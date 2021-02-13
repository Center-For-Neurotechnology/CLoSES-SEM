function [sCoreParams, variantConfig, neuralModelParams,  sInputData, sInputTrigger, sMultiTimeInputData, sMultiTimeInputTrigger, sRandomStimulation] = initializationScriptNeuralModel(whatToDo, modelFileName,filterName,featureName,detectorType, experimentType) 
% 1.   whatToDo: whether to simulate, compile or prepare model to run in real time
%       Options: 'SIMULATION' /  'REAL-TIME' / 'NHP'
%           if whatToDo = Simulation also create data for simulation
%
% 2. modelFileName: neural model decoder file name (could be an "identity" to generate features - but must be of desired feature size)
%       example: MSIT/ECR:  ExampleData/identityModel_15_1.mat 
%                CLEAR:     ExampleData/identityCLEARModel_10_1_5ch.mat
%
%,3. Filter': THETAALPHAGAMMA', 'LP7HIGHGAMMA'
% 4. Feature: 'LOGBANDPOWER','FILTEREDANDPOWER'
% 5. Detector: 'NEURALMODEL' (both for ECR/MSIT and CLEAR)
%
% 6. experimentType: MSIT, ECR, CLEAR -  A specific MODEL could be specified for different experiments  
%
%e.g.ECR:       initializationScriptNeuralModel('REAL-TIME', 'ExampleData/identityModel_10_1.mat','THETA','COHERENCE','MULTISITE', 'NEURALMODEL','ECR')
%e.g. CLEAR:    [sCoreParams, variantConfig, neuralModelParams] = initializationScriptNeuralModel('REAL-TIME', 'ExampleData/identityCLEARModel_10_1_5ch.mat','LP7HIGHGAMMA','FILTEREDANDPOWER','NEURALMODEL','CLEAR')
%  and then:    [sCoreParams, variantConfig] = ConfigurationFile_CLEAR_1sec_Model(sCoreParams, variantConfig)
%% Initilize Model -mainly to adapt cells and structs to Simulink Real-Time matrices format
switch upper(experimentType)
    case {'MSIT','ECR'}
        [neuralModelParams, sCoreParams] = initNeuralModelParams(modelFileName, []);
    case 'CLEAR'
        [neuralModelParams, sCoreParams] = initCLEARModelParams(modelFileName, []);
        
    otherwise
        [neuralModelParams, sCoreParams] = initNeuralModelParams(modelFileName, []); % keep as default for compatibility      
end

%% Initialize CLoSES parameters
[sCoreParams, variantConfig, sInputData, sInputTrigger, sMultiTimeInputData, sMultiTimeInputTrigger, sRandomStimulation] = initializationScript(whatToDo,sCoreParams,filterName,featureName,'NEXTTRIAL',detectorType,[],experimentType);



