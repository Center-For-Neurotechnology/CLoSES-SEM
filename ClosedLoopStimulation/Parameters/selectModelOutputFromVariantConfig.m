function [modelOutput, indModelOutputInGUI] = selectModelOutputFromVariantConfig(variantConfig)
% returns order and name of Model output in GUI
% GUI name SHOULD be the same as VARIANT's name
% Options are : MEAN, UPPER (bound), LOWER (bound)

switch (variantConfig.STATEOUTPUT)
    case 1
        indModelOutputInGUI = 1;
        modelOutput = 'MEAN';
    case 2
        indModelOutputInGUI = 2;
        modelOutput = 'UPPERBOUND';
    case 3
        indModelOutputInGUI = 3;
        modelOutput = 'LOWER';

    otherwise
        indModelOutputInGUI = 1;
        modelOutput = 'MEAN';
        disp(['No Valid Model Output Config specified. Using default: Ind in GUI=', num2str(indModelOutputInGUI), ' - Model Output Name=',modelOutput ]);
end 



%% %STATEOUTPUT  VARIANT Config 
% State variable to use for detection (which state estimate output is compared to threshold)
% variantParams.STATEOUTPUT.MEAN = Simulink.Variant('variantConfig_STATEOUTPUT == 1');        % Mean state estiamte is used in ECR
% variantParams.STATEOUTPUT.UPPERBOUND = Simulink.Variant('variantConfig_STATEOUTPUT == 2');  % Upper bound estimate is used in MSIT
% variantParams.STATEOUTPUT.LOWERBOUND = Simulink.Variant('variantConfig_STATEOUTPUT == 3');

%% ORDER in GUI
% MEAN
% UPPERBOUND
% LOWERBOUND


