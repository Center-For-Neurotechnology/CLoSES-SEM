function [sCoreParams, variantConfig, neuralModelParams,  sInputData, sInputTrigger, sMultiTimeInputData, sMultiTimeInputTrigger, sRandomStimulation] = initializationScriptNeuralModel(whatToDo, modelFileName,filterName,featureName,detectorType, experimentType) 
% 1.   whatToDo: whether to simulate, compile or prepare model to run in real time
%       Options: 'SIMULATION' /  'REAL-TIME' / 'NHP'
%           if whatToDo = Simulation also create data for simulation
%
% 2. modelFileName: neural model decoder file name (could be an "identity" to generate features - but must be of desired feature size)
%       example: ExampleData/identityModel_15_1.mat
%
%,'THETAALPHAGAMMA','LOGBANDPOWER','NEURALMODEL','NEURALMODEL'
%'THETA','COHERENCE','MULTISITE', 'NEURALMODEL'
%
% 6. experimentType: A specific MODEL could be specified for different experiments  
%       Options: experimentType={'MSIT','ECR'}: NEURALMODEL / CLEAR: CLEARMDOEL
%

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



