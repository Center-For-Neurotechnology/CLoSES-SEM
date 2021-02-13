function [stimulationType, indStimulationInGUI] = selectStimulationTypeFromVariantConfig(variantConfig)
% returns order and name of Detector in GUI
% GUI name SHOULD be the same as VARIANT's name
% Options are only:
% - NeuralModel -> used for MSIT/CLEAR that require 1 channel as ouput
% - MULTISITE -> used for ECR that require 2 channels as ouput

switch (variantConfig.STIMULATION_TYPE)
    case {1, 3}
        indStimulationInGUI = 1;
        stimulationType = 'Real Time';
    case {2, 4}
        indStimulationInGUI = 2;
        stimulationType = 'Next Trial';
    otherwise
        indStimulationInGUI = 1;
        stimulationType = 'Real Time';
        disp(['No Valid Stimulation type Config specified. Using default: Ind in GUI=', num2str(indStimulationInGUI), ' - Stimulation Name=',stimulationType ]);
end 


%% %Stimulation VARIANT Config 
% variantParams.STIMULATION.REALTIME = Simulink.Variant('variantConfig_STIMULATION_TYPE == 1');
% variantParams.STIMULATION.ONNEXTTRIGGER = Simulink.Variant('variantConfig_STIMULATION_TYPE == 2');
% variantParams.STIMULATION.MULTISITE.REALTIME = Simulink.Variant('variantConfig_STIMULATION_TYPE == 3');
% variantParams.STIMULATION.MULTISITE.NEXTTRIGGER = Simulink.Variant('variantConfig_STIMULATION_TYPE == 4');

%% ORDER in GUI
% Real Time
% Next Trial


