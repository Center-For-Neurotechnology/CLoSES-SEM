function runClosedLoopStateEstimate(patientNAME, deciderDIR)

if ~exist('deciderDIR','var'), deciderDIR = 'C:\DeciderData'; end
if ~exist('patientNAME','var'), patientNAME = 'testCLoSES-SEM'; end

%% Add to Path
addpath(genpath('ClosedLoopStimulation'))
addpath(genpath('Decoder_Encoder_Model_MultipleTrajectory'))
addpath(genpath('Models\CLEAR\Model'))


%% RUN Closed-Loop GUI
deciderPatientDir = [deciderDIR, filesep, patientNAME];
GUINeuralDecoderClosedLoopConsole('PatientName', patientNAME, 'DirResults', deciderPatientDir)

