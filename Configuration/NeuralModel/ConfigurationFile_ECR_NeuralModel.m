function [sCoreParams, variantConfig] = ConfigurationFile_ECR_NeuralModel(sCoreParams, variantConfig)
% This file contains the specific configuration for ECR experiments
% Detection occurs if State Estimated based on Theta Coherence is:
%   > ThresholdABOVE (stim on Ch Upper) or  < ThresholdBELOW (Stim on Ch Lower)
% for Upper/Lower bounds or mean State (same signal for both)
%
% It can be configured for each patient - CHANGE NAME to: ConfigXXX_PATIENTNAME.m
% File can be selected at initial GUI (ideally in Configuration folder)
%
%
% ECR specific (probably the only ones to modify)
%
% Channels:
% - sCoreParams.decoders.txDetector.channel1 / 2                % Contact numbers from NSP
% - sCoreParams.decoders.txDetector.detectChannelInds           % Which channels/pairs use for detection (out of the bipolar ones) 
%
% - sCoreParams.decoders.txDetector.triggerChannel = 131;       % Image onset  (usually: 131 - ainp3)  
% - sCoreParams.decoders.txDetector.behavioralChannel = 132;    % BEHAVIOURAL data (usually: 132 - ainp4)  
%
% Variant Selection:
% - freqBandName = 'THETA';             % Options: THETA (4-8) / ALPHA (8-15) / BETA (15-30) / LOWGAMMA (30-55) / HIGHGAMMA (65-110) / HIGHGAMMARIPPLE (65-200) / RIPPLE (140-200) / GAMMA (30-110) /SPINDLES (12-16) / NOFILTER / THETAALPHAGAMMA
% - featureName =  'COHERENCE';         % Options: SMOOTHBANDPOWER / COHERENCE / LOGBANDPOWER
% - detectorType = 'MULTISITE';      % Options: NEURALMODEL / MULTISITE 
% - stimulationType = 'NEXTTRIAL';      % Options: REALTIME / NEXTTRIAL
% - stateOutput = 'MEAN';               % Options: MEAN / LOWER / UPPER
%
% Stimulation Parameters:
% - sCoreParams.stimulator.stimChannelUpper = [1,2];    % Which channel to stim on when Feature is above UpperThreshold (ONLY used for MULTISITE stim)
% - sCoreParams.stimulator.stimChannelLower = [3,4];    % Which channel to stim on when Feature is below LowerThreshold (ONLY used for MULTISITE stim) - (Default same channels for Lower and Upper)
% - sCoreParams.stimulator.maxNStimTrials = 5;          % Stimulate on N (maxNStimTrials) out of M trials (default 5 out of 10 trials)
% - sCoreParams.stimulator.outOfMTrials = 10;           % if M=0 do not take this into account!
%
%
% NOTE: Do NOT modify Inputs or outputs
%
% If you need to modify additional parameters look in file InitCoreParams.m for defaults and parameters names
% @Rina Zelmann 2016-2018

%%%%%%%%%%
%% Type of experiment
experimentType = 'ECR'; % this defines the model

%% Bipolar Channels -
% We could have N (default 10) channels as long as channel1 & channel2 consist of vectors (bipolar channels are channel1[i]-channel2[i]) 
% channel1 & channel2 are contact numbers from NSP 
sCoreParams.decoders.txDetector.channel1 = 1:sCoreParams.decoders.txDetector.MaxNumberChannels; 
sCoreParams.decoders.txDetector.channel2 = [2:sCoreParams.decoders.txDetector.MaxNumberChannels+1]; 
sCoreParams.decoders.txDetector.triggerChannel = 131; % Channel were digital input corresponding to image onset is (usually: 131 - ainp3)  
sCoreParams.decoders.txDetector.stimTriggerChannel = sCoreParams.decoders.txDetector.triggerChannel; %use same trigger for image onset and stim trigger
sCoreParams.decoders.txDetector.behavioralChannel = 132; % Channel were BEHAVIOURAL data is input (usually: 132 - ainp4)  

%Do not change this line:
sCoreParams.decoders.txDetector.nChannels = min(length(sCoreParams.decoders.txDetector.channel1),length(sCoreParams.decoders.txDetector.channel2));
%%%%%%%%%%

%% Features and Thresholds
freqBandName = 'THETA';        % Options: THETA (4-8) / ALPHA (8-15) / BETA (15-30) / LOWGAMMA (30-55) / HIGHGAMMA (65-110) / HIGHGAMMARIPPLE (65-200) / RIPPLE (140-200) / GAMMA (30-110) /SPINDLES (12-16) / NOFILTER
featureName =  'COHERENCE';    % Options: SMOOTHBANDPOWER / VARIANCEOFPOWER / COHERENCE 


%Features specific configuration
%sCoreParams.Features.Coherence.lowFreq = 4;     %Frequency band to consider for coherence
%sCoreParams.Features.Coherence.highFreq = 8;
%sCoreParams.Features.Coherence.WindowDurationSec = 0.5;  

% Variants CONFIG - DO NOT CHANGE THESE LINES
[variantConfig, sCoreParams] = selectFrequencyBandConfig(freqBandName, variantConfig,sCoreParams);
[variantConfig, sCoreParams] = selectFeatureConfig(featureName, variantConfig, sCoreParams, 1);
%%%%%%%%%%

%% Detections 
detectorType = 'MULTISITE';         % Options: NEURALMODEL / MULTISITE 
stateOutput = 'MEAN';               % Options: MEAN / LOWER / UPPER

% Indexes of Channels/Pairs used for detection:
% (Could load a file with a vector here!) 
sCoreParams.decoders.txDetector.detectChannelInds = 1:sCoreParams.decoders.txDetector.nFeatures; % use vector of bipolar channels for power feature / use vector of index of pairs for coherence (e.g. [1,2] is 1-2, 1-3 pairs) - pairs are sorted by first channel

% Time of Detection
sCoreParams.decoders.txDetector.delayAfterTriggerSec = 0.25;   % When to start detecting after Detection (image onset) Trigger
sCoreParams.decoders.txDetector.detectionDurationSec = 1;   % For how long should we try to detect after trigger

% Thresholds
sCoreParams.Features.Baseline.thresholdAboveValue = 1000;      % Stim if feature ABOVE this threshold
sCoreParams.Features.Baseline.thresholdBelowValue = -1000;     % Stim if feature BELOW this threshold
%%%%%%%%%%


%% Stimulation Parameters
stimulationType = 'NEXTTRIAL';                      % Options: REALTIME / NEXTTRIAL
sCoreParams.stimulator.stimChannelUpper = [1,2];    % Which channel to stim on when Feature is above UpperThreshold (ONLY used for MULTISITE stim)
sCoreParams.stimulator.stimChannelLower = [3,4];    % Which channel to stim on when Feature is below LowerThreshold (ONLY used for MULTISITE stim) - (Default same channels for Lower and Upper)
        
sCoreParams.stimulator.controlCerestimFromHost = true; % use CERESTIM CONFIGURATION (for ECR) - NEEDs USB connection to Cerestim

sCoreParams.stimulator.maxNStimTrials = 5;          % Stimulate on N (maxNStimTrials) out of M trials (default 5 out of 10 trials)
sCoreParams.stimulator.outOfMTrials = 10;           % if M=0 do not take this into account!

sCoreParams.stimulator.startupTimeSec = 10;         % Wait in seconds before allowing stimulation
sCoreParams.stimulator.refractoryPeriodSec = 2;     % Refractory period in second (most important for real time stim, not for Next trial stim)
sCoreParams.stimulator.delayAfterTriggerSec = 0;    % How long to wait in the case of NEXT TRIAL stim
sCoreParams.decoders.txDetector.delayAfterStimSec = 0; %0.5;    % delay in Seconds after Stimulation occur (to avoid stim artifact being detected)
%%%%%%%%%%

%% Stimulation Artifact
removeStim = 'PASSSIGNAL';                      % Options:  PASSSIGNAL / REMOVESTIMFREQ
sCoreParams.stimulationFrequencyHz = 160;       % Stimulation frequency in Hz used to specify the notch filter to remove it.
sCoreParams.stimulator.amplitude_mA = 6;        % Stimulation amplitude (1mA)
sCoreParams.stimulator.trainDuration = 400;     % Stimulation Train Duration TrainDuration * Freq /1000 = number of pulses in train
%%%%%%%%%%

%% Visualization
sCoreParams.viz.channelInds = 1:sCoreParams.decoders.txDetector.nChannels;      % all channels
sCoreParams.viz.featureInds = 1:sCoreParams.decoders.txDetector.nFeatures;      %All Features -  pairs for coherence!

%% Variants CONFIG - DO NOT CHANGE HERE
variantConfig = selectStateModelConfig(experimentType, variantConfig, featureName);
variantConfig = selectDetectorNeuralModelConfig(detectorType, variantConfig, featureName);
variantConfig = selectStateEstimateOutput(stateOutput, variantConfig);
variantConfig = selectWhenToStimulate(stimulationType, variantConfig, detectorType);
variantConfig = selectWhetherToRemoveStimulationArtifact(removeStim, variantConfig);
%%%%%%%%%%

%% DO NOT REMOVE THIS LINE!
sCoreParams = InitCoreParams_Dependent(sCoreParams);
