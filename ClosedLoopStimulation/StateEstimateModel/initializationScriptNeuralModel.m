function [sCoreParams, variantConfig, neuralModelParams,  sInputData, sInputTrigger, sMultiTimeInputData, sMultiTimeInputTrigger, sRandomStimulation] = initializationScriptNeuralModel(whatToDo, modelFileName,filterName,featureName,detectorType) 
% 1.   whatToDo: whether to simulate, compile or prepare model to run in real time
%       Options: 'SIMULATION' /  'REAL-TIME' / 'NHP'
%           if whatToDo = Simulation also create data for simulation
%
% 2. modelFileName: neural model decoder file name (could be an "identity" to generate features - but must be of desired feature size)
%       example: ExampleData/identityModel_15_1.mat
%
%,'THETAALPHAGAMMA','LOGBANDPOWER','NEURALMODEL'
%'THETA','COHERENCE','MULTISITE'
%
[neuralModelParams, sCoreParams] = initNeuralModelParams(modelFileName, []);

[sCoreParams, variantConfig, sInputData, sInputTrigger, sMultiTimeInputData, sMultiTimeInputTrigger, sRandomStimulation] = initializationScript(whatToDo,sCoreParams,filterName,featureName,'NEXTTRIAL',detectorType);



