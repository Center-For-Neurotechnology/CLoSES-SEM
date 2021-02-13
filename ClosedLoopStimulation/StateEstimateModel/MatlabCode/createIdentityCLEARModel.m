function [modelFileNameIdentity] =  createIdentityCLEARModel(modelFileNameBase, numFeaturesPerEpoch, numEpochs, modelFileNameIdentity)

% Parameters from Model
if ~exist('numFeaturesPerEpoch','var') || isempty(numFeaturesPerEpoch)
    numFeaturesPerEpoch= 10; % Default is 2Freqs x 5 channels
end  
if ~exist('numEpochs','var') || isempty(numEpochs)
    numEpochs= 1; % Default is to NOT divide time interval -> 1 epoch
end  
if ~exist('modelFileNameIdentity','var') || isempty(modelFileNameIdentity)
    filePath = fileparts(modelFileNameBase);
    modelFileNameIdentity = [filePath, filesep, 'identityCLEARModel_',num2str(numFeaturesPerEpoch),'_',num2str(numEpochs),'.mat'];
end

% Get base information from existing model file
stModelOrig = load(modelFileNameBase);
modelOrig = stModelOrig.model;
k = length(modelOrig.selectedChannels); % RIZ: I'm not sure about this value! - it is the same as in the example nz_predict

%Create model params
nFeatures = numFeaturesPerEpoch * numEpochs;
nFeatInModel = min(nFeatures, length(modelOrig.selectedChannels{k}));
nDataPoints = size(modelOrig.NormalDist_mean{k},3);

model.NchannelsMax{1} = nFeatInModel;
model.NormalDist_mean{1} = zeros(nFeatures, 2, nDataPoints);
model.NormalDist_mean{1}(1:nFeatInModel,:,:) = modelOrig.NormalDist_mean{k}(1:nFeatInModel,:,:);
model.NormalDist_variance{1} = zeros(nFeatures, 2, nDataPoints, nDataPoints);
model.NormalDist_variance{1}(1:nFeatInModel,:,:,:) = modelOrig.NormalDist_variance{k}(1:nFeatInModel,:,:, :);
model.selectedChannels{1} =  randperm(nFeatures); % instead of  modelOrig.selectedChannels because it could be larger than nFeatures= zeros(1, nFeatures); 
% model.selectedChannels{1}(1:nFeatInModel)
model.selectedLength{1} =  zeros(1, nFeatures); 
model.selectedLength{1} = modelOrig.selectedLength{k}(1:nFeatInModel);

dValid = ones(nFeatures, 1);
if isfield(modelOrig,'dValid') 
    dValid(1:nFeatInModel,:) = modelOrig.dValid(1:nFeatInModel,:);
end


% Save new model identity file

save(modelFileNameIdentity, 'model','dValid','numEpochs','numFeaturesPerEpoch','nDataPoints');


