function [featureName, indFeatureInGUI] = selectFeatureNameFromVariantConfig(variantConfig)
% returns order and name of Features in GUI
% GUI name SHOULD be the same as VARIANT's name

switch (variantConfig.WHICH_FEATURE)
    case 3
        indFeatureInGUI = 1;
        featureName = 'SMOOTHBANDPOWER';
    case 4
        indFeatureInGUI = 2;
        featureName = 'VARIANCEOFPOWER';
    case 5
        indFeatureInGUI = 3;
        featureName = 'COHERENCE';
    case 1
        indFeatureInGUI = 4;
        featureName = 'IED';
    case 7
        indFeatureInGUI = 5;
        featureName = 'LOGBANDPOWER';
    case 8
        indFeatureInGUI = 6;
        featureName = 'FILTEREDANDPOWER';
    otherwise
        indFeatureInGUI = 1;
        featureName = 'SMOOTHBANDPOWER';
        disp(['No Valid Feature Config specified. Using default: Ind in GUI=', num2str(indFeatureInGUI), ' - Feature Name=',featureName ]);
end 

%% NOT IMPLEMENTED in GUI
%     case 1
%         indFeatureInGUI = [];  % DEFAULT TO EMPTY
%         featureName = 'BANDPOWER'; % NOT in GUI
%     case 2
%         indFeatureInGUI = [];         % DEFAULT TO EMPTY
%         featureName = 'VARIANCE'; % NOT IMPLEMENTED!!
%     case 6
%         indFeatureInGUI = [];         % DEFAULT TO EMPTY
%         featureName = 'CORRELATION'; % NOT IMPLEMENTED!!

%% %Features 
% variantParams.FEATURE.BANDPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE == 1');
% variantParams.FEATURE.VARIANCE = Simulink.Variant('variantConfig_WHICH_FEATURE == 2');
% variantParams.FEATURE.SMOOTHBANDPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE == 3');
% variantParams.FEATURE.VARIANCEOFPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE == 4');
% variantParams.FEATURE.COHERENCE = Simulink.Variant('variantConfig_WHICH_FEATURE == 5');
% variantParams.FEATURE.CORRELATION = Simulink.Variant('variantConfig_WHICH_FEATURE == 6');
% variantParams.FEATURE.LOGBANDPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE == 7');
% variantParams.FEATURE.FILTEREDANDPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE == 8');

%% ORDER in GUI
% SmoothBandPower
% VarianceOfPower
% Coherence
% IED
% LOGBandPower
% FilteredandPower

