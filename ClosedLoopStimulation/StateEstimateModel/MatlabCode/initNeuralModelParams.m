function [neuralModelParams, sCoreParams] = initNeuralModelParams(modelFileName, sCoreParams)
% This function converts model for use with Neural decoder

% params & Variant Config
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

% Parameters from Model
if ~exist('modelFileName','var') || isempty(modelFileName)
    modelFileName = 'rinaModel.mat';
end
% modelInfo = load('rinaModel');
% modelInfo=[];
modelInfo = load(modelFileName);
if ~isfield(modelInfo,'numEpochs')
    modelInfo.numEpochs= 1; % Default is to divide time interval in 4 epochs
end  

% build state-transition distribution if it is not given
if ~isfield(modelInfo,'Xs')
    modelInfo.numEpochs= 1; % Default is to divide time interval in 4 epochs
    x_min = -4;
    x_max =  4;
    sample= sCoreParams.core.samplingRate;
    modelInfo.Xs = linspace(x_min,x_max,sample);
end

TransP= ones(length(modelInfo.Xs),length(modelInfo.Xs));
for i=1:length(modelInfo.Xs)
    TransP(i,:)=pdf('normal',modelInfo.Xs(i),modelInfo.sParam.a*modelInfo.Xs,sqrt(modelInfo.sParam.sv));
end
%indValid = find(modelInfo.dValid(:,1)==1)
%vParams = [modelInfo.dParam{indValid}]

if ~isfield(modelInfo,'XPre')
    X0 = [0 1];
    modelInfo.XPre = pdf('normal',modelInfo.Xs,X0(1),10.*sqrt(X0(2))); %ones(1,size(TransP,1));
end
neuralModelParams.initialXPre = modelInfo.XPre;
neuralModelParams.nEpochs = modelInfo.numEpochs; % number of time epochs

neuralModelParams.nFeatures = length(modelInfo.eParam);
neuralModelParams.nFeaturesPerEpoch = floor(neuralModelParams.nFeatures / neuralModelParams.nEpochs);   % modelInfo.no_feature; - without  considering time division
neuralModelParams.modelType = 2; % modelType: 1= Gamma / 2=Normal (original "model" or "data_type")
neuralModelParams.TransP = TransP;
neuralModelParams.Xs = modelInfo.Xs;
neuralModelParams.dValid = modelInfo.dValid;

% Instead of dParam that is a cell (not accepted) - we divide it into the needed vectors ad structures
dParam = [modelInfo.eParam{:}];
neuralModelParams.Param_W = zeros(length(dParam),3);
for iFeat=1:length(dParam)
    neuralModelParams.Param_W(iFeat,1:length(dParam(iFeat).W)) = dParam(iFeat).W;
    neuralModelParams.Param_Dispersion(iFeat,:) = dParam(iFeat).Dispersion;
    neuralModelParams.Param_EncModel_XPow(iFeat,:) = dParam(iFeat).EncModel.XPow;
    neuralModelParams.Param_EncModel_YPrv(iFeat,:) = dParam(iFeat).EncModel.YPrv;
%    neuralModelParams.Param_EncModel_AuxInd(iFeat,:) = dParam(iFeat).EncModel.AuxInd;
end

% Initialize bands and features
% [variantConfig, sCoreParams] = selectFrequencyBandConfig(freqBandName, variantConfig, sCoreParams);
% [variantConfig, sCoreParams] = selectFeatureConfig(featureName, variantConfig, sCoreParams);
% variantConfig = selectDetectorNeuralModelConfig(detectorType, variantConfig, featureName);

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


