function [neuralModelParams, sCoreParams] = initCLEARModelParams(modelFileName, sCoreParams)
% This function converts model for use with Neural decoder


%% params & Variant Config
if ~exist('sCoreParams','var') || isempty(sCoreParams)
    sCoreParams = InitCoreParams;
end
% if ~exist('variantConfig','var') || isempty(variantConfig)
%     [variantParams, variantConfig] = InitVariants();
% else
%     [variantParams] = InitVariants(); % if variantConfig is provided we only need the variant names (variantParams)
% end
% if ~exist('featureName','var') || isempty(featureName)
%     freqBandName = 'THETAALPHAGAMMA';    % Options: THETA (4-8) / ALPHA (8-15) / BETA (15-30) / LOWGAMMA (30-55) / HIGHGAMMA (65-110) / HIGHGAMMARIPPLE (65-200) / RIPPLE (140-200) / GAMMA (30-110) /SPINDLES (12-16) / NOFILTER
% end
% if ~exist('featureName','var') || isempty(featureName)
%     featureName =  'LOGBANDPOWER';    % Options: SMOOTHBANDPOWER / VARIANCEOFPOWER / COHERENCE / LOGPOWER
% end
% 
% %variantConfig.WHICH_DETECTOR = 8;
% % %variantConfig.FREQ_LOW = 4865200;
% % freqBandName = 'THETAALPHAGAMMA';    % Options: THETA (4-8) / ALPHA (8-15) / BETA (15-30) / LOWGAMMA (30-55) / HIGHGAMMA (65-110) / HIGHGAMMARIPPLE (65-200) / RIPPLE (140-200) / GAMMA (30-110) /SPINDLES (12-16) / NOFILTER
% % featureName =  'SMOOTHBANDPOWER';    % Options: SMOOTHBANDPOWER / VARIANCEOFPOWER / COHERENCE
% 
% detectorType = 'NEURALMODEL';        % Options: CONTINUOUS /TRIGGER / MULTISITE / IED

%% Parameters from Model
if ~exist('modelFileName','var') || isempty(modelFileName)
    modelFileName = 'model.mat';
end
% modelInfo = load('rinaModel');
% modelInfo=[];
modelInfo = load(modelFileName);
model = modelInfo.model;
if ~isfield(modelInfo,'numEpochs')
    modelInfo.numEpochs= 1; % Default is to divide time interval in 1 epochs
end
k = length(model.selectedChannels); % RIZ: I'm not sure about this value! - it is the same as in the example nz_predict

%% assign model parameters obtained during training to paramsCLEARmodel
neuralModelParams.nEpochs = modelInfo.numEpochs; % number of time epochs
%nFeatures = length(model.selectedLength{k}); 
nFeatures = model.NchannelsMax{k}; % n Channels max is the maximum number of features used / length(model.selectedChannels{k});
nDataPoints = size(model.NormalDist_mean{k},3); %max([model.selectedLength{k}]);

neuralModelParams.nFeatures = nFeatures;
neuralModelParams.nDataPoints = nDataPoints;
neuralModelParams.nFeaturesPerEpoch = floor(neuralModelParams.nFeatures / neuralModelParams.nEpochs);   % modelInfo.no_feature; - without  considering time division
% Instead of mean/variance as cell (not accepted) - we divide it into the needed vectors ad structures
% For NOW only 1 epoch!!
neuralModelParams.model_NormalDist_mean = zeros(nFeatures, nDataPoints); % nSelChannels at the end because that is the one in the loop
neuralModelParams.model_NormalDist_variance = zeros(nFeatures, nDataPoints, nDataPoints);

neuralModelParams.model_selectedFeatures = model.selectedChannels{k}(1:nFeatures); % channels are actually features - RIZ CONFIRM that FIRST nFeatures
neuralModelParams.model_selectedLength = model.selectedLength{k}(1:nFeatures); % WILL BE REMOVED!

neuralModelParams.model_NormalDist_mean = model.NormalDist_mean{k}(1:nFeatures, :, :);
neuralModelParams.model_NormalDist_variance = model.NormalDist_variance{k}(1:nFeatures, :, :,:); % variance is 3dimensional

neuralModelParams.model_selectedChannels = model.selectedChannels{k}; % channels are actually features - keep to have the info just in case - but it is missleading!
neuralModelParams.model_NchannelsMax = model.NchannelsMax{k};

neuralModelParams.dValid = ones(nFeatures,4); % RIZ: THIS IS WRONG!!! BUT THIS INFO IS NOT PRESENT IN THE MODEL!! and the format s ,4 to keep it similar to ECR/MSIT model

%Update nFeatures and assign to workspace
sCoreParams.neuralModelParams = neuralModelParams; % Added to be able to send to target
% sCoreParams = InitCoreParams_Dependent(sCoreParams);
% assignin('base','sCoreParams',sCoreParams);
% FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);
% 
% [variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();
% FlattenAndTuneVariants(variantParams,'variantParams',variantParamsFlatNames);
% FlattenAndTune(variantConfig,'variantConfig',variantConfigFlatNames);


assignin('base','neuralModelParams',neuralModelParams);


