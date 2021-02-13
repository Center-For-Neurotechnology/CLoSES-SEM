function [detectorName, indDetectorInGUI] = selectDetectorTypeFromVariantConfig(variantConfig)
% returns order and name of Detector in GUI
% GUI name SHOULD be the same as VARIANT's name
% Options are only:
% - NeuralModel -> used for MSIT/CLEAR that require 1 channel as ouput
% - MULTISITE -> used for ECR that require 2 channels as ouput

switch (variantConfig.WHICH_DETECTOR)
    case 1
        indDetectorInGUI = 1;
        detectorName = 'NeuralModel';
    case 2
        indDetectorInGUI = 2;
        detectorName = 'MULTISITE';

    otherwise
        indDetectorInGUI = 1;
        detectorName = 'NeuralModel';
        disp(['No Valid Detector Config specified. Using default: Ind in GUI=', num2str(indDetectorInGUI), ' - Detector Name=',detectorName ]);
end 


%% %Detectors  VARIANT Config 
% variantParams.DETECTOR.STATEESTIMATE = Simulink.Variant('variantConfig_WHICH_DETECTOR == 1');
% variantParams.DETECTOR.MULTISITE = Simulink.Variant('variantConfig_WHICH_DETECTOR == 2');

%% ORDER in GUI
% NeuralModel
% MULTISITE


