function [output] = nz_predict_CLoSES(model_NchannelsMax, model_selectedChannels, model_selectedLength, model_NormalDist_mean, model_NormalDist_variance, features)
%Predict the class of input features
% RIZ Input changed to matrices instead of struct of cells
% for Simulink Real-time compatibility
%   INPUTS:
%       model_NchannelsMax: [2*N_channels, 1]  - original: model.NchannelsMax{k}
%       model_selectedChannels: [2*N_channels, 1] =  - original: model.selectedChannels{k}{ch}
%       model_selectedLength: [2*N_channels, 1] =  - original: model.selectedChannels{k}{ch}
%       model_NormalDist_mean: [2*N_channels, 2, N_DataPoints] - original: model.NormalDist_mean{k}{ch}
%       model_NormalDist_variance: [2*N_channels,2, N_DataPoints, N_DataPoints]  - original: model.NormalDist_variance{k}{ch}
%
%   
%   model: trained Model
%   features: input feature to the model [2*N_channels, N_DataPoints]
%
% current model: N_DataPoints =15;

pol = ones(1,2); %product of likelihoods
%k = size(features,2)-1;
indAllDataPoints = 1:size(features,2);
for iCh = 1:model_NchannelsMax
    indDataPoints = indAllDataPoints(1:model_selectedLength(iCh));
    muhat = squeeze(model_NormalDist_mean(iCh, :, indDataPoints)); % iCh is the last one to keep dimension in each selection
    sigmahat = squeeze(model_NormalDist_variance(iCh, :, indDataPoints,indDataPoints)); 
    indSelFeat = model_selectedChannels(iCh);
    % sch = model_selectedChannels(ch,:); % RIZ: I am assuming best channels are fix per experiment and selected outside in CLoSES GUI
    [idx, likelihood] = nz_bayes_classifier_CLoSES(muhat,sigmahat,features(indSelFeat, indDataPoints));
    pol = pol.*likelihood;
    
end
[outlikelihood,output] = max(pol);

end

%% ORGINAL CODE:
% pol = 1; %product of likelihoods
% k = size(features,2)-1;
% for ch = 1:model.NchannelsMax{k}
%     muhat = model.NormalDist_mean{k}{ch};
%     sigmahat = model.NormalDist_variance{k}{ch};
%     sch = model.selectedChannels{k}(ch);
%     [idx, likelihood] = nz_bayes_classifier(muhat,sigmahat,features(sch,1:size(sigmahat,3)));
%     pol = pol.*likelihood;
% end
% [outlikelihood,output] = max(pol);
% 
% end

