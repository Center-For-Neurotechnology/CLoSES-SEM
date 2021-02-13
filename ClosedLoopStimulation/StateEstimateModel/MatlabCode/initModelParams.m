function [neuralModelParams, sCoreParams] = initModelParams(modelFileName, sCoreParams, experimentType)

% 1. modelFileName: neural/CLEAR model decoder file name (could be an "identity" to generate features - but must be of desired feature size)
%       example: ExampleData/identityModel_15_1.mat
%
% 2. sCoreParams if already defined
%
% 3. experimentType: A specific MODEL is used for each type of experiment be specified  
%       Options: MSIT & ECR: NEURALMODEL / CLEAR: CLEARMDOEL
%

%% Params & Variant Config
if ~exist('sCoreParams','var') || isempty(sCoreParams)
    sCoreParams = InitCoreParams;
end

% Parameters from Model
if ~exist('modelFileName','var') || isempty(modelFileName)
    modelFileName = 'model.mat';
end

%% Initilize Model -mainly to adapt cells and structs to Simulink Real-Time matrices format
switch upper(experimentType)
    case {'MSIT','ECR'}
        [neuralModelParams, sCoreParams] = initNeuralModelParams(modelFileName, sCoreParams);

    case 'CLEAR'
        [neuralModelParams, sCoreParams] = initCLEARModelParams(modelFileName, sCoreParams);
        
    otherwise
        [neuralModelParams, sCoreParams] = initNeuralModelParams(modelFileName, sCoreParams); % keep as default for compatibility      
end



