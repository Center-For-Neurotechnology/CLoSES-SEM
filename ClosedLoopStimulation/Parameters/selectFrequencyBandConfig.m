function [variantConfig, sCoreParams] = selectFrequencyBandConfig(freqBandName, variantConfig, sCoreParams)
% Same order as in GUI

nFreqs =1;
switch upper(freqBandName)
    case 'THETA'
        variantConfig.FREQ_LOW = 4;
        sCoreParams.Features.Coherence.lowFreq = 4;
        sCoreParams.Features.Coherence.highFreq = 8;
    case 'ALPHA'
        variantConfig.FREQ_LOW = 8;
        sCoreParams.Features.Coherence.lowFreq = 8;
        sCoreParams.Features.Coherence.highFreq = 15;
    case 'BETA'
        variantConfig.FREQ_LOW = 15;
        sCoreParams.Features.Coherence.lowFreq = 15;
        sCoreParams.Features.Coherence.highFreq = 30;
    case 'LOWGAMMA'
        variantConfig.FREQ_LOW = 30;
        sCoreParams.Features.Coherence.lowFreq = 30;
        sCoreParams.Features.Coherence.highFreq = 60;
    case 'HIGHGAMMA'
        variantConfig.FREQ_LOW = 65;
        sCoreParams.Features.Coherence.lowFreq = 65;
        sCoreParams.Features.Coherence.highFreq = 110;
    case 'RIPPLE'
        variantConfig.FREQ_LOW = 200;
        sCoreParams.Features.Coherence.lowFreq = 110;
        sCoreParams.Features.Coherence.highFreq = 200;
    case 'HIGHGAMMARIPPLE'
        variantConfig.FREQ_LOW = 65200;
        sCoreParams.Features.Coherence.lowFreq = 65;
        sCoreParams.Features.Coherence.highFreq = 200;
    case 'HFORIPPLE'
        variantConfig.FREQ_LOW = 80;
        sCoreParams.Features.Coherence.lowFreq = 80;
        sCoreParams.Features.Coherence.highFreq = 200;
    case 'GAMMA'
        variantConfig.FREQ_LOW = 30110;
        sCoreParams.Features.Coherence.lowFreq = 30;
        sCoreParams.Features.Coherence.highFreq = 110;
    case 'SPINDLES'
        variantConfig.FREQ_LOW = 1216;
        sCoreParams.Features.Coherence.lowFreq = 12;
        sCoreParams.Features.Coherence.highFreq = 16;
    case 'NOFILTER'
        variantConfig.FREQ_LOW = 0;
    case 'THETAALPHAGAMMA'
        variantConfig.FREQ_LOW = 4865200;
        sCoreParams.Features.Coherence.lowFreq = 4;
        sCoreParams.Features.Coherence.highFreq = 200;
        nFreqs =3;
    case 'LP7HIGHGAMMA'
        variantConfig.FREQ_LOW = 765;
        sCoreParams.Features.Coherence.lowFreq = 1;
        sCoreParams.Features.Coherence.highFreq = 110;
        nFreqs =2;
    otherwise
        disp(['No Valid Frequency specified. Using default: ', num2str(variantConfig.FREQ_LOW)]);
end

%if (nFreqs ~= sCoreParams.decoders.txDetector.nFreqs)
sCoreParams.decoders.txDetector.nFreqs = nFreqs;
sCoreParams.decoders.txDetector.nFilteredChannels = sCoreParams.decoders.txDetector.nChannels *  sCoreParams.decoders.txDetector.nFreqs;
%end


