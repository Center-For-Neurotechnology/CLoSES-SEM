function [freqBandName, indFreqInGUI] = selectFrequencyNameFromVariantConfig(variantConfig)
% returns order and name of filter in GUI
% GUI name SHOULD be the same as VARIANT's name

% Same order and name as in GUI
switch (variantConfig.FREQ_LOW)
    case 4
        indFreqInGUI = 1;
        freqBandName = 'THETA';
    case 8
        indFreqInGUI = 2;
        freqBandName = 'ALPHA';
    case 15
        indFreqInGUI = 3;
        freqBandName = 'BETA';
    case 30
        indFreqInGUI = 4;
        freqBandName = 'LOWGAMMA';
    case 65
        indFreqInGUI = 5;
        freqBandName = 'HIGHGAMMA';
    case 200
        indFreqInGUI = 6;
        freqBandName = 'RIPPLE';
    case 65200
        indFreqInGUI = 7;
        freqBandName = 'HIGHGAMMARIPPLE';
    case 80
        indFreqInGUI = 8;
        freqBandName = 'HFORIPPLE';
    case 30110
        indFreqInGUI = 9;
        freqBandName = 'GAMMA';
    case 1216
        indFreqInGUI = 10;
        freqBandName = 'SPINDLES';
    case 0
        indFreqInGUI = 11;
        freqBandName = 'NOFILTER';
    case 4865200
        indFreqInGUI = 12;
        freqBandName = 'THETAALPHAGAMMA';
    case 765
        indFreqInGUI = 13;
        freqBandName = 'LP7HIGHGAMMA';
    otherwise
        indFreqInGUI = 1;
        freqBandName = 'THETA';      
        disp(['No Valid variantConfig.FREQ_LOW specified. Using default: ', num2str(indFreqInGUI),' ',freqBandName]);
end

%% FILTERS VARIANTS
% variantParams.FILTER.IIR_HFORIPPLE= Simulink.Variant('variantConfig_FREQ_LOW == 80 && variantConfig_FILTER_TYPE == 2');
% variantParams.FILTER.IIR_RIPPLE= Simulink.Variant('variantConfig_FREQ_LOW == 140 && variantConfig_FILTER_TYPE == 2');
% variantParams.FILTER.IIR_HIGHGAMMARIPPLE= Simulink.Variant('variantConfig_FREQ_LOW == 65200 && variantConfig_FILTER_TYPE == 2');
% variantParams.FILTER.IIR_HIGHGAMMA= Simulink.Variant('variantConfig_FREQ_LOW == 65 && variantConfig_FILTER_TYPE == 2');
% variantParams.FILTER.IIR_LOWGAMMA= Simulink.Variant('variantConfig_FREQ_LOW == 30 && variantConfig_FILTER_TYPE == 2');
% variantParams.FILTER.IIR_BETA= Simulink.Variant('variantConfig_FREQ_LOW == 15 && variantConfig_FILTER_TYPE == 2');
% variantParams.FILTER.IIR_ALPHA= Simulink.Variant('variantConfig_FREQ_LOW == 8 && variantConfig_FILTER_TYPE == 2');
% variantParams.FILTER.IIR_THETA= Simulink.Variant('variantConfig_FREQ_LOW == 4 && variantConfig_FILTER_TYPE == 2');
% variantParams.FILTER.IIR.GAMMA= Simulink.Variant('variantConfig_FREQ_LOW == 30110 && variantConfig_FILTER_TYPE == 2');
% variantParams.FILTER.IIR.SPINDLES= Simulink.Variant('variantConfig_FREQ_LOW == 1216 && variantConfig_FILTER_TYPE == 2');
% 
% variantParams.FILTER.FIR_EXTERNAL = Simulink.Variant('variantConfig_FREQ_LOW == -1 && variantConfig_FILTER_TYPE == 1');
% variantParams.FILTER.ALLPASS = Simulink.Variant('variantConfig_FREQ_LOW == 0'); % Do NOT filter -> simply pass raw EEG data
% 
% variantParams.FILTER.MANYFREQS.THETAALPHAGAMMA  = Simulink.Variant('variantConfig_FREQ_LOW == 4865200 && variantConfig_FILTER_TYPE == 2'); % for state estimate model we need 3 freqs
% variantParams.FILTER.MANYFREQS.LP7HIGHGAMMA= Simulink.Variant('variantConfig_FREQ_LOW == 765 && variantConfig_FILTER_TYPE == 2');

