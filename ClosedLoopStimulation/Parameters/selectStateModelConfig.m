function [variantConfig] = selectStateModelConfig(experimentType, variantConfig, featureName)

% A specific MODEL could be specified (to detect only during trial or all the time)- 
% but be careful, there are different Parameters and initializations and not sure how to consider  POWER and COHERENCE features for CLEAR
%       Options: NEURALMODEL /CLEARMODEL

if isempty(experimentType)
    return;
end

switch upper(experimentType)
    case {'MSIT','ECR'}
        variantConfig.STATEMODEL = 1; %NEURALMODEL (MSIT/ECR)
    case 'CLEAR'
        variantConfig.STATEMODEL = 2; %CLEARMODEL

    otherwise
        disp(['No Valid EXPERIMENT specified. Using default: Feat=', num2str(variantConfig.WHICH_FEATURE), ' - BaselineFeat=',num2str(variantConfig.WHICH_FEATURE_BASELINE), ' - Detector=',num2str(variantConfig.WHICH_DETECTOR),' - State Model=',num2str(variantConfig.STATEMODEL) ]);
end 


