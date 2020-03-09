function sCoreParams = InitCoreParams_Dependent(sCoreParams)
% Dependent
%sCoreParams.core.stepMultiple = sCoreParams.core.batchPeriod / sCoreParams.core.stepPeriod;
sCoreParams.core.samplesPerStep = sCoreParams.core.stepPeriod * sCoreParams.core.samplingRate;
%sCoreParams.decoders.txDetector.nChannels = min(length(sCoreParams.decoders.txDetector.channel1),length(sCoreParams.decoders.txDetector.channel2));
sCoreParams.decoders.txDetector.detectChannelMask = zeros(1,sCoreParams.decoders.txDetector.nFeatures); %logical(zeros(1,sCoreParams.core.maxChannelsAllNSPs));
sCoreParams.decoders.txDetector.detectChannelMask(sCoreParams.decoders.txDetector.detectChannelInds) = 1;
sCoreParams.decoders.txDetector.nDetectionsRequested = sCoreParams.decoders.txDetector.nDetectionsRequestedmSec * sCoreParams.core.samplesPerStep;   % Number of consecutive detections required to produce a stimulation (idea of only detecting if feature is large for a certain duration)
sCoreParams.decoders.txDetector.nFilteredChannels = sCoreParams.decoders.txDetector.nChannels *  sCoreParams.decoders.txDetector.nFreqs;

sCoreParams.write.broadcastSamp =  sCoreParams.write.broadcastSec / sCoreParams.core.stepPeriod; % in steps
sCoreParams.viz.preTriggerSamp = sCoreParams.viz.preTriggerSec * sCoreParams.core.samplingRate; %
sCoreParams.viz.postTriggerSamp = sCoreParams.viz.postTriggerSec * sCoreParams.core.samplingRate; %
sCoreParams.viz.nChannels = length(sCoreParams.viz.channelInds);

sCoreParams.viz.nFeatures = min(length(sCoreParams.viz.featureInds),(sCoreParams.network.maxMtu)); 
sCoreParams.viz.featureInds = sCoreParams.viz.featureInds(1:sCoreParams.viz.nFeatures); %if >maxMTU only keep up to allowed by UDP MTU
%sCoreParams.Features.Baseline.durationSamples = sCoreParams.Features.Baseline.durationSec * sCoreParams.core.samplingRate;

%sCoreParams.Features.Coherence.downSampleFactor = 2^nextpow2(sCoreParams.core.samplingRate/sCoreParams.Features.Coherence.FsAfterDownSample); %max(floor(sCoreParams.core.samplingRate / (8* sCoreParams.Features.Coherence.highFreq)),1); % Keep up to 4 times the highest frequency
%sCoreParams.Features.Coherence.FsAfterDownSample = round(sCoreParams.core.samplingRate / sCoreParams.Features.Coherence.downSampleFactor); % Keep up to 4 times the highest frequency
%sCoreParams.Features.Coherence.WindowDurationSamples = round(sCoreParams.Features.Coherence.WindowDurationSec * sCoreParams.Features.Coherence.FsAfterDownSample);
sCoreParams.Features.Coherence.WindowDurationSamples = round(sCoreParams.Features.Coherence.WindowDurationSec * sCoreParams.core.samplingRate); % In Samples (sec*Fs) since it is a buffer of the whole signal
sCoreParams.Features.Coherence.BinSizeSamples = round(sCoreParams.Features.Coherence.BinSizeSec * sCoreParams.core.samplingRate); % In Samples (sec*Fs) since it is a buffer of the whole signal
sCoreParams.Features.Power.WindowDurationSamples = round(sCoreParams.Features.Power.WindowDurationSec * sCoreParams.core.samplingRate); % In Samples (sec*Fs) since it is a buffer of the whole signal 
%sCoreParams.triggers.periodSamples = sCoreParams.triggers.periodSec * sCoreParams.core.samplingRate; %/ sCoreParams.core.stepPeriod;
%sCoreParams.triggers.initialTriggerSamples = sCoreParams.triggers.initialTriggerSec* sCoreParams.core.samplingRate; % / sCoreParams.core.stepPeriod;
sCoreParams.triggers.minDistanceTriggersSteps = round(sCoreParams.triggers.minDistanceTriggersSec / sCoreParams.core.stepPeriod); % In steps 

%sCoreParams.DurationTriggeredMeanFrames = round(sCoreParams.DurationTriggeredMeanSec * sCoreParams.core.samplingRate/sCoreParams.core.samplesPerStep/sCoreParams.FrameSize);
sCoreParams.decoders.txDetector.nPairs = sCoreParams.decoders.txDetector.nChannels * (sCoreParams.decoders.txDetector.nChannels-1) /2;
sCoreParams.decoders.txDetector.delayAfterTriggerSteps = sCoreParams.decoders.txDetector.delayAfterTriggerSec / sCoreParams.core.stepPeriod; % changed name to steps because it is actually a delay in the sumulink model
sCoreParams.decoders.txDetector.detectionDurationSteps = sCoreParams.decoders.txDetector.detectionDurationSec / sCoreParams.core.stepPeriod; % Changed name to "steps" because we get 1 feature per step
sCoreParams.decoders.txDetector.delayAfterStimSteps = sCoreParams.decoders.txDetector.delayAfterStimSec/ sCoreParams.core.stepPeriod;        % changed name to steps because it is actually a delay in the sumulink model
if (max([sCoreParams.decoders.txDetector.channel1,sCoreParams.decoders.txDetector.channel2])<=length(sCoreParams.decoders.txDetector.channelNames))
    sCoreParams.decoders.txDetector.bipolarChannelNames = [sCoreParams.decoders.txDetector.channelNames(sCoreParams.decoders.txDetector.channel1)' ,sCoreParams.decoders.txDetector.channelNames(sCoreParams.decoders.txDetector.channel2)' ];
end
%sCoreParams.write.maxSignalsPerStep = 9 + 2 * sCoreParams.viz.nFeatures + 2 * sCoreParams.viz.nChannels; %MAX # of UDP matrix size received: 7 1D vectors +2 stimChannel + 2* number of Features (Channels/Pairs) + 2* number of channels
sCoreParams.write.maxContinuousSignalsPerStep = 9 + sCoreParams.viz.nChannels; %MAX # of UDP matrix size received: 7 1D vectors +2 stimChannel  + 1* number of channels (only raw EEG)
sCoreParams.write.maxTrialByTrialDataPerStep = 10 +  sCoreParams.viz.nFeatures + 2;      %MAX # of UDP matrix size received: 4 1D vectors + 3 state estimate + 2 stimChannel + 1* number of Features (Channels/Pairs)+ 2 Thresholds (above/below) for state 
sCoreParams.write.maxSignalsPerStep = max(sCoreParams.write.maxTrialByTrialDataPerStep,sCoreParams.write.maxContinuousSignalsPerStep); % UDP packets will be this size -> padded with zero

sCoreParams.write.broadcastSampDivisors = divisors(sCoreParams.write.broadcastSamp);

sCoreParams.stimulator.delayAfterTriggerSteps = sCoreParams.stimulator.delayAfterTriggerSec / sCoreParams.core.stepPeriod; % change name to steps!! - in stepsPeriod because it is number of steps not really samples
sCoreParams.stimulator.possibleStimRealChannelNumbers = [sCoreParams.stimulator.stimChannelUpper; sCoreParams.stimulator.stimChannelLower];
%if (length(sCoreParams.Features.Baseline.initialThresholdValue) ~= sCoreParams.decoders.txDetector.nFeatures)
%    sCoreParams.Features.Baseline.initialThresholdValue = sCoreParams.Features.Baseline.initialThresholdValue(1) * ones(1,sCoreParams.decoders.txDetector.nFeatures);
%end
if sCoreParams.write.maxContinuousSignalsPerStep*sCoreParams.write.broadcastSamp*8 > 65000 || sCoreParams.write.maxTrialByTrialDataPerStep*8 > 65000 % MAX posible is maxSignalsPerStep of 81
    warndlg(['You''re trying to log too many signals! - use at most ',num2str(floor(65000/8/sCoreParams.write.broadcastSamp)),' features or channels * time'])
end

end
