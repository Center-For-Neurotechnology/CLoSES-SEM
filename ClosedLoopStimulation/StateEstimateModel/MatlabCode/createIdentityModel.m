function [modelFileNameIdentity] =  createIdentityModel(modelFileNameBase, numFeaturesPerEpoch, numEpochs, modelFileNameIdentity)

% Parameters from Model
if ~exist('numFeaturesPerEpoch','var') || isempty(numFeaturesPerEpoch)
    numFeaturesPerEpoch= 15; % Default is 3Freqs x 5 channels
end  
if ~exist('numEpochs','var') || isempty(numEpochs)
    numEpochs= 1; % Default is to divide time interval in 4 epochs
end  
if ~exist('modelFileNameIdentity','var') || isempty(modelFileNameIdentity)
    filePath = fileparts(modelFileNameBase);
    modelFileNameIdentity = [filePath, filesep, 'identityModel_',num2str(numFeaturesPerEpoch),'_',num2str(numEpochs),'.mat'];
end

% Get base information from existing model file
modelInfo = load(modelFileNameBase);


%Create model params
nFeatures = numFeaturesPerEpoch * numEpochs;
nFeatInModel = min(nFeatures, size(modelInfo.dValid,1));

if isfield(modelInfo,'data_type') 
    data_type = modelInfo.data_type;
else
    data_type = 2;
end

dValid = ones(nFeatures, 4);
if isfield(modelInfo,'dValid') 
    dValid(1:nFeatInModel,:) = modelInfo.dValid(1:nFeatInModel,:);
else
    disp(['Warning:: NO field dValid found in file ',modelFileNameBase]);
end

eParam = cell(nFeatures, 1);
if isfield(modelInfo,'eParam') 
    eParam(1:nFeatInModel,1) = modelInfo.eParam(1:nFeatInModel,:);
    if nFeatures>nFeatInModel % Add remaining features as the same as the last one
        eParam(nFeatInModel+1:nFeatures,1) = eParam(nFeatInModel,1);
    end
else
    disp(['Warning:: NO field eParam found in file ',modelFileNameBase]);
end

if isfield(modelInfo,'sParam') 
    sParam = modelInfo.sParam;
else
    disp(['Warining:: NO field sParam found in file ',modelFileNameBase]);
    sParam.a = 0.9990;
    sParam.sv = 0.0054;
end


% Save new model identity file

save(modelFileNameIdentity,'dValid','data_type','eParam','sParam','numEpochs','numFeaturesPerEpoch');


