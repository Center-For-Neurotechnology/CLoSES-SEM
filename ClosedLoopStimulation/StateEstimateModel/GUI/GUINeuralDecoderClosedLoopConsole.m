function varargout = GUINeuralDecoderClosedLoopConsole(varargin)
% GUINeuralDecoderClosedLoopConsole MATLAB code for GUINeuralDecoderClosedLoopConsole.fig
%      GUINeuralDecoderClosedLoopConsole, by itself, creates a new GUINeuralDecoderClosedLoopConsole or raises the existing
%      singleton*.
%
%      H = GUINeuralDecoderClosedLoopConsole returns the handle to a new GUINeuralDecoderClosedLoopConsole or the handle to
%      the existing singleton*.
%
%      GUINeuralDecoderClosedLoopConsole('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUINeuralDecoderClosedLoopConsole.M with the given input arguments.
% 
%      GUINeuralDecoderClosedLoopConsole('Property','Value',...) creates a new GUINeuralDecoderClosedLoopConsole or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUINeuralDecoderClosedLoopConsole_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUINeuralDecoderClosedLoopConsole_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% @Rina Zelmann 2016

% Edit the above text to modify the response to help GUINeuralDecoderClosedLoopConsole

% Last Modified by GUIDE v2.5 08-Aug-2018 10:51:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GUINeuralDecoderClosedLoopConsole_OpeningFcn, ...
    'gui_OutputFcn',  @GUINeuralDecoderClosedLoopConsole_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
% global targetConnected;
% global tg;
% global dataStreamHistory;
end

% --- Executes just before GUINeuralDecoderClosedLoopConsole is made visible.
    function GUINeuralDecoderClosedLoopConsole_OpeningFcn(hObject, eventdata, handles, varargin)
        % This function has no output args, see OutputFcn.
        % hObject    handle to figure
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        % varargin   command line arguments to GUINeuralDecoderClosedLoopConsole (see VARARGIN)
      
        %Initialize variables
        if nargin>4 %Check if inputs specified
            for iVarg=1:2:nargin-3 %first 3 are hObject, eventdata, handles
                handles.(varargin{iVarg}) = varargin{iVarg+1};
            end
        end
        if ~isfield(handles,'patientName') && ~isfield(handles,'PatientName')&& ~isfield(handles,'PATIENTNAME') && ~isfield(handles,'pName') && ~isfield(handles,'PName')
            handles.patientName = 'TEST'; %If patient Name is not specified - use: TEST!
        end    
        if isfield(handles,'PatientName'),handles.patientName = handles.PatientName; end
        if isfield(handles,'PATIENTNAME'),handles.patientName = handles.PATIENTNAME; end
        if isfield(handles,'pName'),handles.patientName = handles.pName; end
        if isfield(handles,'PName'),handles.patientName = handles.PName; end
        
        if ~isfield(handles,'dirBase')
            handles.dirBase = pwd; %Compiled program to send should be dirBase/CompileFiles/ClosedLoopStimXpcTarget or selected on initGUI
        end
        if ~isfield(handles,'sCoreParamConfigFileName')
            handles.sCoreParamConfigFileName = '';  %if not specified - used default sCoreParams for this experiemnt type
        end
        if ~isfield(handles,'dirResults') && ~isfield(handles,'DirResults')&& ~isfield(handles,'DIRRESULTS')
            handles.dirResults = ['C:\Temp']; %handles.dirBase; %RIZ: Could be specified as input
        end
        if isfield(handles,'DIRRESULTS'),handles.dirResults = handles.DIRRESULTS; end
        if isfield(handles,'DirResults'),handles.dirResults = handles.DirResults; end
        if ~exist(handles.dirResults,'dir')
            mkdir(handles.dirResults);
        end
        
        % Temporal File to save data (using ReceiveWrite Model)
        handles.fileNameTemporalInfo = ['saveData.mat'];%MUST correspond to ReceiveWrite Model!!! - HARDCODED to working directory FOR NOW!

        % Global Variables initialization
        global sCoreParams;
        global targetConnected;
        global tg;
        global dataStreamHistory;
        global dataTrialByTrialHistory;
        global dataAllTrials;

        sCoreParams = [];
        targetConnected = false;
        tg = [];
        dataStreamHistory=[];
        dataTrialByTrialHistory=[];
        dataAllTrials = [];
        handles.blockRunning = false;
        %userApprovedStart = false;
        guidata(hObject, handles);

        %For threshold, filteredData and unfiteredEEGData the position is
        %determined in real time to account for multiple channels
        % IF UDP packages sent are changed in OutputToVisualization.slx -> modify numbers here

        %local variables -         
        %Default Model Names
        defaultSimulationModel = [handles.dirBase filesep 'ClosedLoopStimulation' filesep 'StateEstimateModel' filesep 'ClosedLoopStim_SimulatedInput_WithDecoderModel'];
        defaultClosedLoopModel = [handles.dirBase filesep 'CompileFiles' filesep 'ClosedLoopStimXpcTarget_WithDecoderModel'];
        defaultNHPModel = [handles.dirBase filesep 'CompileFiles' filesep 'ClosedLoopStimPlexon']; %Since it runs in host computer is the same as simulation (no need for compiled model)!

        %Initialize diary (to save command line as log)
        diary([handles.dirResults, filesep, 'log_',handles.patientName,'_',datestr(now,'yymmdd_HHMM'),'.log'])

        
        %Run configuration figure first to select MODE
        [mode, modelFileName, experimentType, configFileName, simulationFileName, neuralModelFileName] = InitDialogNeuralDecoder(hObject); % mode could be: Simulation or Closed-Loop
        if isempty(mode) || (strcmpi(mode,'No')) % This is returned if option window was closed!
            delete(hObject); 
            %delete(handles.figure1);
            return;
        end
        handles.mode = mode;
        handles.experimentType = experimentType;
        handles.sCoreParamConfigFileName = configFileName;
        handles.simulation.simulationFileName = simulationFileName;
        handles.neuralModelFileName = neuralModelFileName;
        guidata(hObject, handles);

        disp(['Options from InitConfig:'])
        disp(['Mode: ',mode,' -  Experiment Type: ',experimentType])
        disp([' - Simulink Model FileName: ',modelFileName])
        disp([' - Config FileName: ',configFileName])
        disp([' - Simulation FileName: ',simulationFileName])
        disp([' - Neural Model FileName: ',neuralModelFileName])

        % UIWAIT makes GUINeuralDecoderClosedLoopConsole wait for user response (see UIRESUME)
        %uiwait(handles.figure1);
        
        %Initialize Variables and Variants and GUI based on experiment
        initializeVariables(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified
        
        %Initialize UDPCommunication
        InitializeNetwork(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified

        %Pre-Configure GUI and parameters based on experiment type
        % RIZ: this is probably irrelevant IF we select a CONFIG file
        configureGUIBasedOnExperimentType(hObject, [], handles, handles.experimentType);
        handles = guidata(hObject); %Get the handles back after they were modified

        %Add a menu to the GUI
        set(hObject,'toolbar','figure');
             

%         % Patient Specific Configuration - It is at the end of all the configuration to avoid being overwriten by a default value
%         if ~isempty(handles.sCoreParamConfigFileName )
%             patientSpecificConfiguration(hObject, [], handles)
%             handles = guidata(hObject); %Get the handles back after they were modified
%         end
        
        % Choose default command line output for GUINeuralDecoderClosedLoopConsole
        handles.output = hObject;
       
        %Chose execution mode
        handles.modelFileName = modelFileName;
        guidata(hObject, handles);         % Update handles structure
        switch mode
            case 'Simulation'
                if isempty(handles.modelFileName)
                    handles.modelFileName = defaultSimulationModel;
                end
                [~, name] = fileparts(handles.modelFileName);
                handles.modelName = name;
                handles.modelNameClosedLoop = [handles.modelName,'/ClosedLoopControl'];
                guidata(hObject, handles);
                InitialSimulation(hObject, handles);
            case 'Closed-Loop'
                if isempty(handles.modelFileName)
                    hWarnDlg = warndlg({'Are you sure you want to run with default SIMULINK model?'},' Missing Simulink Model File!');
                    uiwait(hWarnDlg);
                    handles.modelFileName = defaultClosedLoopModel;
                end
                [~, name] = fileparts(handles.modelFileName);
                handles.modelName = name;
                handles.modelNameClosedLoop = [handles.modelName,'/ClosedLoopControl'];
                guidata(hObject, handles);
               % slrtexplr %RIZ20161109: BAD HACK!!! To work on RIG
                InitialClosedLoop(hObject, handles);
            case 'NHP'
                if isempty(handles.modelFileName)
                    handles.modelFileName = defaultNHPModel;
                end
                [~, name] = fileparts(handles.modelFileName);
                handles.modelName = name;
                handles.modelNameClosedLoop = [handles.modelName,'/ClosedLoopControl'];
                guidata(hObject, handles);
                % For Real-Time (Decider) NHP
             %   slrtexplr %RIZ20161109: BAD HACK!!! To work on RIG
                InitialClosedLoop(hObject, handles);
                % For Simulated (or USB6009) NHP
                %InitialNHPModelSimulation(hObject, handles);                 
            case 'No'
                disp('Closing Console');
                delete(handles.figure1);
            otherwise
                disp('Closing Console');
                delete(handles.figure1);                
        end 
    end
% --- Outputs from this function are returned to the command line.
    function varargout = GUINeuralDecoderClosedLoopConsole_OutputFcn(hObject, eventdata, handles)
        % varargout  cell array for returning output args (see VARARGOUT);
        % hObject    handle to figure
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        
        % Get default command line output from handles structure
        if isfield(handles,'output')
            varargout{1} = handles.output;
        end
    end
    
% --- Depending on experiment type, pre set objects and parameters    
    function configureGUIBasedOnExperimentType(hObject, eventdata, handles, experimentType)
        global sCoreParams;
    
        switch upper(experimentType)
            case 'MSIT'
                % Default Config is HighGamma + SmoothBandPower
                set(handles.popFreq,'Value',12);     % 12 - ThetaAlphaGamma
                set(handles.popFeature,'Value',5);  % Changed to LOG band power - before: 1=SmoothBandPower
                set(handles.popStimulationType,'Value',2);  %NEXT TRIAL Stimulation (as soon as it detects)
                set(handles.popDetectorType,'Value',1);     %STATEESTIMATE detector
                set(handles.popStateOutput,'Value',1);     % Use mean (before was =2: Upper Bound) for detection
                sCoreParams.stimulationFrequencyHz = 130;
                sCoreParams.stimulator.trainDuration = 600;
                sCoreParams.stimulator.amplitude_mA = 2000;
                handles.controlCerestimFromHost = false;
            case 'ECR'
                % Default Config is Theta + Coherence
                set(handles.popFreq,'Value',1);     %1=Theta
                set(handles.popFeature,'Value',3);  %Coherence
                set(handles.popStimulationType,'Value',2);  %NEXT TRIAL Stimulation (if stim should happen in one trial -> send STIM at trigger of next trial)
                set(handles.popDetectorType,'Value',2);     % STATEESTIMATEMULTISITE Detector
                set(handles.popStateOutput,'Value',1);     % Use Mean State for detection
               sCoreParams.stimulationFrequencyHz = 160;
                sCoreParams.stimulator.trainDuration = 400;
                sCoreParams.stimulator.amplitude_mA = 4000;
                handles.controlCerestimFromHost = true;     %Multisite Stim needs that the Cerestim be controlled from host computer
            case 'CONTINUOUS'   %RIZ: NOT IMPLEMENTED WITH NEURAL ESTIMATE MODEL
                % Default Config is Ripple + SmoothBandPower
                set(handles.popFreq,'Value',7);     %Ripple
                set(handles.popFeature,'Value',1);  %SmoothBandPower
                set(handles.popDetectorType,'Value',1); % RIZ: CHANGE IF implemented for real!!!!
                set(handles.popTriggerType,'Value',2);      %Periodic trigger
                sCoreParams.stimulationFrequencyHz = 60; %RIZ: SINGLE PULSE Stimulation -> write as 60Hz to have a second notch at 60 - RIZ: it DOES not make sense!!
                sCoreParams.stimulator.trainDuration = 60;  %As long as frequency and duratio are the same, it generates a SINGLE PULSE
                sCoreParams.stimulator.amplitude_mA = 6000;
                handles.controlCerestimFromHost = false; %For NOW only 1 channel stim! -> change afterwards
             case 'CLEAR'   %RIZ: USES CLEAR MODEL - > specifed in neuralModelFileName
                % Default Config is Theta + Coherence
                set(handles.popFreq,'Value',13);     %13 - LP7 HG
                set(handles.popFeature,'Value',6);  %FILTEREDandPOWER
                set(handles.popStimulationType,'Value',2);  %NEXT TRIAL Stimulation (if stim should happen in one trial -> send STIM at trigger of next trial)
                set(handles.popDetectorType,'Value',1);     % Simple Detector (called NEURALMODEL detector - this is misleading shold be changed)
                set(handles.popStateOutput,'Value',1);     % Use Mean State for detection
                sCoreParams.stimulationFrequencyHz = 1;
                sCoreParams.stimulator.trainDuration = 1;
                sCoreParams.stimulator.amplitude_mA = 0;
            otherwise
                disp('Error in experiment Type - please configure in GUI');
        end

        %Call the pop objects callbacks to update the variants
        popFreq_Callback(handles.popFreq, eventdata, handles);
        handles = guidata(handles.popFreq); %Get the handles back after they were modified
        popFeature_Callback(handles.popFeature, eventdata, handles);
        handles = guidata(handles.popFeature); %Get the handles back after they were modified
        popDetectorType_Callback(handles.popDetectorType, eventdata, handles);
        handles = guidata(handles.popDetectorType); %Get the handles back after they were modified
        popStimulationType_Callback(handles.popStimulationType, eventdata, handles);
        handles = guidata(handles.popStimulationType); %Get the handles back after they were modified
        popTriggerType_Callback(handles.popTriggerType, eventdata, handles);
        handles = guidata(handles.popTriggerType); %Get the handles back after they were modified
        popStateOutput_Callback(handles.popStateOutput, eventdata, handles);
        handles = guidata(handles.popStateOutput); %Get the handles back after they were modified

        guidata(hObject, handles);
    end
    

% Send configuration parameters and variants to BASE WORKSPACE before RUNNING
    function configureModelParams(hObject, handles)
        %Assign changes variables to workspace - then restart model
        global sCoreParams;
        global tg;
        if (handles.paramChanged == true)
            sCoreParams = InitCoreParams_Dependent(sCoreParams);
            FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);
            assignin('base','sCoreParams',sCoreParams);
        end
        % Configure Variants based on Freq & Feature selections - Requires re-starting model!
        if (handles.variantChanged == true)
            [variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();
            FlattenAndTune(handles.variant.variantConfig,'variantConfig',variantConfigFlatNames);
        end
        if strcmpi(handles.mode,'Closed-Loop') || strcmpi(handles.mode,'NHP')
            if (handles.variantChanged == true || handles.needsToReCompile == true)
                % Needs to Compile model - VARIANTS cannot be changed directly ALWAYS NEED TORECOMPILE (RIZ: not sure why!!)
                set(handles.txtStatus,'String',sprintf('Compiling model...  please wait'));
                compileModelToUpdateVariants(handles.modelFileName, pwd, sCoreParams, handles.variant.variantConfig);
                set(handles.txtStatus,'String',sprintf('Compilation Done!'));
            elseif (handles.paramChanged == true)
                % Update tunable parameters
                tg.load(handles.modelFileName); % Not sure if necessary, but just in case!
                updateTargetParams(hObject, handles);
            else
                tg.load(handles.modelFileName); % Not sure if necessary, but just in case!
            end
        end
        handles.paramChanged = false;
        handles.variantChanged = false;
        handles.needsToReCompile = false;
        guidata(hObject, handles);
    end
    

    function txtTriggerChannel_Callback(hObject, eventdata, handles)
        % hObject    handle to txtTriggerChannel (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        
        % Hints: get(hObject,'String') returns contents of txtTriggerChannel as text
        %        str2double(get(hObject,'String')) returns contents of txtTriggerChannel as a double
        global sCoreParams;

        paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
        paramStr = get(hObject,'UserData');
        sCoreParams.decoders.txDetector.otherTriggerChannel = paramValue;
        handles.paramChanged = true;
        guidata(hObject, handles);

    end

% % --- Executes during object creation, after setting all properties.
%     function txtTriggerChannel_CreateFcn(hObject, eventdata, handles)
%         % hObject    handle to txtTriggerChannel (see GCBO)
%         % eventdata  reserved - to be defined in a future version of MATLAB
%         % handles    empty - handles not created until after all CreateFcns called
%         
%         % Hint: edit controls usually have a white background on Windows.
%         %       See ISPC and COMPUTER.
%         if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%             set(hObject,'BackgroundColor','white');
%         end
%     end

% --- Executes on button press in btnStart.
    function btnStart_Callback(hObject, eventdata, handles)
        global sCoreParams;
        global dataAllTrials;
        global stimInfo;

        % Check that number of features for Neural Model and for sCoreParams are the same
        % (otherwise it will crash later on)
        if (handles.paramChanged == true)
            sCoreParams = InitCoreParams_Dependent(sCoreParams);
        end
        if sCoreParams.decoders.txDetector.nFeaturesUsedInDetection ~= handles.neuralModelParams.nFeaturesPerEpoch
            hWarnDlg = warndlg(['Different Number of selected Features (',num2str(sCoreParams.decoders.txDetector.nFeatures) ,') than Parameters (',num2str(handles.neuralModelParams.nFeaturesPerEpoch),')'],' Wrong Number Features!');
            uiwait(hWarnDlg);
            return;
        end
        
        %Assign changed variables to workspace
        hObjectGUI = hObject.Parent;
        configureModelParams(hObjectGUI, handles);
        handles = guidata(hObjectGUI);
        
        %Initialize Plots and lists
        initializePlots(hObjectGUI, handles);
        handles = guidata(hObjectGUI);
        initializeWithControlValues(hObjectGUI, handles)
        handles = guidata(hObjectGUI);
       
        %add time information
        handles.startTime = datestr(now,'HH:MM:SS');
        guidata(hObjectGUI, handles);
        
        %Initialize dataTrials and stimInfo to only save this experiment
        dataAllTrials = [];
        stimInfo = [];

        %Initialize UDPCommunication
        InitializeNetwork(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified

       
        % Disable This START button until STOP is pressed (to ensure only it is run only once)
        set(hObject,'Enable','off');
        % Disable also the COMPILE button until STOP is pressed (to ensure  it not run while running system)
        set(handles.btnCompile,'Enable','off');
        
        %updateDetVizChannelsList(hObject, handles);
        if strcmpi(handles.mode,'Closed-Loop') || strcmpi(handles.mode,'NHP')
            disp('Starting Closed-Loop Stimulation Control!')
            %StartClosedLoop(hObject, handles);
            StartAquisitionBlock(hObjectGUI, handles);
        elseif strcmpi(handles.mode,'Simulation')
            disp('Starting Simulation mode')
            %StartSimulation(hObject, handles);
            RunSimulation(hObjectGUI, handles);
        else
            disp(['Warning wrong mode: ', handles.mode,' - it must be Closed-Loop or Simulation'])
        end
    end

% --- Executes on button press in btnStop.
    function btnStop_Callback(hObject, eventdata, handles)
        %Just in case STOP everything - eventhough it would actually be the
        %target PC or simulation
        global tg;
        tic
        evalin('base','StopWriter()');
        
        %Save experimental Data
        disp('Saving Closed-Loop Stimulation HOST Files!')
        SessionDataConfig = saveExperimentData(hObject, handles);
        
        % Stop visualization 
        if isfield(handles,'vizTimer')
            stop(handles.vizTimer);
        end
        % Stop Simulink
        if strcmpi(handles.mode,'Simulation') 
            disp('Stoping Closed-Loop Stimulation Control - Simulation!')
            try
                set_param(handles.modelName,'simulationcommand','stop');
            catch
                disp('Error Closing Model!')
            end
            saveSimulationFilesInHost(hObject, handles, SessionDataConfig);
 %       elseif strcmpi(handles.mode,'NHP') 
 %           disp('Stoping Closed-Loop Stimulation Control - NHP Plexon!')
 %           set_param(handles.modelName,'simulationcommand','stop');
          %  stopPlexonServer(handles.plexon);
        else %Assumes that it is running on decider (human or NHP)
            % Move files from Target computer to HOST
            disp('Stoping Closed-Loop Stimulation Control!')
            if strcmpi(get(tg,'Status'), 'running')
                tg.stop;
            end
            if isfield(handles,'cerestim') && ~isempty(handles.cerestim)
                disconnectCereStim(handles.cerestim);
            end
            disp('Saving Closed-Loop Stimulation TARGET Files!')
            saveTargetFilesInHost(hObject, handles);
            disp('Saving Performance Information!')
            saveTargetPerformanceInfo(hObject, handles, SessionDataConfig);
        end

        %assignin('base','streamDataHeaders',handles.plotInfo);
        %assignin('base','resultsDir',handles.dirResults);
        set(handles.txtStatus,'String','');
        set(handles.btnStart,'Enable','on'); % Enable START button again
        set(handles.btnCompile,'Enable','on'); % Enable also Compile button again

        toc
    end

    function SessionDataConfig=saveExperimentData(hObject, handles)
    % Saves experimental data and moves allHistorical data from saveData temporal file to permanent file
        global dataAllTrials;
        global sCoreParams;
        global stimInfo;

        SessionDataConfig = [];
        fileNameSessionData = [handles.dirResults, filesep, 'DeciderData_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.mat'];
        fileNameSessionTrialByTrialData = [handles.dirResults, filesep, 'DeciderTrialByTrialData_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.mat'];
        if exist(handles.fileNameTemporalInfo, 'file') && ~exist(fileNameSessionData, 'file')
           set(handles.txtStatus,'String','Saving Data... Please wait');

           %           stData = load(handles.fileNameTemporalInfo); %Load temporal data
           %           SessionData.streamData = stData.savedData; %stData.ans;  %
           SessionDataConfig.patientName = handles.patientName;
           SessionDataConfig.experimentType = handles.experimentType;
           SessionDataConfig.sCoreParams = sCoreParams;
           SessionDataConfig.savedDataHeaders = handles.plotInfo;
           SessionDataConfig.feature = handles.feature;
           SessionDataConfig.freqBandName = handles.freqBandName;
           SessionDataConfig.detectorType = handles.detectorType;
           SessionDataConfig.variants = handles.variant;
           SessionDataConfig.mode = handles.mode;
           SessionDataConfig.modelFileName = handles.modelFileName;
           SessionDataConfig.neuralModelParams = handles.neuralModelParams;
           SessionDataConfig.startTime = handles.startTime;
           SessionDataConfig.endTime = datestr(now,'HH:MM:SS');
           SessionDataConfig.date = datestr(now,'yyyymmdd');
           SessionDataConfig.files.neuralModelFileName = handles.neuralModelFileName;
           SessionDataConfig.files.modelFileName = handles.modelFileName;
           SessionDataConfig.files.sCoreParamConfigFileName = handles.sCoreParamConfigFileName;
           SessionDataConfig.files.simulationFileName = handles.simulation.simulationFileName;
           SessionDataConfig.simulationInfo = handles.simulation;
           SessionDataConfig.channelNames = sCoreParams.decoders.txDetector.channelNames;
           SessionDataConfig.channelInfo = handles.channelInfo;
           SessionDataConfig.bipolarChannelNames = sCoreParams.decoders.txDetector.bipolarChannelNames;
           SessionDataConfig.featuresInfo.featureNames = sCoreParams.decoders.txDetector.featureNames;
           SessionDataConfig.featuresInfo.featureIndexesComputed = SessionDataConfig.sCoreParams.decoders.txDetector.detectChannelInds;
           SessionDataConfig.featuresInfo.featureNamesComputed = sCoreParams.decoders.txDetector.featureNames(SessionDataConfig.featuresInfo.featureIndexesComputed);
           SessionDataConfig.featuresInfo.featureNamesSaved = sCoreParams.viz.featureNames;
           SessionDataConfig.featuresInfo.featureIndexesSaved = sCoreParams.viz.featureInds;

           dataTrialByTrial = dataAllTrials;
           stimulationData = stimInfo;
           
           save(fileNameSessionTrialByTrialData,'SessionDataConfig','dataTrialByTrial','stimulationData'); % Save trial by trial data first (it is way smaller)
          %movefile(handles.fileNameTemporalInfo,fileNameSessionData,'f')
           copyfile(handles.fileNameTemporalInfo,fileNameSessionData,'f')

           save(fileNameSessionData,'SessionDataConfig','dataTrialByTrial','stimulationData','-append');

           set(handles.txtStatus,'String','Saving Data... Done!');
           disp(['Data Saved to ',fileNameSessionData,' - Do not forget to get it!']);
           guidata(hObject, handles);

        else
           SessionDataConfig=[];
           disp(['Could not find ',handles.fileNameTemporalInfo,' savedData file! if you already hit STOP it was saved then.']);
       end
    end
    
    function saveTargetFilesInHost(hObject, handles)
    %Gets info from target computer and saves them on host
    global tg;
    global sCoreParams;
    
    currentDir = pwd;
    fileNameSessionDataFeat = [handles.dirResults, filesep, 'DeciderTARGETData_Feat_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.dat'];
    fileNameSessionDataEEG = [handles.dirResults, filesep, 'DeciderTARGETData_EEG-', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.dat'];
    fileNameSessionDataStim = [handles.dirResults, filesep, 'DeciderTARGETData_Stim_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.dat'];

    try
        cd(handles.dirResults)
        % Get files from TARGET computer
        SimulinkRealTime.copyFileToHost(tg, sCoreParams.target.filenames.featTh);
        SimulinkRealTime.copyFileToHost(tg, sCoreParams.target.filenames.eeg);
        SimulinkRealTime.copyFileToHost(tg, sCoreParams.target.filenames.stimInfo);
        % change name to keep all files
        copyfile(sCoreParams.target.filenames.featTh,fileNameSessionDataFeat,'f')
        copyfile(sCoreParams.target.filenames.eeg,fileNameSessionDataEEG,'f')
        copyfile(sCoreParams.target.filenames.stimInfo,fileNameSessionDataStim,'f')

        cd(currentDir);
    catch
         warning('Problem Transfering data from TARGET. Remember to copy it after!');
         cd(currentDir);
    end
    %To read them
    % idFeatFile=fopen('FEAT_001.dat')
    % dataFeatTh = fread(idFeatFile);
    % fclose(idFeatFile);
    % x=SimulinkRealTime.utils.getFileScopeData(dataFeatTh);
   
    end

    
    function saveTargetPerformanceInfo(hObject, handles, SessionDataConfig)
    
        global tg;
        fileNamePerformance = [handles.dirResults, filesep, 'DeciderPerformance_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.mat'];
        
        %consoleLog = SimulinkRealTime.utils.getConsoleLog(tg,1);
        
        infoPerformance.TETLog = tg.TETLog;
        infoPerformance.MinTET = tg.MinTET;
        infoPerformance.MaxTET = tg.MaxTET;
        infoPerformance.CPUoverload = tg.CPUoverload;
        infoPerformance.SessionTime =  tg.SessionTime;
        infoPerformance.ExecTime = tg.ExecTime;
        infoPerformance.SampleTime=tg.SampleTime;

        %infoPerformance.consoleLog = consoleLog;
        
         save(fileNamePerformance,'SessionDataConfig','infoPerformance')
    
    end
    
    
    function saveSimulationFilesInHost(hObject, handles, SessionDataConfig)
    %Gets info from target computer and saves them on host
    
    fileNameFeaturesFromModel = [handles.dirResults, filesep, 'SimulationData_Feat_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.mat'];
    
    try
        % Get files from TARGET computer
        copyfile('saveFeaturesFromModel.mat',fileNameFeaturesFromModel,'f');
        save(fileNameFeaturesFromModel,'SessionDataConfig','-append');

    catch
        warning('Problem Saving data from Simulation File. Remember to copy it after!');
    end
    
    end
    
    function InitialSimulation(hObject, handles)
        %global targetConnected;
        global sCoreParams;

        %Generate Random data or load from file
        %[sCoreParams, sInputData, sInputTrigger] = initializationScript('SIMULATION', sCoreParams, handles.freqBandName, handles.feature,  handles.stimulationType,  handles.detectorType, contactNumbers1, contactNumbers2, detectChannelInds, triggerChannel, whatTypeSimulation, realDataFileName);

        if isfield(handles,'simulation') && ~isempty(handles.simulation.simulationFileName)
            if ~isempty(strfind(handles.simulation.simulationFileName,'PREPROCESSED'))
                handles.simulation.typeSimulation = 'PREPROCESSED'; % if 'PREPROCESSED' is in the name is a preprocessed file from ft(bipolar)
            else
                handles.simulation.typeSimulation = 'REAL';     % otherwise is a referential raw EEG data 
            end
        else
            handles.simulation.simulationFileName =[];  %in case it didn't exist
            handles.simulation.typeSimulation = 'SINE'; %if file is not specified assume sine+rand
        end
        %[sCoreParams, variantConfig, sInputData, sInputTrigger, sRandomStimulation] = initializationScript(whatToDo, sCoreParams, freqBandName, featureName, stimulationType, detectorType, triggerType, contactNumbers1, contactNumbers2, triggerChannel, whatTypeSimulation, realDataFileName)
        %[sCoreParams, variantParams, variantConfig, variantConfigFlatNames, sInputData, sInputTrigger] = InitializeSimulation('SIMULATION');
        
        %[neuralModelParams, variantConfig, sCoreParams] = initNeuralModelParams(handles.neuralModelFileName, handles.variant.variantConfig, sCoreParams, handles.freqBandName, handles.feature);

        [sCoreParams, variantConfig,  sInputData, sInputTrigger, sMultiTimeInputData, sMultiTimeInputTrigger] = initializationScript('SIMULATION', sCoreParams, handles.freqBandName, handles.feature, handles.stimulationType, handles.detectorType, handles.triggerType, handles.experimentType , handles.stateOutput, [],[],[], handles.simulation.typeSimulation, handles.simulation.simulationFileName, handles.variant.variantConfig, handles.neuralModelParams);

        % Patient Specific Configuration - It is at the end of all the configuration to avoid being overwriten by a default value
        if ~isempty(handles.sCoreParamConfigFileName )
            patientSpecificConfiguration(hObject, [], handles)
            handles = guidata(hObject); %Get the handles back after they were modified
        end
        
        handles.sCoreParams = sCoreParams;
        handles.variant.variantConfig = variantConfig;
       % handles.sInputData = {sInputDataOdd, sInputDataEven};
       % handles.sInputTrigger = {sInputTriggerOdd, sInputTriggerEven};
        %handles.neuralModelParams = neuralModelParams;
        guidata(hObject, handles);
        initializeParameters(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified

        %assignin('base','sCoreParams',sCoreParams);
        %assignin('base','variantParams',variantParams);
        %assignin('base','variantConfig',variantConfig);
        %assignin('base','sInputData',sInputData);
        %assignin('base','sInputTrigger',sInputTrigger);
        
        %Load system - This is done every time we start the simulation to allow modification of fix length parameters 
        load_system(handles.modelName);
         % Update handles structure
        guidata(hObject, handles);
        
        % Get Default values and update GUI objects
        updateGUIObjectsFromCurrent(hObject, handles);

        %Initialize plots with empty dataStreamHistory and dataTrialByTrialHistory
        %Initialize Plots and lists
        updateDetVizChannelsList(hObject, handles);
        handles = guidata(hObject);
        initializePlots(hObject, handles);
        handles = guidata(hObject);
        initializeWithControlValues(hObject, handles)
        handles = guidata(hObject);

        %handles = guidata(handles.popFeature); %Get the handles back after they were modified
        %targetConnected = true;

    end
    
    function InitialNHPModelSimulation(hObject, handles)
        global sCoreParams;
        %Initilize parameters and variants
        [sCoreParams, variantConfig] = initializationScript('NHP', sCoreParams, handles.freqBandName, handles.feature, handles.stimulationType,  handles.detectorType, handles.triggerType, handles.stateOutput, [],[],[],[],[], handles.variant.variantConfig);
        %[sCoreParams, variantConfig, sInputData, sInputTrigger] = initializationScript('SIMULATION', sCoreParams, handles.freqBandName, handles.feature,  handles.stimulationType,  handles.detectorType, handles.triggerType, contactNumbers1, contactNumbers2, detectChannelInds, triggerChannel);
        handles.sCoreParams = sCoreParams;
        handles.variant.variantConfig = variantConfig;
        guidata(hObject, handles);
        
        % Initiliaze Parameters
        initializeParameters(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified

        %Load system - This is done every time we start the simulation to allow modification of fix length parameters
        load_system(handles.modelName);
        % Update handles structure
        guidata(hObject, handles);

        % Get Default values and update GUI objects
        updateGUIObjectsFromCurrent(hObject, handles);

        %Initialize plots with empty dataStreamHistory
        updateDetVizChannelsList(hObject, handles);
        handles = guidata(hObject);
        initializePlots(hObject, handles);  %Initialize Plots and lists
        handles = guidata(hObject);
        initializeWithControlValues(hObject, handles)
        handles = guidata(hObject);
    end
    
    function InitialNHPModelRealTime(hObject, handles)
        global sCoreParams;

        [sCoreParams, variantParams, variantConfig, variantConfigFlatNames] = InitializeNHPPlexon( sCoreParams);
        handles.sCoreParams = sCoreParams;
        handles.variant.variantConfig = variantConfig;
        guidata(hObject, handles);
    end
    
    function RunSimulation(hObject, handles)
        %Load simulation model
        disp('Running simulation')

 %       simMode = get_param(modelName, 'SimulationMode');
        %Start Simulation
%        handles.simModel = sim(handles.modelFileName, 'StopTime', '1000', 'ZeroCross','on', 'SaveTime','on','TimeSaveName','tout', ...
%            'SaveOutput','on','OutputSaveName','youtNew',...
%            'SignalLogging','on','SignalLoggingName','logsout');

        load_system(handles.modelName);
        set_param(handles.modelName,'simulationcommand','start');
        assignin('base','guiParamsTempFilename',handles.fileNameTemporalInfo);
        evalin('base','StartWriter');

        %Start Visualization
        set(handles.txtStatus,'String','Running Simulation');
        disp('Starting Visualization Update');
        guidata(hObject, handles);
        StartVisualizationBlock(hObject, handles);
       % save(simOut)
    end

    function InitialClosedLoop(hObject, handles)
        agentTimer = timer('TimerFcn',{@checkAgentsSRT, hObject, handles} ,'Period',1,'BusyMode','drop','ExecutionMode','fixedRate');
        assignin('base','agentTimer',agentTimer);
        handles.agentTimer = agentTimer;
        guidata(hObject, handles);
        agentTimer.TimerFcn = {@checkAgentsSRT, hObject, handles}; %Reassign to have itself in the handles - RIZ:There is probably a cleaner way!
        start(agentTimer)
    end

%% Function that actualy do something (based on Anish's NeuroModConsole)
    function checkAgentsSRT(h,~, hObject, handles)
        %Similar to CheckAgents but modified for simulink real time
        global targetConnected;
        global tg;

        try
            if ~targetConnected
                % The lack of a semicolon here is necessary!
                % Otherwise, the xpc object doesn't actually re-check.
                %tg = xpctarget.xpc('xCoreTarget')  %RIZ: check if name is correct or changed in SRT
                tg =  SimulinkRealTime.target('xCoreTarget')
            end
            set(handles.txtStatus,'String',sprintf('Searching for xPC...is it on? %0.f',h.TasksExecuted));
            
            if ~isempty(tg) && strcmpi(tg.Connected,'Yes')
                targetConnected = true;
                set(handles.txtStatus,'String','Target Connected');
                disp('Target Connected - Starting Closed-Loop');
                pause(.001);
                set(handles.txtStatus,'String','Initializing...');
                pause(.001);
                InitialAquisitionBlock(hObject, handles); %STARTS acquisition block!
                handles = guidata(hObject); %Get the handles back after they were modified
                if ishandle(handles.txtStatus)
                    set(handles.txtStatus,'String','');
                end
                pause(.5);
                stop(h);
            else
               set(handles.txtStatus,'String',sprintf('xPC target not found...is it on? If not boot and restart! '));
            end
            % Update handles structure
            guidata(hObject, handles);
            
        catch e
            disp(e.stack(1));
            disp(e.message);
            targetConnected = false;
        end
        
 end

    function InitialAquisitionBlock(hObject, handles)
        global tg;
        global sCoreParams;

         %Stop timer that checks targe computer
        stop(handles.agentTimer)

        %       [neuralModelParams, variantConfig, sCoreParams] = initNeuralModelParams(handles.neuralModelFileName, handles.variant.variantConfig, sCoreParams, handles.freqBandName, handles.feature);
        % Perhaphs this step is not necessary... but it won't hurt to have it and is exactly like simulation
        [sCoreParams, variantConfig] = initializationScript('REAL-TIME', sCoreParams, handles.freqBandName, handles.feature, handles.stimulationType, handles.detectorType, handles.triggerType, handles.experimentType, handles.stateOutput, [],[],[], [], [], handles.variant.variantConfig, handles.neuralModelParams);
        
        % Patient Specific Configuration - It is at the end of all the configuration to avoid being overwriten by a default value
        if ~isempty(handles.sCoreParamConfigFileName )
            patientSpecificConfiguration(hObject, [], handles)
            handles = guidata(hObject); %Get the handles back after they were modified
        end
        
        %handles.neuralModelParams = neuralModelParams;
        handles.variant.variantConfig = variantConfig;
        handles.sCoreParams = sCoreParams;
        guidata(hObject, handles);
        
        initializeParameters(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified
        
        % Changed to Compile on COMPILE button instead
        % BEfore: Compile (at Button Start) since for sure there is change of config since last time
        handles.needsToReCompile = true; % RIZ: change to false for DEMO? probably NOT enough
        
        %Initialize Cerestim
         if handles.controlCerestimFromHost == true % Always connect again (we disconnect on STOP)&& (~isfield(handles,'cerestim') || isempty(handles.cerestim))
            [cerestim, res] = initializeCereStim(sCoreParams.stimulationFrequencyHz, sCoreParams.stimulator.trainDuration, sCoreParams.stimulator.amplitude_mA);
            choice='Re-Connect';
            while (res<0 || isempty(res)) && strcmpi(choice,'Re-Connect')
                [cerestim, res] = initializeCereStim(sCoreParams.stimulationFrequencyHz, sCoreParams.stimulator.trainDuration, sCoreParams.stimulator.amplitude_mA);
                choice = questdlg({'Continue WITHOUT Cerestim?'},'Cerestim NOT Connected!', 'Continue','Re-Connect','Cancel','Cancel');
                %                uiwait(hDlg);
                switch choice
                    case 'Continue'
                        disp([choice ' without Cerestim.'])
                    case 'Re-Connect'
                        disp([choice '... trying again to connect.'])
                    case 'Cancel'
                        disp([choice ' - No Cerestim found.'])
                        btnStop_Callback(handles.btnStop, [], handles)
                        return;
                end
            end
            handles.cerestim = cerestim;
            guidata(hObject, handles);
        end
        
        % Load model to TARGET pc 
        tg.load(handles.modelFileName);
  %      updateTargetParams(hObject, handles); % added RIZ 20170515 - it should update parameters on decider that are then read  - a bit circular, probably I should fine a better solution!

        % Get Default values and update GUI objects
        updateGUIObjectsFromCurrent(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified

        %StartAquisitionBlock(hObject, handles);
        %Initialize plots with empty dataStreamHistory
%        global dataStreamHistory;
%        dataStreamHistory = nan( handles.params.streamDepthSamp,  sCoreParams.write.maxSignalsPerStep); % dataStreamHistory is the data coming from UDP - here we only specify the size
        %Initialize Plots
        updateDetVizChannelsList(hObject, handles);
        handles = guidata(hObject);
        initializePlots(hObject, handles);
        handles = guidata(hObject);
        initializeWithControlValues(hObject, handles)
        handles = guidata(hObject);
    end
    
    function StartAquisitionBlock(hObject, handles)
        global tg;
        global sCoreParams;

        tg.stop; % In case it was still running
        tg.set('CommunicationTimeOut', 50);
          
        %evalin('base','StopWriter');
        %Assign changed variables to workspace
        %Starts the model and the data writer
        % Initialize Cerestim
        if handles.controlCerestimFromHost == true % Always connect again (we disconnect on STOP)&& (~isfield(handles,'cerestim') || isempty(handles.cerestim))
            [cerestim, res] = initializeCereStim(sCoreParams.stimulationFrequencyHz, sCoreParams.stimulator.trainDuration, sCoreParams.stimulator.amplitude_mA);
            choice='Re-Connect';
            while (res<0 || isempty(res)) && strcmpi(choice,'Re-Connect')
                [cerestim, res] = initializeCereStim(sCoreParams.stimulationFrequencyHz, sCoreParams.stimulator.trainDuration, sCoreParams.stimulator.amplitude_mA);
                choice = questdlg({'Continue WITHOUT Cerestim?'},'Cerestim NOT Connected!', 'Continue','Re-Connect','Cancel','Cancel');
                %                uiwait(hDlg);
                switch choice
                    case 'Continue'
                        disp([choice ' without Cerestim.'])
                    case 'Re-Connect'
                        disp([choice '... trying again to connect.'])
                    case 'Cancel'
                        disp([choice ' - No Cerestim found.'])
                        btnStop_Callback(handles.btnStop, [], handles)
                        return;
                end
            end
            handles.cerestim = cerestim;
            guidata(hObject, handles);
        end
        
        %Start Experiment
        tg.start;
        %StartWriter;
        assignin('base','guiParamsTempFilename',handles.fileNameTemporalInfo);
        evalin('base','StartWriter');
        
        set(handles.txtStatus,'String','Running Closed-Loop');
        StartVisualizationBlock(hObject, handles);
    end
     
    function StartVisualizationBlock(hObject, handles)
        global sCoreParams;

        %Start Visualization Update Timer
        %vizTimer = timer('TimerFcn',{@UpdateViz, hObject, handles},'Period',sCoreParams.write.broadcastSec / 5,'BusyMode','drop','ExecutionMode','fixedRate');
        vizTimer = timer('TimerFcn',{@UpdateViz, hObject, handles},'Period',0.005,'BusyMode','drop','ExecutionMode','fixedRate');
        assignin('base','vizTimer',vizTimer);
        handles.vizTimer = vizTimer;
        handles.blockRunning = true;
        disp('In StartVisualizationBlock')
        % Update handles structure
        guidata(hObject, handles);
        vizTimer.TimerFcn = {@UpdateViz, hObject, handles}; %Reassign to have itself in the handles - RIZ:There is probably a cleaner way!
        start(vizTimer);
    end

            
        
    function InitializeNetwork(hObject, handles)
    % Initialize or Reset the receiving UDP socket (the one used by ReceiveWrite.slx model
    if isfield(handles,'vizContinuousSocket') && handles.vizContinuousSocket>=0
        pnet(handles.vizContinuousSocket, 'close')
        pnet(handles.vizTriaByTrialSocket, 'close'); % Assumes both are open or not together
    else
        %Close all connections and Initialize UDPCommunication for first time
        pnet('closeall')
    end
    % Initilize UDP socket - There are now 2 sockets (ports) one for
    % Continuous data and one for TrialByTrialData
    handles.network.vizContinuousSocket = InitUDPreceiver('127.0.0.1',59124); % Use this port 59124 for CONTINUOUS data % For target PC keep tde correct 49152–65535  range!
    handles.network.vizTrialByTrialSocket = InitUDPreceiver('127.0.0.1',59134); % Use this port 59134 for TRIAL by TRIAL data % For target PC keep tde correct 49152–65535  range!
   if (handles.network.vizContinuousSocket<0) || (handles.network.vizTrialByTrialSocket<0)
        disp('ERROR:: Initializing UDP receiver')
    end
    % Update handles structure
    guidata(hObject, handles);
    end
    
    function initializeVariables(hObject, handles)
        global sCoreParams;

        %Initial Parameters
        sCoreParams = InitCoreParams;
        %Initial Variants
        [variantParams, variantConfig] = InitVariants();
         %Assign Variants
        handles.variant.variantParams = variantParams;
        handles.variant.variantConfig = variantConfig;
        [variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();
        FlattenAndTuneVariants(variantParams,'variantParams',variantParamsFlatNames);
        FlattenAndTune(variantConfig,'variantConfig',variantConfigFlatNames);

        %initialize Neural Model Parameters
        %handles.neuralModelParams.nEpochs =1; 
        [neuralModelParams, sCoreParams] = initModelParams(handles.neuralModelFileName,  sCoreParams, handles.experimentType);
        handles.neuralModelParams = neuralModelParams;
        sCoreParams.neuralModelParams =neuralModelParams;
        
        % Assign sCoreParams and Variants
        handles.sCoreParams = sCoreParams;
        FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);
        assignin('base','sCoreParams',sCoreParams);
        handles.paramChanged = false;
        assignin('base','variantParamsFlatNames',variantParamsFlatNames);
        %assignin('base','variantConfigFlatNames',variantConfigFlatNames);

        handles.variantChanged = true;
        handles.needsToReCompile = false; %RIZ -> check if false is OK?!?!
        
        % Update handles structure
        handles = orderfields(handles);
        guidata(hObject, handles);
    end
    
    function patientSpecificConfiguration(hObject, eventdata, handles)
        %Configure parameters (sCoreParams and Variants) based on patient specific config file
        % This function should only be called if there is a patient specific file
        % RIZ: IMPROVED - CHECK! NOTHING SHOULD BE HARDCODED! NAMES IN MENU SHOULD CORRESPOND TO VARIANTS AND USE A SELECTOR 
        global sCoreParams;
        
        % Read file
        [configPath, sCoreFileNameOnly] = fileparts(handles.sCoreParamConfigFileName);
        addpath(configPath);
        [sCoreParams, variantConfig] = feval(sCoreFileNameOnly, sCoreParams, handles.variant.variantConfig);
        sCoreParams = InitCoreParams_Dependent(sCoreParams);

        %Assign Variants
        [variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();
        FlattenAndTuneVariants(handles.variant.variantParams,'variantParams',variantParamsFlatNames);
        FlattenAndTune(variantConfig,'variantConfig',variantConfigFlatNames);
        assignin('base','variantParamsFlatNames',variantParamsFlatNames);
            
        % pop Menus - Make selection based on variants
       % possibleFreqLow = [4,8,15,30,65,140,65200,80,30110,1216,0,4865200,765]; %RIZ: Poor HACK!! - IMPROVE!!!
        %possibleFeaturesInPopMenu = [3,4,5,2,7,8]; %Poor HACK!! Corresponds to: SmoothBandPower=3, VarianceOfPower=4, Coherence=5, IED=2, LOGBandPower
        %possibleDetectorsInPopMenu = [1,2]; %Poor HACK!! Corresponds to: NeuralModel =1 / NeuralModel Multisite =2
        %possibleStimTypeInPopMenu = [1,3;2,4]; %Poor HACK!! Corresponds to: CONTINUOUS: WHICH_DETECTOR={1,3} / TRIGGER: WHICH_DETECTOR={4,5} / MULTISITE: WHICH_DETECTOR={6,7}
         %set(handles.popFreq,'Value',find(possibleFreqLow==variantConfig.FREQ_LOW));
        %set(handles.popFeature,'Value',find(possibleFeaturesInPopMenu==variantConfig.WHICH_FEATURE));
        %[row, col] = find(possibleStimTypeInPopMenu==variantConfig.STIMULATION_TYPE);

        [freqBandName, indFreqInGUI] = selectFrequencyNameFromVariantConfig(variantConfig);
        set(handles.popFreq, 'Value', indFreqInGUI);
        [featureName, indFeatureInGUI] = selectFeatureNameFromVariantConfig(variantConfig);
        set(handles.popFeature, 'Value', indFeatureInGUI);
        [stimulationType, indStimulationInGUI] = selectStimulationTypeFromVariantConfig(variantConfig);
        set(handles.popStimulationType,'Value', indStimulationInGUI);
        [detectorName, indDetectorInGUI] = selectDetectorTypeFromVariantConfig(variantConfig);
        set(handles.popDetectorType,'Value',indDetectorInGUI);
        [modelOutput, indModelOutputInGUI] = selectModelOutputFromVariantConfig(variantConfig);
        set(handles.popStateOutput,'Value',indModelOutputInGUI);  % MEAN=1 / UPPERBOUND=2 / LOWERBOUND=3
       
        % Call the pop objects callbacks to update the variants
        popFreq_Callback(handles.popFreq, eventdata, handles);
        handles = guidata(handles.popFreq); %Get the handles back after they were modified
        popFeature_Callback(handles.popFeature, eventdata, handles);
        handles = guidata(handles.popFeature); %Get the handles back after they were modified
        popDetectorType_Callback(handles.popDetectorType, eventdata, handles);
        handles = guidata(handles.popDetectorType); %Get the handles back after they were modified
        popStimulationType_Callback(handles.popStimulationType, eventdata, handles);
        handles = guidata(handles.popStimulationType); %Get the handles back after they were modified
        popTriggerType_Callback(handles.popTriggerType, eventdata, handles);
        handles = guidata(handles.popTriggerType); %Get the handles back after they were modified
        popStateOutput_Callback(handles.popStateOutput, eventdata, handles);
        handles = guidata(handles.popStateOutput); %Get the handles back after they were modified
        % Mark variant change
        handles.variant.variantConfig = variantConfig;
        handles.variantChanged = true;

        % Assign sCoreParams
        handles.sCoreParams = sCoreParams;
        FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);
        assignin('base','sCoreParams',sCoreParams);

        guidata(hObject, handles);
        
    end
    
    function initializeParameters(hObject, handles)
        %more config - Expected data sizes
        global sCoreParams;

       % handles.params.expectedDataWidth = sCoreParams.write.maxSignalsPerStep;% +1;
        handles.params.streamDepthSamp = round(sCoreParams.viz.streamDepthSec  / sCoreParams.core.stepPeriod);
        handles.params.packetDepthSamp = sCoreParams.write.broadcastSamp; % / sCoreParams.core.stepPeriod;
        handles.params.numTrialsPerPlot = sCoreParams.viz.numTrialsPerPlot; % default 10 trials (10 points) per plot
       
        %Constants to define inputs from UDP:
        handles.plotInfo.continuous.NSP_TIME = 1; %first column is previous NSP 
        handles.plotInfo.continuous.STIM_HAPPENNING = 2;
        handles.plotInfo.continuous.SHAM_DETECTED = 3;  %5
        handles.plotInfo.continuous.DECIDED_STIMULATION = 4;
        handles.plotInfo.continuous.BASELINETRIGGER = 5; %Baseline Trigger 
        handles.plotInfo.continuous.DETSTIMTRIGGER = 6; %Detection/Stim Triggers
        handles.plotInfo.continuous.STIM_CHANNEL = [7 8]; % two contacts create a stim channel
        handles.plotInfo.continuous.TRIAL_NUMBER = 9;
        handles.plotInfo.continuous.FIRST_EEG = 10;
     
        handles.plotInfo.trialbytrial.IS_TRIALBYTRIAL = 1; %first column is previous NSP         
        handles.plotInfo.trialbytrial.NSP_TIME = 2; %first column is previous NSP         
        handles.plotInfo.trialbytrial.STATE_VALUE = 3;  % previous EVENT_DETECTED corresponds now to STATE_VALUE which is the MEAN state estimate
        handles.plotInfo.trialbytrial.STATE_BOUNDS = [4 5]; % State bounds are 5-95 percentile of state estimate
        handles.plotInfo.trialbytrial.TRIAL_NUMBER = 6;
        handles.plotInfo.trialbytrial.NUMBER_STIM = 7;
        handles.plotInfo.trialbytrial.STIM_CHANNEL = [8 9]; % two contacts create a stim channel
        handles.plotInfo.trialbytrial.BEHAVIORALDATA = 10;
        handles.plotInfo.trialbytrial.THRESHOLDS = [11 12];
        handles.plotInfo.trialbytrial.FIRST_FEATURE = 13; % thresholds now come BEFORE features

        %Initialize also controls
        %Contacts lists -> change to channel names for Simulation ONLY!
        if strcmpi(handles.mode,'Simulation') && strcmpi(handles.simulation.typeSimulation, 'REAL')
            strChannelVals = sCoreParams.decoders.txDetector.channelNames;
            strChannelVals{length(strChannelVals)+1} = 'Trig1'; % RIZ: HARDCODED!! Make Generic!!!
            strChannelVals{length(strChannelVals)+1} = 'Trig2';

        else % for closed loop - keep numbers
            strChannelVals = cell(1, sCoreParams.core.maxChannelsAllNSPs);
            for iCh =1:sCoreParams.core.maxChannelsAllNSPs
                strCh = num2str(iCh);
                strChannelVals{iCh} = strCh;
            end
        end
        % Keep Names and Numbers on handle variables
        channelNumbers = 1:sCoreParams.core.maxChannelsAllNSPs;
        handles.channelInfo.contact1.Names = strChannelVals;
        handles.channelInfo.contact2.Names = strChannelVals;
        handles.channelInfo.contact1.Numbers = channelNumbers;
        handles.channelInfo.contact2.Numbers = channelNumbers;
        
        nChansPerNSP = sCoreParams.core.maxChannelsAllNSPs/sCoreParams.core.NumberNSPs; 
        for indNSP=1:sCoreParams.core.NumberNSPs
            indChThisNSP = (indNSP-1)*nChansPerNSP+1: indNSP *nChansPerNSP;
            strNSP = num2str(indNSP);
            for iCh =1:nChansPerNSP
                handles.channelInfo.contact1.NSP_Names{indChThisNSP(iCh)} = strcat(strNSP,':',strChannelVals{indChThisNSP(iCh)});
                handles.channelInfo.contact2.NSP_Names{indChThisNSP(iCh)} = strcat(strNSP,':',strChannelVals{indChThisNSP(iCh)});
                handles.channelInfo.contact1.NSP_Numbers{indChThisNSP(iCh)} = [strNSP,':',num2str(iCh)];
                handles.channelInfo.contact2.NSP_Numbers{indChThisNSP(iCh)} = [strNSP,':',num2str(iCh)];
            end
        end
        
        set(handles.lstContact1,'String',handles.channelInfo.contact1.Names);
        set(handles.lstContact2,'String',handles.channelInfo.contact2.Names);
        
        %before and after stim time txtboxes
        set(handles.txtBeforeStimSec,'String',num2str(sCoreParams.viz.preTriggerSec));
        set(handles.txtAfterStimSec,'String',num2str(sCoreParams.viz.postTriggerSec));

        if (sCoreParams.Features.Baseline.weightPreviousThreshold >= 1) % if 1 it means  FIX Threshold!
            set(handles.chkFixThreshold,'Value', get(handles.chkFixThreshold,'Max')); %Check if =1 -- RIZ: Not sure if here is the best place...
        end
        set(handles.txtThresholdAbove,'String',num2str(sCoreParams.Features.Baseline.thresholdAboveValue)); 
        set(handles.txtThresholdBelow,'String',num2str(sCoreParams.Features.Baseline.thresholdBelowValue));

  %      set(handles.txtPrevThWeight,'String', num2str(sCoreParams.Features.Baseline.weightPreviousThreshold)); 
        set(handles.popDetectIfAnyAll,'Value',sCoreParams.decoders.txDetector.anyAll +1); % txDetector.anyAll =0 if ANY / =1 if ALL - in GUI corresponding value is 1/2

        %Others
        handles.average.beforeStimSamples = round(str2double(get(handles.txtBeforeStimSec,'String')) / sCoreParams.core.stepPeriod);
        handles.average.afterStimSamples = round(str2double(get(handles.txtAfterStimSec,'String')) / sCoreParams.core.stepPeriod);
 %       handles.blockRunning = false;
        handles.stimInfo.nStims = 0;
        handles.stimInfo.nShamStims = 0;
        handles.stimInfo.nEventDetectedStims = 0;
        handles.stimElectrodes = [0 0];
       % handles.dataAllTrials = struct([]);
        
        % Update handles structure
        handles = orderfields(handles);
        guidata(hObject, handles);
    end

    function updateGUIObjectsFromCurrent(hObject, handles)
        % Update GUI objects to current Values - These Parameters  can be changed in real time
        %global tg;
        global sCoreParams;
        %sCoreParams =  handles.sCoreParams;
        tunableParams = NameTunableParams;
        for tuneInd = 1:length(tunableParams)
            % if strcmpi(handles.mode,'Simulation') % RIZ: changed to ONLY update from sCoreParams instead of from last values on target PC. This way config files are preoperly considered and not changed based on previous experiments.
            % Get parameter name
            stNameParam = strrep(tunableParams{tuneInd},'_','.');
            startVal = eval(stNameParam);
            %else %it is REAL TIME  CLOSE-LOOP (human or NHP!)
            %    startVal = GetRealTimeValue(tg, tunableParams{tuneInd});
            %end
            % modify GUI object
            hEditObj = findobj('UserData',tunableParams{tuneInd},'-and','Style','edit');
            if ~isempty(hEditObj) % it is a text, just change the string 
                disp([tunableParams{tuneInd}, ' - ', num2str(startVal)]);
                set(hEditObj,'String',num2str(startVal));
                callbackEditObj = get(hEditObj,'Callback');
                callbackEditObj(hEditObj,[]);
            else % Assume that if it is not text it is a list
                hEditObj = findobj('UserData',tunableParams{tuneInd},'-and','Style','list');
                if ~isempty(hEditObj)
                    disp([tunableParams{tuneInd}, ' - ', num2str(startVal)]);
                    nStrInList= length(get(hEditObj,'String'));
                    set(hEditObj,'Value',startVal(1:min(nStrInList,length(startVal))));
                    callbackEditObj = get(hEditObj,'Callback');
                    callbackEditObj(hEditObj,[]);
                end
            end
            assignin('base',tunableParams{tuneInd},startVal);
        end
    end
    
    function updateTargetParams(hObject, handles)
    % Update GUI objects to current Values - These Parameters  can be changed in real time
        global tg;
        global sCoreParams;
        
        sCoreParams = InitCoreParams_Dependent(sCoreParams);
        tunableParams = NameTunableParams;
        FlattenAndTune(sCoreParams, 'sCoreParams',tunableParams);
        assignin('base','sCoreParams',sCoreParams);
        if ~isempty(tg)
            for tuneInd = 1:length(tunableParams)
                stNameParam = strrep(tunableParams{tuneInd},'_','.');
                paramValue = eval(stNameParam);
                %it is ONLY for REAL TIME  CLOSE-LOOP
                try
                    tg = SetRealTimeOnlyNewValue(tg, tunableParams{tuneInd}, paramValue);
                    disp(['Updated: ',tunableParams{tuneInd}, ' - ', num2str(paramValue(:)')]);
                catch
                    disp('Error Sending Parameters to Real-Time Target Decider!')
                end
            end
        else
            %assumes simulation
            try
                set_param(handles.modelName,'SimulationCommand','update');
            catch me
                disp('Error Sending Parameters in Simulation! Stop and Start again')
            end

            %Display new values
            for tuneInd = 1:length(tunableParams)
                stNameParam = strrep(tunableParams{tuneInd},'_','.');
                paramValue = eval(stNameParam);
                disp(['Updated: ',tunableParams{tuneInd}, ' - ', num2str(paramValue(:)')]);
            end
        end
    end
    
    function initializePlots(hObject, handles)
        %time applies to all plots
        global dataStreamHistory;
        global dataTrialByTrialHistory;
        global sCoreParams;
        dataStreamHistory = zeros( handles.params.streamDepthSamp,  sCoreParams.write.maxContinuousSignalsPerStep); % dataStreamHistory is the data coming from UDP - here we only specify the size
        dataTrialByTrialHistory = zeros( handles.params.numTrialsPerPlot,  sCoreParams.write.maxTrialByTrialDataPerStep); % dataStreamHistory is the data coming from UDP - here we only specify the size

        clear handles.featureTraces; clear handles.thresholdTraces; clear handles.rawEEGTraces; clear handles.triggerTrace; clear triggerAveragedTraces;

        %number of EEG channels of data sent with UDP is either the number of analized channels or the subset seleted for visualization
        nChannels = sCoreParams.viz.nChannels; %sCoreParams.decoders.txDetector.nFilteredChannels; %sCoreParams.viz.nChannels;
        nFeatures = sCoreParams.viz.nFeatures; %sCoreParams.decoders.txDetector.nFeaturesUsedInDetection; %
        %nThresholds = 2;
        handles.plotInfo.trialbytrial.featurePositions = handles.plotInfo.trialbytrial.FIRST_FEATURE:handles.plotInfo.trialbytrial.FIRST_FEATURE+nFeatures-1;
    %   handles.plotInfo.filteredDataPositions = handles.plotInfo.thresholdPositions(end)+1:handles.plotInfo.thresholdPositions(end)+nChannels;
  %     handles.plotInfo.EEGDataPositions = handles.plotInfo.thresholdPositions(end)+1:handles.plotInfo.thresholdPositions(end)+nChannels;
        handles.plotInfo.continuous.EEGDataPositions = handles.plotInfo.continuous.FIRST_EEG:handles.plotInfo.continuous.FIRST_EEG+nChannels-1;

        tContinousAx = linspace(0,sCoreParams.viz.streamDepthSec, handles.params.streamDepthSamp);
        tTrialByTrialAx = linspace(1,sCoreParams.viz.numTrialsPerPlot, sCoreParams.viz.numTrialsPerPlot);

        %Plot 1: Detections & STIMULATION - is Trial by Trial
        cla(handles.axDetections);
        hold(handles.axDetections, 'on');
        set(handles.axDetections, 'XTick', tContinousAx);
        title(handles.axDetections, '\bf STIMULATION & \rm Detections','Color','white');
       % handles.eventDetectedTrace = plot(handles.axDetections,tAx,dataStreamHistory(:,handles.plotInfo.EVENT_DETECTED),'green','LineWidth',1);
        handles.eventStimulationTrace = plot(handles.axDetections,tContinousAx,dataStreamHistory(:,handles.plotInfo.continuous.DECIDED_STIMULATION),'blue','LineWidth',1);
        handles.shamDetectedTrace = plot(handles.axDetections,tContinousAx,dataStreamHistory(:,handles.plotInfo.continuous.SHAM_DETECTED),'cyan','LineWidth',1);
        handles.realStimTrace = plot(handles.axDetections,tContinousAx,dataStreamHistory(:,handles.plotInfo.continuous.STIM_HAPPENNING),'red','LineWidth',3);
       
        
        %Plot 2: State and Threshold (Threshold corresponds to state now and it is only 1 line)  - is Trial by Trial
        cla(handles.axState);
        hold(handles.axState, 'on');
        set(handles.axState, 'XTick', tTrialByTrialAx);                
        title(handles.axState, 'STATE and Threshold','Color','white', 'FontWeight','normal');        
        
        handles.stateValueTrace = plot(handles.axState, tTrialByTrialAx, dataTrialByTrialHistory(:,handles.plotInfo.trialbytrial.STATE_VALUE),'green','LineWidth',2,'LineStyle','-','Marker','o','MarkerFaceColor','green','MarkerSize',10); % EVENT_DETECTED corresponds to STATE!
        handles.stateBoundsTrace = plot(handles.axState, tTrialByTrialAx, dataTrialByTrialHistory(:,handles.plotInfo.trialbytrial.STATE_BOUNDS),'green','LineWidth',1,'LineStyle','--'); 
        handles.thresholdTraces = plot(handles.axState, tTrialByTrialAx, dataTrialByTrialHistory(:,handles.plotInfo.trialbytrial.THRESHOLDS),'magenta','LineWidth',1.5,'LineStyle',':');
        handles.behavioralDataTrace = plot(handles.axState, tTrialByTrialAx, dataTrialByTrialHistory(:,handles.plotInfo.trialbytrial.BEHAVIORALDATA),'cyan','LineWidth',1.5,'LineStyle','-','Marker','s','MarkerEdgeColor','cyan','MarkerSize',8); % EVENT_DETECTED corresponds to STATE!

        %Plot 3: Features - is Trial by Trial
        cla(handles.axFeaturesThresholds);
        hold(handles.axFeaturesThresholds, 'on');
        set(handles.axFeaturesThresholds, 'XTick', tTrialByTrialAx);
        set(handles.axFeaturesThresholds, 'XTickLabel', tTrialByTrialAx);
        handles.axFeaturesThresholds.ColorOrderIndex =1;
        title(handles.axFeaturesThresholds, 'Features','Color','white', 'FontWeight','normal');
        handles.featureTraces = plot(handles.axFeaturesThresholds,tTrialByTrialAx,dataTrialByTrialHistory(:,handles.plotInfo.trialbytrial.featurePositions),'LineWidth',1,'LineStyle','-','Marker','x','MarkerSize',10); %Features
        handles.featTracesOriginalColors = {handles.featureTraces.Color};
        %       handles.axFeaturesThresholds.ColorOrderIndex =1;
 %       handles.thresholdTraces = plot(handles.axFeaturesThresholds,tAx,dataTrialByTrialHistory(:,handles.plotInfo.thresholdPositions),'LineWidth',1.5,'LineStyle',':');
        
        %Plot 4: RAW EEG
        cla(handles.axRawEEG);
        hold(handles.axRawEEG, 'on');
        set(handles.axRawEEG, 'XTick', tContinousAx);
        handles.axRawEEG.ColorOrderIndex =1;
        title(handles.axRawEEG, 'Bipolar EEG','Color','white', 'FontWeight','normal');
        handles.rawEEGTraces = plot(handles.axRawEEG,tContinousAx,dataStreamHistory(:,handles.plotInfo.continuous.EEGDataPositions),'LineWidth',1); %Raw EEG data
        handles.baselineTriggerTrace = stem(tContinousAx,dataStreamHistory(:,handles.plotInfo.continuous.BASELINETRIGGER),'LineWidth',1,'Color','cyan','Marker','none','Parent',handles.axRawEEG); %Raw EEG data
        handles.detStimTriggerTrace = stem(tContinousAx,dataStreamHistory(:,handles.plotInfo.continuous.DETSTIMTRIGGER),'LineWidth',1,'Color','white','Marker','none','Parent',handles.axRawEEG); %Raw EEG data

        %Plot 4: Triger Averagged EEG
        tTriggerAvAx = linspace(-str2double(get(handles.txtBeforeStimSec,'String')), str2double(get(handles.txtAfterStimSec,'String')), handles.average.beforeStimSamples + handles.average.afterStimSamples);
        cla(handles.axTriggerAveraged);
        hold(handles.axTriggerAveraged, 'on');
        set(handles.axTriggerAveraged, 'XTick', tTriggerAvAx);
        handles.axTriggerAveraged.ColorOrderIndex =1;
        title(handles.axTriggerAveraged, 'Trigger Averaged EEG','Color','white', 'FontWeight','normal');
        handles.triggerAveragedTraces = plot(handles.axTriggerAveraged, tTriggerAvAx, zeros( length(tTriggerAvAx), length(handles.plotInfo.continuous.EEGDataPositions)),'LineWidth',1); %Raw EEG data
        handles.triggerAveragedStim = stem(tTriggerAvAx, zeros( length(tTriggerAvAx), 1),'Marker','none','LineWidth',2,'LineStyle','--','Color','red', 'Parent', handles.axTriggerAveraged); %Raw EEG data

        %Link axes to zoom all together on X - separate for trial by trail axes and continuous axes
        linkaxes([handles.axDetections, handles.axRawEEG], 'x');
        linkaxes([handles.axState, handles.axFeaturesThresholds], 'x');
        
        %organize handles
        handles = orderfields(handles);
        guidata(hObject, handles);
    end
    
    function initializeWithControlValues(hObject, handles)
        % Clear txt with stim/channel info
        set(handles.txtStimElectrode1,'String','');
        set(handles.txtStimElectrode2,'String','');
        set(handles.txtShamStim,'String',num2str(0));
        set(handles.txtDetectedStim,'String',num2str(0));
        set(handles.txtStateValue,'String','');
        set(handles.txtTrialNumber,'String',num2str(0));

        % Call lstVisualization callback to only show selected channels/features
        lstVizChannelIndexes_Callback(handles.lstVizChannelIndexes, [], handles);
        chkColorPerBand_Callback(handles.chkColorPerBand, [], handles);
        txtAfterStimSec_Callback(handles.txtAfterStimSec, [], handles);
        txtBeforeStimSec_Callback(handles.txtBeforeStimSec, [], handles);
        
        % Call Threshold txt and checkboxes to start with selection
        chkShowThresAbove_Callback(handles.chkShowThresAbove, [], handles);
        chkShowThBelow_Callback(handles.chkShowThBelow, [], handles);
        txtThresholdAbove_Callback(handles.txtThresholdAbove, [], handles);
        txtThresholdBelow_Callback(handles.txtThresholdBelow, [], handles);
        
        % Call Stim channel txtbox to start with correct channel numbers
        txtStimPair1Ch1_Callback(handles.txtStimPair1Ch1, [], handles);
        txtStimPair1Ch2_Callback(handles.txtStimPair1Ch2, [], handles);
        txtStimPair2Ch1_Callback(handles.txtStimPair2Ch1, [], handles);
        txtStimPair2Ch2_Callback(handles.txtStimPair2Ch2, [], handles);
        
        % Call init model textboxes to start with correct initial values
        txtX0mean_Callback(handles.txtX0mean, [], handles);
        txtX0std_Callback(handles.txtX0std, [], handles);
        
        %Call Channel seletion and Behavior Channel Callbacks to start with correct Visualization
        lstVizChannelIndexes_Callback(handles.lstVizChannelIndexes, [], handles);
        txtBehavioralChannel_Callback(handles.txtBehavioralChannel, [], handles);
        
        %organize handles
        handles = orderfields(handles);
        guidata(hObject, handles);   
    
    end

    function UpdateViz(~,~, hObject, handles)
   % disp('In UpdateViz')
        % Run for continuous packets
        [newContinousData] =GetContinuousStreamData(hObject, handles);
        if ~isempty(newContinousData)
            UpdateContinuousViz(hObject, handles, newContinousData);
            % If we are running simulation and all EEG is zero -> STOP simulation (and save data!)
            eegDATA = newContinousData(:,handles.plotInfo.continuous.EEGDataPositions);
            if strcmpi(handles.mode,'Simulation') && (all(eegDATA(:)==0)) && (any(newContinousData(:,handles.plotInfo.continuous.NSP_TIME)>eps))
                disp(['Simulation finished - EEG is all ZERO'])
                btnStop_Callback(handles.btnStop, [], handles)
                % handles = guidata(handles.btnStop); %Get the handles back after they were modified
            end
        end
        
        % Run for trial by trial packets
        [newTrialByTrialData] =GetTrialByTrialStreamData(hObject, handles);
        if ~isempty(newTrialByTrialData)
            UpdateTrialByTrialViz(hObject, handles, newTrialByTrialData);
        end
        
    end
    
    function [newContinousData] =GetContinuousStreamData(hObject, handles)
           %        disp(['A in GetStreamData']);
           global sCoreParams;
           %Get Data from UDP and Plot
           % if handles.blockRunning
           newContinousData = ReceiveUDP(handles.network.vizContinuousSocket,'latest','double'); %Get new UDP package
           if isempty(newContinousData)
               return
           end
           if numel(newContinousData) < handles.params.packetDepthSamp * sCoreParams.write.maxContinuousSignalsPerStep
               disp(['Data size to large - Reduce Number of Channels! - ',num2str(numel(newContinousData)),' > ',num2str(handles.params.packetDepthSamp * sCoreParams.write.maxContinuousSignalsPerStep)])
               return
           end
           
           newContinousData = reshape(newContinousData(1:(handles.params.packetDepthSamp * sCoreParams.write.maxContinuousSignalsPerStep)),[handles.params.packetDepthSamp, sCoreParams.write.maxContinuousSignalsPerStep]);        
    end
    
    function [newTrialByTrialData] =GetTrialByTrialStreamData(hObject, handles)
           %        disp(['A in GetStreamData']);
           global sCoreParams;
           %Get Data from UDP and Plot
           % if handles.blockRunning
           newTrialByTrialData = ReceiveUDP(handles.network.vizTrialByTrialSocket,'latest','double'); %Get new UDP package
           if isempty(newTrialByTrialData)
               return
           end
%            if numel(newTrialByTrialData) < sCoreParams.write.maxTrialByTrialDataPerStep
%                disp(['Data size to large - Reduce Number of Channels! - ',num2str(numel(newTrialByTrialData)),' > ',num2str(handles.params.packetDepthSamp * sCoreParams.write.maxTrialByTrialDataPerStep)])
%                return
%            end
%            
          % newTrialByTrialData = reshape(newTrialByTrialData(1:( sCoreParams.write.maxTrialByTrialDataPerStep)),[handles.params.packetDepthSamp, sCoreParams.write.maxTrialByTrialDataPerStep]);        
      end
    
    function UpdateContinuousViz(hObject, handles, newData)
        persistent timeStampPrev
        global stimInfo;
        persistent triggerAvData;
        global dataStreamHistory;
        persistent nSame;
        %global targetConnected;

        %Initialize persistent variables if necessary
         if isempty(timeStampPrev)
            timeStampPrev = 0;
         end
         if isempty(nSame)
            nSame = 0;
        end       
        if isempty(stimInfo)
             stimInfo.nStims=0;
             stimInfo.nShamStims=0;
             stimInfo.nEventDetectedStims=0;
             stimInfo.eachStim = cell(1,0);
         end
        if isempty(triggerAvData) || size(triggerAvData,2) ~= length(handles.plotInfo.continuous.EEGDataPositions)
            triggerAvData = zeros( handles.average.afterStimSamples+handles.average.beforeStimSamples, length(handles.plotInfo.continuous.EEGDataPositions));
        end     
        
        % Update continuous data
        dataStreamCandidate = [dataStreamHistory((handles.params.packetDepthSamp+1):end,:); newData];
        % Show NSP time
        timeStamp = dataStreamCandidate(end, handles.plotInfo.continuous.NSP_TIME);
        set(handles.txtNSPtime,'String',num2str(timeStamp));
        % Update continuous plots
        if timeStamp > timeStampPrev && ~all(isnan(dataStreamCandidate(:)))
            dataStreamHistory = dataStreamCandidate;
            disp(['A in UpdateViz - NSP=',num2str(timeStamp),'-prevNSP=',num2str(timeStampPrev)]);

            % PLOT 1. Update plots with information about all channels (event detected / STIM)
            set(handles.eventStimulationTrace,'YData',dataStreamHistory(:,handles.plotInfo.continuous.DECIDED_STIMULATION));
            set(handles.shamDetectedTrace,'YData',dataStreamHistory(:,handles.plotInfo.continuous.SHAM_DETECTED));
            set( handles.realStimTrace,'YData',dataStreamHistory(:,handles.plotInfo.continuous.STIM_HAPPENNING));
            
            % PLOT 3. Update RAW EEG plot - including trigger
            rawEEGData = dataStreamHistory(:,handles.plotInfo.continuous.EEGDataPositions);
            for iCh=1:length(handles.plotInfo.continuous.EEGDataPositions)
              %   if (ismember(iCh,handles.vizualization.channelInds))
               %     set(handles.rawEEGTraces(iCh),'YData', rawEEGData(:,handles.vizualization.channelInds(iCh)))
                    set(handles.rawEEGTraces(iCh),'YData', rawEEGData(:,iCh))
               %  end
            end
            set(handles.baselineTriggerTrace,'YData',dataStreamHistory(:,handles.plotInfo.continuous.BASELINETRIGGER) * max(max(dataStreamHistory(:,handles.plotInfo.continuous.EEGDataPositions(:)))));
            set(handles.detStimTriggerTrace,'YData',dataStreamHistory(:,handles.plotInfo.continuous.DETSTIMTRIGGER) * max(max(dataStreamHistory(:,handles.plotInfo.continuous.EEGDataPositions(:)))));
            % set(h_titleCount,'String',(sprintf('Total stims: %i %i ',totalStim,totalRandStim)));
            
            % PLOT 4. Update Trigger Averaged signal
            [triggerAvData, isNewTriggerAv, stimDataForAv] = displayTiggerAverageSignal(triggerAvData, handles);
            if (isNewTriggerAv == true)
                handles.stimInfo = stimInfo;
                for iCh=1:length(handles.plotInfo.continuous.EEGDataPositions)
                    set(handles.triggerAveragedTraces(iCh),'YData', triggerAvData(:,iCh));
                    %set(handles.txtShamStim,'String',num2str(stimInfo.nShamStims));
                    %set(handles.txtDetectedStim,'String',num2str(stimInfo.nEventDetectedStims));
                end
                set(handles.triggerAveragedStim,'YData',stimDataForAv);
            end

            % Update timeStamp
            timeStampPrev = timeStamp;
            nSame=0;
        elseif timeStampPrev> 0 && timeStamp<timeStampPrev
            % Assume we are on a new block and reset persitent values
            disp(['B in UpdateViz NEW Block - NSP=',num2str(timeStamp),'-prevNSP=',num2str(timeStampPrev)]);
            timeStampPrev = 0;%timeStamp;
            %stimInfo =[];
            triggerAvData=[];
            nSame=0;
        elseif timeStamp==timeStampPrev
            disp(['Same - PrevTimesStamp:', num2str(timeStampPrev),' - NewTimeStamp:', num2str(timeStamp)]);
            if nSame>5
           %     btnStop_Callback(handles.btnStop, [], handles); %RIZ:TEST! I DON't KNOW WHY it gets stuck here
            end
            nSame =nSame+1;
        end

        handles = orderfields(handles);
        guidata(hObject, handles);
    end

    function UpdateTrialByTrialViz(hObject, handles, newData)
        persistent nTrialPrev;
        global dataTrialByTrialHistory;
%        global dataAllTrials;
        
        %Initialize persistent variables if empty or if at the beggining of an experiment
        if isempty(nTrialPrev) || all(dataTrialByTrialHistory(:)==0),  nTrialPrev = 0;  end
        
        % Update trial by trial data
        if ~isempty(newData)
            dataTrialByTrialCandidate = newData(end,:);
            nTrial = dataTrialByTrialCandidate( handles.plotInfo.trialbytrial.TRIAL_NUMBER); % last trial info
            nStims = dataTrialByTrialCandidate( handles.plotInfo.trialbytrial.NUMBER_STIM); 
        else
            nTrial = 0;
            nStims = 0;
        end
        %disp([' in UpdateTrialByTrialViz A - Trial number=',num2str(nTrial)]);

        if nTrial > nTrialPrev && ~all(isnan(dataTrialByTrialCandidate(:)))
            dataTrialByTrialHistory = [dataTrialByTrialHistory(2:end,:); dataTrialByTrialCandidate]; % the first one is removed and replaced by new data
            disp([' in UpdateTrialByTrialViz B - Trial number=',num2str(nTrial)]);
            set(handles.txtTrialNumber,'String',num2str(nTrial));

            
            %PLOT 2. - State value / Thresholds / Behavioral Data (from Ain)  
            set(handles.stateValueTrace,'YData', dataTrialByTrialHistory(:,handles.plotInfo.trialbytrial.STATE_VALUE));
            stateValue = dataTrialByTrialHistory(end,handles.plotInfo.trialbytrial.STATE_VALUE);
            set(handles.txtStateValue,'String',num2str(stateValue));
            
            for iBound=1:length(handles.plotInfo.trialbytrial.STATE_BOUNDS)
                set(handles.stateBoundsTrace(iBound),'YData', dataTrialByTrialHistory(:,handles.plotInfo.trialbytrial.STATE_BOUNDS(iBound)));
            end
            for iTh=1:length(handles.plotInfo.trialbytrial.THRESHOLDS)
                if strcmpi('on',get(handles.thresholdTraces(iTh), 'Visible'))
                    set(handles.thresholdTraces(iTh),'YData',dataTrialByTrialHistory(:,handles.plotInfo.trialbytrial.THRESHOLDS(iTh)));
                end
            end
            set(handles.behavioralDataTrace,'YData',dataTrialByTrialHistory(:,handles.plotInfo.trialbytrial.BEHAVIORALDATA));
            
            
            %PLOT 3. Update Features
            featData10Trials = dataTrialByTrialHistory(:,handles.plotInfo.trialbytrial.featurePositions); % 10 trials all features
            for iCh=1:length(handles.plotInfo.trialbytrial.featurePositions)
            %    if (ismember(iCh,handles.vizualization.featureInds))
                    set( handles.featureTraces(iCh),'YData',featData10Trials(:,iCh)); % assign only the features selected for visualization
                 %   set( handles.featureTraces(iCh),'Color','r');
             %   else
                %    set( handles.featureTraces(iCh),'Color','none');                    
              %  end
            end

            
            %5. Update Stimulation Channels if different than before
            [isNewStimChannel, stimElectrodes] = updateStimChannel(handles);
      %      if (isNewStimChannel == true)
                handles.stimElectrodes = stimElectrodes;
                set(handles.txtStimElectrode1,'String',num2str(stimElectrodes(1)));
                set(handles.txtStimElectrode2,'String',num2str(stimElectrodes(2)));
       %     end
            set(handles.txtDetectedStim,'String',num2str(nStims));

            
            % Prepare matrix to Save
            createTrialByTrialMatrixToSave(dataTrialByTrialHistory, handles);
            %handles.dataAllTrials = dataAllTrials;
            
            %6. Update timeStamp (trial number)
            nTrialPrev = nTrial;
        elseif nTrialPrev> 0 && nTrial<nTrialPrev && nTrial>0
            % Assume we are on a new block and reset persitent values
            disp(['#trial ', num2str(nTrial),' is < than previous: ',num2str(nTrialPrev),' - NSP=',num2str(dataTrialByTrialHistory(end,handles.plotInfo.trialbytrial.NSP_TIME))])
            nTrialPrev = nTrial;
        end

        handles = orderfields(handles);
        guidata(hObject, handles);
    end

    function [triggerAvData, isNewTriggerAv, stimDataForAv] = displayTiggerAverageSignal(triggerAvData, handles)
        global dataStreamHistory;
        global stimInfo;
        persistent prevStimDataTime;
        if isempty(prevStimDataTime), prevStimDataTime=0;end 

        isNewTriggerAv = false;
        stimDataForAv = zeros(size(triggerAvData,1),1);
        stimData = dataStreamHistory(:,handles.plotInfo.continuous.STIM_HAPPENNING);
        indStim = find(stimData,1); %only keep the fist stimulation in package (there might be 2, but it is easier and faster this way)
        if ~isempty(indStim)
            stimDataTime = dataStreamHistory(indStim, handles.plotInfo.continuous.NSP_TIME);
            lData =size(dataStreamHistory,1);
            if (stimDataTime ~= prevStimDataTime) && (indStim < max(lData/3,handles.average.beforeStimSamples)) %at least in the first third of the signal
                disp(['in displayTiggerAverageSignal - indStim=',num2str(indStim),' - StimTime=',num2str(stimDataTime)]);
                newData = dataStreamHistory(max(indStim - handles.average.beforeStimSamples, 1): min(handles.average.afterStimSamples + indStim, lData), handles.plotInfo.continuous.EEGDataPositions);
                newStimData = dataStreamHistory(max(indStim - handles.average.beforeStimSamples, 1): min(handles.average.afterStimSamples + indStim, lData), handles.plotInfo.continuous.STIM_HAPPENNING);
                indTimeInAv = max(handles.average.beforeStimSamples - indStim -1, 0) +(1: min(length(newData),size(triggerAvData,1)));
                triggerAvData(indTimeInAv,:) = triggerAvData(indTimeInAv,:) + newData/2; % add newData/2 to obtain average signal
                stimDataForAv(indTimeInAv,:) = max(triggerAvData(:)) * newStimData; %Increase amplitude to max of signal for visualization
                prevStimDataTime = stimDataTime;
                isNewTriggerAv = true;
                %Create a struct with information of each stimulation
                stimInfo.eachStim{stimInfo.nStims+1}.stimDataTime = stimDataTime;
                stimInfo.eachStim{stimInfo.nStims+1}.stimElectrodes = handles.stimElectrodes;
                %Count number of stimulations
                stimShamData = dataStreamHistory(indStim, handles.plotInfo.continuous.SHAM_DETECTED);
                if stimShamData > 0.2
                    % Stimulation due to sham detection - assumes that sham detection is always real-time (no next trigger sham)
                    stimInfo.eachStim{stimInfo.nStims+1}.detectionType = 'Random';
                    stimInfo.nShamStims = stimInfo.nShamStims + 1;
                else
                    %if it is not SHAM stim - it assumes it comes from a detected event
                    stimInfo.eachStim{stimInfo.nStims+1}.detectionType = 'DetEvent';
                    stimInfo.nEventDetectedStims = stimInfo.nEventDetectedStims + 1;
                end
                stimInfo.nStims = stimInfo.nEventDetectedStims + stimInfo.nShamStims;
            end
        end
    end

    
    function createTrialByTrialMatrixToSave(dataTrialByTrialHistory, handles)
        global dataAllTrials;
        if isempty(dataAllTrials)
            dataAllTrials = struct('features',[],'thresholds',[],'stateMeanValue',[],'stateBounds',[],'nspTime',[],'nTrials',[],'numberOfStim',[]);
        end
        
        features = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.featurePositions); % this trial all features
        thresholds = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.THRESHOLDS); % this trial all thresholds
        stateMeanValue = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.STATE_VALUE); % this trial state estimate mean
        stateBounds = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.STATE_BOUNDS); % this trial state estimate bounds
        nspTime = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.NSP_TIME);     %add also the NSP time 
        numberOfStim = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.NUMBER_STIM);     %add also the NSP time 

        dataAllTrials.features = [dataAllTrials.features; features];
        dataAllTrials.thresholds = [dataAllTrials.thresholds; thresholds];
        dataAllTrials.stateMeanValue = [dataAllTrials.stateMeanValue; stateMeanValue];
        dataAllTrials.stateBounds = [dataAllTrials.stateBounds; stateBounds];
        dataAllTrials.nspTime = [dataAllTrials.nspTime; nspTime];
        dataAllTrials.nTrials = size(dataAllTrials.features,1);
        dataAllTrials.numberOfStim = [dataAllTrials.numberOfStim; numberOfStim];

    end
    
    
    function [isNewStimChannel, stimElectrodes] = updateStimChannel(handles)
        global dataTrialByTrialHistory;
        persistent prevStimChNumbers;
        if isempty(prevStimChNumbers)
            prevStimChNumbers = handles.stimElectrodes; %We are assuming consecutive stimulation channels!
        end
        isNewStimChannel = false;
        stimElectrodes = prevStimChNumbers;
        disp(['Previous Channels: ',num2str(prevStimChNumbers)]);
        
        newStimElectrodes = round(dataTrialByTrialHistory(end,handles.plotInfo.trialbytrial.STIM_CHANNEL)); % Get latest Value as NEWEST stim channels
%         indStimChNumber1 = find(chNumbersData(:,1),1); 
%         indStimChNumber2 = find(chNumbersData(:,2),1);
%        newStimElectrodes = round(chNumbersData(indStimChNumber,:));
        
        if ~isempty(newStimElectrodes) && (prevStimChNumbers(1) ~= newStimElectrodes(1) || prevStimChNumbers(2) ~= newStimElectrodes(2))
           % chNumberDataTime = dataStreamHistory(indStimChNumber, handles.plotInfo.NSP_TIME);
            stimElectrodes(1) = newStimElectrodes(1);
            stimElectrodes(2) = newStimElectrodes(2);
            sendNewChannelToStimulator(newStimElectrodes, handles);
            disp([' New STIM Channels: ',num2str(newStimElectrodes)]);
            prevStimChNumbers(1) =  newStimElectrodes(1);
            prevStimChNumbers(2) =  newStimElectrodes(2);
            isNewStimChannel = true;
        end
    end

    function sendNewChannelToStimulator(newStimElectrodes, handles)
        if strcmpi(handles.mode,'Closed-Loop')~=0 && handles.controlCerestimFromHost == true && isfield(handles,'cerestim')
            disp(['Modifying Stimulation Electrodes to ' num2str(newStimElectrodes(1)),'-',num2str(newStimElectrodes(2))])
            res = changeChannelStimulationCereStim(handles.cerestim, newStimElectrodes(1), newStimElectrodes(2));
        end
    end

    
function txtDetectionRMSLower_Callback(hObject, eventdata, handles)
% hObject    handle to txtDetectionRMSLower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtDetectionRMSLower as text
    %        str2double(get(hObject,'String')) returns contents of txtDetectionRMSLower as a double
    global sCoreParams;
    paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
    paramStr = get(hObject,'UserData');
    sCoreParams.decoders.txDetector.txRMSLower = paramValue;
    handles.paramChanged = true;
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function txtDetectionRMSLower_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtDetectionRMSLower (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
%     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%         set(hObject,'BackgroundColor','white');
%     end
% end


function txtDetectionSign_Callback(hObject, eventdata, handles)
% hObject    handle to txtDetectionSign (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtDetectionSign as text
%        str2double(get(hObject,'String')) returns contents of txtDetectionSign as a double
    global sCoreParams;
    paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
    paramStr = get(hObject,'UserData');
    sCoreParams.decoders.txDetector.txSign = paramValue;
    handles.paramChanged = true;
    guidata(hObject, handles);

end

% --- Executes during object creation, after setting all properties.
% function txtDetectionSign_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtDetectionSign (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
%     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%         set(hObject,'BackgroundColor','white');
%     end
% 
% end

function txtNDetectionsReq_Callback(hObject, eventdata, handles)
% hObject    handle to txtNDetectionsReq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtNDetectionsReq as text
%        str2double(get(hObject,'String')) returns contents of txtNDetectionsReq as a double
    global sCoreParams;
    paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
    paramStr = get(hObject,'UserData');
    sCoreParams.decoders.txDetector.nDetectionsRequested = paramValue;
    sCoreParams.decoders.txDetector.nDetectionsRequestedmSec = paramValue /sCoreParams.core.samplesPerStep;
    handles.paramChanged = true;
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function txtNDetectionsReq_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtNDetectionsReq (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
%     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%         set(hObject,'BackgroundColor','white');
%     end
% 
% end

% --- Executes on selection change in popFreq.
function popFreq_Callback(hObject, eventdata, handles)
% hObject    handle to popFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global sCoreParams;
    contents = cellstr(get(hObject,'String')); % returns popFreq contents as cell array
    freqBandName =contents{get(hObject,'Value')}; % returns selected item from popFreq
    variantConfig = handles.variant.variantConfig;
    [variantConfig, sCoreParams] = selectFrequencyBandConfig(freqBandName, variantConfig, sCoreParams);
    handles.variant.variantConfig = variantConfig;
    handles.sCoreParams = sCoreParams;
    handles.freqBandName = freqBandName;
    handles.variantChanged = true;
    disp(['Selected frequency: ', freqBandName,' corresponds to variantConfig_FREQ_LOW = ', num2str(variantConfig.FREQ_LOW)])
    if ~isfield(handles,'nFreqs') || (sCoreParams.decoders.txDetector.nFreqs ~= handles.nFreqs)
        popFeature_Callback(handles.popFeature, eventdata, handles);
    end
    handles.nFreqs = sCoreParams.decoders.txDetector.nFreqs;
    guidata(hObject, handles);

end

% --- Executes during object creation, after setting all properties.
% function popFreq_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to popFreq (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: popupmenu controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end

% --- Executes on selection change in popFeature.
function popFeature_Callback(hObject, eventdata, handles)
% hObject    handle to popFeature (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global sCoreParams;
    contents = cellstr(get(hObject,'String')); % returns popFeature contents as cell array
    featureName =contents{get(hObject,'Value')}; % returns selected item from popFeature
    variantConfig = handles.variant.variantConfig;
    %sCoreParams = handles.sCoreParams;
    %Modify Variants based on selected features
    [variantConfig, sCoreParams] = selectFeatureConfig(featureName,variantConfig, sCoreParams, handles.neuralModelParams.nEpochs);
    FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);
    handles.sCoreParams = sCoreParams;
    handles.paramChanged = true;
    disp(['Selected Feature: ', featureName,' corresponds to Feat=', num2str(variantConfig.WHICH_FEATURE), ' - BaselineFeat=',num2str(variantConfig.WHICH_FEATURE_BASELINE), ' - Detector=',num2str(variantConfig.WHICH_DETECTOR) ]);
    handles.variant.variantConfig = variantConfig;
    handles.variantChanged = true;
    handles.feature = featureName;
    guidata(hObject, handles);
    disp('Select channels/ pairs to use in detection')
    % Call also the selector for Detector to update it based on the selected feature
    popDetectorType_Callback(handles.popDetectorType, eventdata, handles);
    handles = guidata(handles.popDetectorType); %Get the handles back after they were modified
    updateDetVizChannelsList(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function popFeature_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to popFeature (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: popupmenu controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
%     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%         set(hObject,'BackgroundColor','white');
%     end
% end


% --- Executes on selection change in lstContact1.
function lstContact1_Callback(hObject, eventdata, handles)
% hObject    handle to lstContact1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
        % RZ: I am harcodeing to which variable corresponds!!!
    global sCoreParams;
    contents = cellstr(get(hObject,'String'));  %returns lstContact1 contents as cell array
    selContactsStr = handles.channelInfo.contact1.Names(get(hObject,'Value'));    %returns selected item from NAMES of contact (regardles of what is shown on list)
    for iCh=1:length(selContactsStr)
        vecContactsNum(iCh) = find(strcmp(selContactsStr{iCh}, sCoreParams.decoders.txDetector.channelNames));
    end
    %vecContactsNum = cellfun(@str2double, selContactsStr)';
    %paramStr = get(hObject,'UserData');
    prevNChanns= length(sCoreParams.decoders.txDetector.channel1);
    sCoreParams.decoders.txDetector.channel1 = vecContactsNum;
    handles.paramChanged = true;
    guidata(hObject, handles);
    if (length(sCoreParams.decoders.txDetector.channel1) == length(sCoreParams.decoders.txDetector.channel2))
        updateDetVizChannelsList(hObject, handles);
        handles.paramChanged = true;
        if (length(sCoreParams.decoders.txDetector.channel1)~=prevNChanns) % DO NOT compile if selected channels changed but number is the same
            handles.needsToReCompile = true;
        end
    end
end


% --- Executes on selection change in lstContact2.
function lstContact2_Callback(hObject, eventdata, handles)
% hObject    handle to lstContact2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global sCoreParams;
    contents = cellstr(get(hObject,'String'));  %returns lstContact2 contents as cell array
    selContactsStr = handles.channelInfo.contact2.Names(get(hObject,'Value'));     %returns selected item from NAMES of contact (regardles of what is shown on lstContact2)
    for iCh=1:length(selContactsStr)
        vecContactsNum(iCh) = find(strcmp(selContactsStr{iCh}, sCoreParams.decoders.txDetector.channelNames));
    end
    
    %    vecContactsNum = cellfun(@str2double, selContactsStr)';
    %paramStr = get(hObject,'UserData');
    prevNChanns= length(sCoreParams.decoders.txDetector.channel1);
    sCoreParams.decoders.txDetector.channel2 = vecContactsNum;
    handles.paramChanged = true;
    guidata(hObject, handles);
    if (length(sCoreParams.decoders.txDetector.channel1) == length(sCoreParams.decoders.txDetector.channel2))
        handles.paramChanged = true;
        updateDetVizChannelsList(hObject, handles);
        if (length(sCoreParams.decoders.txDetector.channel1)~=prevNChanns) % DO NOT compile if selected channels changed but number is the same
            handles.needsToReCompile = true;
        end
    end
end



% --- Executes during object creation, after setting all properties.
% function lstContact2_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to lstContact2 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: listbox controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
%     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%         set(hObject,'BackgroundColor','white');
%     end
% end


% --- Executes on selection change in lstDetChannelIndexes.
function lstDetChannelIndexes_Callback(hObject, eventdata, handles)
% hObject    handle to lstDetChannelIndexes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global sCoreParams;
    contents = cellstr(get(hObject,'String'));  %returns lstContact2 contents as cell array
    selContactsStr = contents(get(hObject,'Value'));    %returns selected item from lstContact2
    vecContactsNum = get(hObject,'Value');
%    paramStr = get(hObject,'UserData');
    sCoreParams.decoders.txDetector.detectChannelInds = vecContactsNum;
    handles.paramChanged = true;
    
    %handles.needsToReCompile = true; %RIZ 20181019 - not 100% sure
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function lstDetChannelIndexes_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to lstDetChannelIndexes (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: listbox controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end

function updateDetVizChannelsList(hObject, handles)
%Update Detectable channels list to ALL possible combinations 
% using either channels as contact1- contct2
%or pairs of channels if Feature is coherence
%This function is called when contacts are selected or when Features combo changes
% COULD BE CHANGED TO CHANNEL NAMES LIST!
    global sCoreParams;
%    sCoreParams =  handles.sCoreParams;
    
    cont1 = sCoreParams.decoders.txDetector.channel1;
    cont2 = sCoreParams.decoders.txDetector.channel2;
    if (length(cont1) ~= length(cont2))
        disp('WARNING:: Number of selected Contacts must be the same!')
    end
    nSelChannels = length(cont1);
    nAllChannels = length(sCoreParams.decoders.txDetector.channelNames);
    if (max([cont1,cont2])>nAllChannels)
        disp('WARNING:: Channel selection might not exist!')
    end
    sCoreParams.decoders.txDetector.nChannels = nSelChannels;
    strChannelVals = cell(1,nSelChannels);
    for iCh =1:nSelChannels
        if (cont1(iCh)<=nAllChannels) && (cont2(iCh)<=nAllChannels)
            strCont1 = sCoreParams.decoders.txDetector.channelNames{cont1(iCh)};
            strCont2 = sCoreParams.decoders.txDetector.channelNames{cont2(iCh)};
            strChannelVals{iCh} = [strCont1,'-',strCont2];
        else 
            disp(['WARNING:: Channel',num2str(cont1(iCh)), ' or ',num2str(cont2(iCh)),' might not exist!'])
            disp(['Changing selection to ',num2str(iCh)]) 
            strCont1 = sCoreParams.decoders.txDetector.channelNames{(iCh)};
            strChannelVals{iCh} = [strCont1,'-',strCont1];
        end
    end
    
    if strcmpi(handles.feature, 'COHERENCE') || strcmpi(handles.feature, 'CORRELATION')
        pairChannels = getPairsChannels(1:nSelChannels);
        nDetFeatures = size(pairChannels,1);
        vecStrDetChan = cell(1,nDetFeatures);
        if ~isempty(pairChannels)
            for iCh=1:nDetFeatures
                vecStrDetChan{iCh} = [strChannelVals{pairChannels(iCh,1)},'/',strChannelVals{pairChannels(iCh,2)}];
            end
        end
    else % For all other features is directly the bipolar channels
        nDetFeatures = nSelChannels;
        vecStrDetChan = strChannelVals;
    end
    
    %Update DETECTION sCoreParams (only if different features - otherwise we were loosing the patient specific config)
    if nDetFeatures ~= (sCoreParams.decoders.txDetector.nFeatures / sCoreParams.decoders.txDetector.nFreqs)
        sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nFreqs * nDetFeatures;
      %  sCoreParams.decoders.txDetector.nFeaturesUsedInDetection = sCoreParams.decoders.txDetector.nFeatures * handles.neuralModelParams.nEpochs;
        sCoreParams.decoders.txDetector.detectChannelInds = 1:sCoreParams.decoders.txDetector.nFeatures;
 %       sCoreParams.decoders.txDetector.detectChannelMask = ones(1,sCoreParams.decoders.txDetector.nFeatures);
    end
    vecIndFeatures = sCoreParams.decoders.txDetector.detectChannelInds; % before: 1:sCoreParams.decoders.txDetector.nFeaturesUsedInDetection; % ALL are selected (out of the selected in sCoreParams.decoders.txDetector.channel1 / 2)
    % create Feat_freq names - more to account for all frequencies - RIZ: TEST if order is correct! - Change names?
    if sCoreParams.decoders.txDetector.nFreqs>1
        allFreqVecStrDetChan=[];
        for iFreq=1:sCoreParams.decoders.txDetector.nFreqs
            allFreqVecStrDetChan=[allFreqVecStrDetChan;  strcat(vecStrDetChan(:), '_', num2str(iFreq))];
        end
    else
        allFreqVecStrDetChan=vecStrDetChan(:);
    end
    
    % Update Features names
    sCoreParams.decoders.txDetector.featureNames = allFreqVecStrDetChan;

    %Update DETECTION List of Channels
    set(handles.lstDetChannelIndexes, 'String', allFreqVecStrDetChan(:));
    set(handles.lstDetChannelIndexes, 'Value', vecIndFeatures);

    %Update VISUALIZATION sCoreParams 
    sCoreParams.decoders.txDetector.nFeaturesUsedInDetection = sCoreParams.decoders.txDetector.nFeatures * handles.neuralModelParams.nEpochs;
    % create Feat_freq|Epoch names ONLY for VISUALIZATION -  to account for all EPCOHS - RIZ: TEST if order is correct! - Change names?
    if handles.neuralModelParams.nEpochs>1
        allFreqAllEpochsVecStrDetChan=[];
        for iEpoch=1:handles.neuralModelParams.nEpochs
            allFreqAllEpochsVecStrDetChan=[allFreqAllEpochsVecStrDetChan;  strcat(allFreqVecStrDetChan(:), '|', num2str(iEpoch))];
        end
    else
        allFreqAllEpochsVecStrDetChan=allFreqVecStrDetChan(:);
    end
    
    %Update VISUALIZATION List of Channels (Reset to All channels and Features)
    allFreqVecStrVizChan = allFreqAllEpochsVecStrDetChan; 
    vecIndVizFeatures = 1:min(sCoreParams.network.maxMtu, sCoreParams.decoders.txDetector.nFeaturesUsedInDetection); % ALL are selected up to 1472 (maxUDP)(out of the selected in sCoreParams.decoders.txDetector.channel1 / 2)
    
    %Update VISUALIZATION List of Channels
    set(handles.lstVizChannelIndexes, 'String', allFreqVecStrVizChan(:));
    set(handles.lstVizChannelIndexes, 'Value', vecIndVizFeatures);
    handles.vizualization.channelInds = 1: nSelChannels;
    handles.vizualization.featureInds = vecIndVizFeatures;

    % Update also sCorePArams to send ALL correspondig channels and feature
    sCoreParams.viz.channelInds = 1: nSelChannels; %viz.channelInds is always with respect to channels (selects EEG signal)
    sCoreParams.viz.channelNames = strChannelVals; %repmat(strChannelVals, nVizChannels/nChannels,1)';
    sCoreParams.viz.featureInds = vecIndVizFeatures;        %viz.featureInds could be pairs or channels
    sCoreParams.viz.featureNames = allFreqAllEpochsVecStrDetChan;
    sCoreParams = InitCoreParams_Dependent(sCoreParams);
    guidata(hObject, handles);
end


% --- Executes on selection change in lstVizChannelIndexes.
function lstVizChannelIndexes_Callback(hObject, eventdata, handles)
% hObject    handle to lstVizChannelIndexes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstVizChannelIndexes contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstVizChannelIndexes
    global sCoreParams;
    contents = cellstr(get(hObject,'String'));  %returns lstContact2 contents as cell array
    selFeatStr = contents(get(hObject,'Value'));    %returns selected item from lstContact2
    vecFeatIndexes = get(hObject,'Value');
    %paramStr = get(hObject,'UserData');
    %handles.sCoreParams.viz.featureInds = vecContactsNum; % do not change the sCoreParam value - only what we visualize!
    handles.vizualization.featureInds = vecFeatIndexes;

    chanInds=[];
    for iStr=1:length(selFeatStr)
        pairNameOnly = strsplit([selFeatStr{iStr}],{'_','|'}); % First remove the freq band number and the epoch number if any
        chInPair = strsplit([pairNameOnly{1}],{'/'});
        for iCh=1:length(chInPair)
            chanInds = [chanInds, find(strcmpi(sCoreParams.viz.channelNames, chInPair{iCh}))];
        end
    end
    handles.vizualization.channelInds =  unique(chanInds);
    
    % Set to Visible=ON only those features and channels that are  selected    
    for iFeat=1:length(handles.featureTraces)
        if ismember(iFeat, vecFeatIndexes)
            set(handles.featureTraces(iFeat),'Visible','on');
        else
            set(handles.featureTraces(iFeat),'Visible','off');
        end
    end
    for iCh=1:length(handles.rawEEGTraces)% min(length(handles.rawEEGTraces),length(sCoreParams.viz.channelNames))
        if ismember(iCh, handles.vizualization.channelInds)
            set(handles.rawEEGTraces(iCh),'Visible','on');
        else
            set(handles.rawEEGTraces(iCh),'Visible','off');
        end
    end
   % sCoreParams.viz.channelInds = unique(chanInds);% do not change the sCoreParam value - only what we visualize!
   % handles.paramChanged = true;
    guidata(hObject, handles);
    % %SetRealTimeValue(tg, paramStr, paramValue); % do not change the sCoreParam value - only what we visualize!
end

% --- Executes during object creation, after setting all properties.
% function lstVizChannelIndexes_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to lstVizChannelIndexes (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: listbox controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% 
% 
% end



function txtBeforeStimSec_Callback(hObject, eventdata, handles)
% hObject    handle to txtBeforeStimSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtBeforeStimSec as text
%        str2double(get(hObject,'String')) returns contents of txtBeforeStimSec as a double
    global sCoreParams;
    handles.average.beforeStimSamples = round(str2double(get(hObject,'String')) / sCoreParams.core.stepPeriod);    
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function txtBeforeStimSec_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtBeforeStimSec (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end


% % --- Executes during object creation, after setting all properties.
% function txtNSPtime_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtNSPtime (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% end


% --- Executes on mouse press over axes background.
function axFeaturesThresholds_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axFeaturesThresholds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'YLim', [-inf, inf]);
end


% --- Executes on mouse press over axes background.
function axRawEEG_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axRawEEG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject, 'YLim', [-inf, inf]);
end


% --- Executes on mouse press over axes background.
function axTriggerAveraged_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axTriggerAveraged (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject, 'YLim', [-inf, inf]);
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    %On Closing Close ALSO connection to target and stop writer and save
    %data - if this was not done alreeady
    if strcmpi(get(handles.btnStart,'Enable'),'off') % if START button is NOT enabled is because we didn't press STOP
        disp(['Saving data first...'])
        btnStop_Callback(handles.btnStop, [], handles)
    else
        disp(['Data Saved already... '])
    end
    diary off; % close diary - command line data is saved NOW
    % Hint: delete(hObject) closes the figure
    disp(['... Exiting'])
    delete(hObject);
end



function txtAfterStimSec_Callback(hObject, eventdata, handles)
% hObject    handle to txtAfterStimSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtAfterStimSec as text
%        str2double(get(hObject,'String')) returns contents of txtAfterStimSec as a double
    global sCoreParams;

    % Check that total duration is <= 5sec (duration of dataStream) and check this object's value to stay within limits
    if (str2double(get(hObject,'String')) + str2double(get(handles.txtBeforeStimSec,'String'))) > 5
        set(hObject,'String',num2str(5-str2double(get(handles.txtBeforeStimSec,'String'))));
    end
        
    handles.average.afterStimSamples = round(str2double(get(hObject,'String')) / sCoreParams.core.stepPeriod);    
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function txtAfterStimSec_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtAfterStimSec (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end


% --- Executes on button press in chkFixThreshold.
function chkFixThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to chkFixThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% % Hint: get(hObject,'Value') returns toggle state of chkFixThreshold
%     if (get(hObject,'Value') == get(hObject,'Max'))
%         handles.sCoreParams.Features.Baseline.initialThresholdValue = str2double(get(handles.txtThresholdAbove,'String'));
%         handles.sCoreParams.Features.Baseline.weightPreviousThreshold = 1;
%         set(handles.txtPrevThWeight,'String','1');
%         handles.paramChanged = true;
%         guidata(hObject, handles);
%     else
%         handles.sCoreParams.Features.Baseline.weightPreviousThreshold = str2double(get(handles.txtPrevThWeight,'String'));
%         handles.paramChanged = true;
%         guidata(hObject, handles);
%     end
end


function txtThresholdAbove_Callback(hObject, eventdata, handles)
% hObject    handle to txtThresholdAbove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtThresholdAbove as text
%        str2double(get(hObject,'String')) returns contents of txtThresholdAbove as a double
    global sCoreParams;
    sCoreParams.Features.Baseline.thresholdAboveValue = str2double(get(hObject,'String'));
    handles.paramChanged = true;
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function txtInitialThreshold_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtThresholdAbove (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end


% --- Executes on button press in btnAllDetectedCh.
function btnAllDetectedCh_Callback(hObject, eventdata, handles)
% hObject    handle to btnAllDetectedCh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnAllDetectedCh

% Select in Visualization Channels/Pairs the same Channels/Pairs selected to Detect
    indSelChDetection = get(handles.lstDetChannelIndexes,'Value');
    set(handles.lstVizChannelIndexes,'Value',indSelChDetection);
    lstVizChannelIndexes_Callback(handles.lstVizChannelIndexes, eventdata, handles);
end



function txtPrevThWeight_Callback(hObject, eventdata, handles)
% hObject    handle to txtPrevThWeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtPrevThWeight as text
%        str2double(get(hObject,'String')) returns contents of txtPrevThWeight as a double
    global sCoreParams;
    sCoreParams.Features.Baseline.weightPreviousThreshold = str2double(get(hObject,'String'));
    handles.paramChanged = true;
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function txtPrevThWeight_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtPrevThWeight (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end


% --- Executes on selection change in popDetectIfAnyAll.
function popDetectIfAnyAll_Callback(hObject, eventdata, handles)
% hObject    handle to popDetectIfAnyAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global sCoreParams;
    contents = cellstr(get(hObject,'String'));
    selDetAnyAll = contents{get(hObject,'Value')};
    switch upper(selDetAnyAll)
        case 'ANY'
            sCoreParams.decoders.txDetector.anyAll = 0; % 0 means ANY
        case 'ALL'
            sCoreParams.decoders.txDetector.anyAll = 1; % 1 means ALL
        otherwise
            disp(['No Valid DETECTION TYPE specified (Options: ANY/ALL). Using default: ', num2str(sCoreParams.decoders.txDetector.anyAll)]);
    end
    handles.paramChanged = true;
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function popDetectIfAnyAll_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to popDetectIfAnyAll (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: popupmenu controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end


% --- Executes on selection change in popStimulationType.
function popStimulationType_Callback(hObject, eventdata, handles)
% hObject    handle to popStimulationType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popStimulationType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popStimulationType
    contents = cellstr(get(hObject,'String')); % returns popFeature contents as cell array
    stimulationType =contents{get(hObject,'Value')}; % returns selected item from popFeature
    variantConfig = handles.variant.variantConfig;
    contents = cellstr(get(handles.popDetectorType,'String')); % returns popFeature contents as cell array
    detectorType =contents{get(handles.popDetectorType,'Value')}; % returns selected item from popFeature
   
    [variantConfig] = selectWhenToStimulate(stimulationType, variantConfig, detectorType);
    disp(['Selected STIMULATION TYPE: ', stimulationType,' corresponds to variantConfig_STIMULATION_TYPE = ', num2str(variantConfig.STIMULATION_TYPE)])
    handles.variant.variantConfig = variantConfig;
    handles.stimulationType = stimulationType;
    handles.variantChanged = true;
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function popStimulationType_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to popStimulationType (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: popupmenu controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end



function txtStimulationTriggerChannel_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimulationTriggerChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global sCoreParams;
    paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
    paramStr = get(hObject,'UserData');
    sCoreParams.decoders.txDetector.stimTriggerChannel = paramValue;
    handles.paramChanged = true;
    guidata(hObject, handles);

end

% --- Executes during object creation, after setting all properties.
% function txtStimulationTriggerChannel_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtStimulationTriggerChannel (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end
% 

% --- Executes on selection change in popDetectorType.
function popDetectorType_Callback(hObject, eventdata, handles)
% hObject    handle to popDetectorType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popDetectorType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popDetectorType
    contents = cellstr(get(hObject,'String')); % returns popFeature contents as cell array
    detectorName =contents{get(hObject,'Value')}; % returns selected item from popFeature
    variantConfig = handles.variant.variantConfig;
    contents = cellstr(get(handles.popFeature,'String')); % returns popFeature contents as cell array
    featureName =contents{get(handles.popFeature,'Value')}; % returns selected item from popFeature
    
    %Modify Variants based on selected Detector type and features
    [variantConfig, controlCerestimFromHost] = selectDetectorNeuralModelConfig(detectorName, variantConfig, featureName);
    disp(['Selected Detector Type: ', detectorName,' corresponds to configDet=',num2str(variantConfig.WHICH_DETECTOR), ' - Feature=',featureName,' - ', num2str(variantConfig.WHICH_FEATURE), ' - BaselineFeat=',num2str(variantConfig.WHICH_FEATURE_BASELINE) ]);
    handles.variant.variantConfig = variantConfig;
    handles.variantChanged = true;
    handles.feature = featureName;
    handles.detectorType = detectorName;
    handles.controlCerestimFromHost = controlCerestimFromHost;
    guidata(hObject, handles);
    % Call also stimulator type select to modify stimulator output type for the different detectors
    popStimulationType_Callback(handles.popStimulationType, eventdata, handles);
    handles = guidata(handles.popStimulationType); %Get the handles back after they were modified
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function popDetectorType_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to popDetectorType (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: popupmenu controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% 
% end

function txtDetectionRMS_Callback(hObject, eventdata, handles)
% hObject    handle to txtDetectionRMS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtDetectionRMS as text
%        str2double(get(hObject,'String')) returns contents of txtDetectionRMS as a double
    global sCoreParams;
        paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
        paramStr = get(hObject,'UserData');
        sCoreParams.decoders.txDetector.txRMS = paramValue;
        handles.paramChanged = true;
        guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function txtDetectionRMS_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtDetectionRMS (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end


% --- Executes on selection change in popTriggerType.
function popTriggerType_Callback(hObject, eventdata, handles)
% hObject    handle to popTriggerType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popTriggerType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popTriggerType
    contents = cellstr(get(hObject,'String')); % returns popFreq contents as cell array
    triggerType =contents{get(hObject,'Value')}; % returns selected item from popFreq
    variantConfig = handles.variant.variantConfig;
    [variantConfig] = selectTriggerTypeConfig(triggerType, variantConfig);
    disp(['Selected frequency: ', triggerType,' corresponds to variantConfig_TRIGGER_TYPE = ', num2str(variantConfig.TRIGGER_TYPE)])
    handles.variant.variantConfig = variantConfig;
    handles.triggerType = triggerType;
    handles.variantChanged = true;
    guidata(hObject, handles);

end

% --- Executes during object creation, after setting all properties.
% function popTriggerType_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to popTriggerType (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: popupmenu controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end



function txtStimElectrode1_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimElectrode1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimElectrode1 as text
%        str2double(get(hObject,'String')) returns contents of txtStimElectrode1 as a double
end


% --- Executes during object creation, after setting all properties.
% function txtStimElectrode1_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtStimElectrode1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end


function txtStimElectrode2_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimElectrode2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimElectrode2 as text
%        str2double(get(hObject,'String')) returns contents of txtStimElectrode2 as a double
end

% --- Executes during object creation, after setting all properties.
% function txtStimElectrode2_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtStimElectrode2 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end



function txtRandomStimulation_Callback(hObject, eventdata, handles)
% hObject    handle to txtRandomStimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtRandomStimulation as text
%        str2double(get(hObject,'String')) returns contents of txtRandomStimulation as a double
    global sCoreParams;
        paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
        paramStr = get(hObject,'UserData');
        sCoreParams.decoders.chanceDetector.randStimEventsPerSec = paramValue;
        if paramValue>0 && sCoreParams.decoders.chanceDetector.useChanceDetector == 0
            sCoreParams.decoders.chanceDetector.useChanceDetector = 1; 
        end
        handles.paramChanged = true;
        guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function txtRandomStimulation_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtRandomStimulation (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end


function txtProbaNoStim_Callback(hObject, eventdata, handles)
% hObject    handle to txtProbaNoStim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtProbaNoStim as text
%        str2double(get(hObject,'String')) returns contents of txtProbaNoStim as a double
    global sCoreParams;
        paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
        paramStr = get(hObject,'UserData');
        sCoreParams.decoders.txDetector.ProbabilityOfStim = paramValue;
        handles.paramChanged = true;
        guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
% function txtProbaNoStim_CreateFcn(hObject, eventdata, ~)
% % hObject    handle to txtProbaNoStim (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end

% --- Executes on button press in btnSendParams.
function btnSendParams_Callback(hObject, eventdata, handles)
% hObject    handle to btnSendParams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    updateTargetParams(hObject, handles);
end


% --- Executes during object creation, after setting all properties.
% function txtTriggerChannel_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtTriggerChannel (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% end



function txtThresholdBelow_Callback(hObject, eventdata, handles)
% hObject    handle to txtThresholdBelow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtThresholdBelow as text
%        str2double(get(hObject,'String')) returns contents of txtThresholdBelow as a double
    global sCoreParams;

    sCoreParams.Features.Baseline.thresholdBelowValue = str2double(get(hObject,'String'));
    handles.paramChanged = true;
    guidata(hObject, handles);

end



function txtInitialThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to txtInitialThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtInitialThreshold as text
%        str2double(get(hObject,'String')) returns contents of txtInitialThreshold as a double
end



function txtBehavioralChannel_Callback(hObject, eventdata, handles)
% hObject    handle to txtBehavioralChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtBehavioralChannel as text
%        str2double(get(hObject,'String')) returns contents of txtBehavioralChannel as a double
    global sCoreParams;
    paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
    paramStr = get(hObject,'UserData');
    if paramValue>0
        sCoreParams.decoders.txDetector.behavioralChannel = paramValue;
        handles.paramChanged = true;
        if isfield(handles,'behavioralDataTrace')
            set(handles.behavioralDataTrace,'Visible','on');
        end
    else
        if isfield(handles,'behavioralDataTrace')
            set(handles.behavioralDataTrace,'Visible','off');
        end
    end
    guidata(hObject, handles);
end


% --- Executes on selection change in popStateOutput.
function popStateOutput_Callback(hObject, eventdata, handles)
% hObject    handle to popStateOutput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popStateOutput contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popStateOutput
    contents = cellstr(get(hObject,'String')); % returns popFeature contents as cell array
    stateOutput =contents{get(hObject,'Value')}; % returns selected item from popFeature
    variantConfig = handles.variant.variantConfig;
   
    [variantConfig] = selectStateEstimateOutput(stateOutput, variantConfig);
    disp(['Selected STATE OUTPUT: ', stateOutput,' corresponds to variantConfig_STATEOUTPUT = ', num2str(variantConfig.STATEOUTPUT)])
    handles.variant.variantConfig = variantConfig;
    handles.stateOutput = stateOutput;
    handles.variantChanged = true;
    guidata(hObject, handles);

end


% --- Executes on button press in chkShowThresAbove.
function chkShowThresAbove_Callback(hObject, eventdata, handles)
% hObject    handle to chkShowThresAbove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkShowThresAbove
    indThAbove =1;
    isShowTh = get(hObject,'Value');
    if isShowTh >=1 
        set(handles.thresholdTraces(indThAbove),'Visible','on');
    else
        set(handles.thresholdTraces(indThAbove),'Visible','off');
    end

end

% --- Executes on button press in chkShowThBelow.
function chkShowThBelow_Callback(hObject, eventdata, handles)
% hObject    handle to chkShowThBelow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkShowThBelow
    indThAbove =2;
    isShowTh = get(hObject,'Value');
    if isShowTh >=1 
        set(handles.thresholdTraces(indThAbove),'Visible','on');
    else
        set(handles.thresholdTraces(indThAbove),'Visible','off');
    end
end


% --- Executes on button press in btnVisualizeFromDValid.
function btnVisualizeFromDValid_Callback(hObject, eventdata, handles)
% hObject    handle to btnVisualizeFromDValid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% RZ: IN THE FUTURE THIS HAS TO BE GENERALIZED FOR DIFFFERENT MODELS
% Select in Visualization Channels/Pairs the same Channels/Pairs selected to Detect
if isfield(handles.neuralModelParams,'dValid')
    indSelFeat = find(handles.neuralModelParams.dValid(:,1));
    set(handles.lstVizChannelIndexes,'Value',indSelFeat);
    lstVizChannelIndexes_Callback(handles.lstVizChannelIndexes, eventdata, handles);
end
end


% --- Executes on button press in chkColorPerBand.
function chkColorPerBand_Callback(hObject, eventdata, handles)
% hObject    handle to chkColorPerBand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkColorPerBand
    global sCoreParams;

    isShowColorPerBand = get(hObject,'Value');
    nFeat = length(handles.featureTraces);
    nEpochs = handles.neuralModelParams.nEpochs;  
    nFreqBands = sCoreParams.decoders.txDetector.nFreqs;
    if isShowColorPerBand >=1 && nFreqBands>1
        colorVal = repmat([1/nFreqBands:1/nFreqBands:1; 1:-1/nFreqBands:1/nFreqBands; ones(1, nFreqBands)]',nEpochs,1);
        for iFeat=1:nFeat
            indFreq = ceil(iFeat/(nFeat/nEpochs/nFreqBands));
            set(handles.featureTraces(iFeat),'Color',colorVal(indFreq,:));
        end
    else
        for iFeat=1:nFeat
            set(handles.featureTraces(iFeat),'Color',handles.featTracesOriginalColors{iFeat});
        end
    end
end


function txtStimPair1Ch1_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimPair1Ch1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimPair1Ch1 as text
%        str2double(get(hObject,'String')) returns contents of txtStimPair1Ch1 as a double
    global sCoreParams;

    chNumber = str2double(get(hObject,'String'));
    if ~isempty(chNumber) && ~isnan(chNumber)
        sCoreParams.stimulator.stimChannelUpper(1,1) = chNumber;
        handles.paramChanged = true;
        guidata(hObject, handles);
    end

end

function txtStimPair1Ch2_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimPair1Ch2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimPair1Ch2 as text
%        str2double(get(hObject,'String')) returns contents of txtStimPair1Ch2 as a double
    global sCoreParams;

    chNumber = str2double(get(hObject,'String'));
    if ~isempty(chNumber) && ~isnan(chNumber)
        sCoreParams.stimulator.stimChannelUpper(1,2) = chNumber;
        handles.paramChanged = true;
        guidata(hObject, handles);
    end
end


function txtStimPair2Ch1_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimPair2Ch1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimPair2Ch1 as text
%        str2double(get(hObject,'String')) returns contents of txtStimPair2Ch1 as a double
    global sCoreParams;

    chNumber = str2double(get(hObject,'String'));
    if ~isempty(chNumber) && ~isnan(chNumber)
        sCoreParams.stimulator.stimChannelLower(1,1) = chNumber;
        handles.paramChanged = true;
        guidata(hObject, handles);
    end
end

function txtStimPair2Ch2_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimPair2Ch2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimPair2Ch2 as text
%        str2double(get(hObject,'String')) returns contents of txtStimPair2Ch2 as a double
    global sCoreParams;

    chNumber = str2double(get(hObject,'String'));
    if ~isempty(chNumber) && ~isnan(chNumber)
        sCoreParams.stimulator.stimChannelLower(1,2) = chNumber;
        handles.paramChanged = true;
        guidata(hObject, handles);
    end
end


% --- Executes on button press in btnCompile.
function btnCompile_Callback(hObject, eventdata, handles)
% hObject    handle to btnCompile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
       %Assign changed variables to workspace
        hObjectGUI = hObject.Parent;
        handles.needsToReCompile = true; % force it to compile
        handles = guidata(hObjectGUI);
        configureModelParams(hObjectGUI, handles);

end



function txtX0mean_Callback(hObject, eventdata, handles)
% hObject    handle to txtX0mean (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtX0mean as text
%        str2double(get(hObject,'String')) returns contents of txtX0mean as a double

    global sCoreParams;
    % RIZ: WE MAY NEED SOMETHING SPECIFIC FOR CLEAR
    X0mean = str2double(get(hObject,'String'));
    X0std = str2double(get(handles.txtX0std,'String'));
    if ~isempty(X0mean) && ~isnan(X0mean) && ~isempty(X0std) && ~isnan(X0std)
        if isfield( handles.neuralModelParams,'initialXPre')
            handles.neuralModelParams.initialXPre = pdf('normal',handles.neuralModelParams.Xs,X0mean,10.*sqrt(X0std));
        end
        sCoreParams.neuralModelParams = handles.neuralModelParams;
        handles.paramChanged = true;
        guidata(hObject, handles);
    end
        
end


function txtX0std_Callback(hObject, eventdata, handles)
% hObject    handle to txtX0std (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtX0std as text
%        str2double(get(hObject,'String')) returns contents of txtX0std as a double

    global sCoreParams;

    X0mean = str2double(get(handles.txtX0mean,'String'));
    X0std = str2double(get(hObject,'String'));
    if ~isempty(X0mean) && ~isnan(X0mean) && ~isempty(X0std) && ~isnan(X0std)
        if isfield( handles.neuralModelParams,'initialXPre')
            handles.neuralModelParams.initialXPre = pdf('normal',handles.neuralModelParams.Xs,X0mean,10.*sqrt(X0std));
        end
        sCoreParams.neuralModelParams = handles.neuralModelParams;
        handles.paramChanged = true;
        guidata(hObject, handles);
    end
end


% --- Executes on button press in btnDetFromDValid.
function btnDetFromDValid_Callback(hObject, eventdata, handles)
% hObject    handle to btnDetFromDValid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% RIZ: WHAT WOULD BE THE EQUIVALENT IN CLEAR? - IN THE FUTURE THIS SHOULD BE A GENERAL "MODEL" CHANNELS SELECTED FIELD
% Select in Detection Channels/Pairs the same Channels/Pairs that are 1 in dValid
    if isfield( handles.neuralModelParams,'dValid')
        indSelFeatAllEpochs = find(handles.neuralModelParams.dValid(:,1));
        indSelFeat = unique(mod(indSelFeatAllEpochs-1,handles.neuralModelParams.nFeaturesPerEpoch)+1); % keep features with features in any epoch (feat are computed continuously)
        set(handles.lstDetChannelIndexes,'Value',indSelFeat);
        lstDetChannelIndexes_Callback(handles.lstDetChannelIndexes, eventdata, handles);
    end
end





% --- Executes on selection change in popChannelDisplay.
function popChannelDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to popChannelDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popChannelDisplay contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popChannelDisplay

% How to show the list of channels
    contents = cellstr(get(hObject,'String'));
    selStrValue = contents{get(hObject,'Value')};
    switch upper(selStrValue)
        case 'NAMES'
            set(handles.lstContact1,'String',handles.channelInfo.contact1.Names);
            set(handles.lstContact2,'String',handles.channelInfo.contact2.Names);
            
        case 'NUMBERS'
            set(handles.lstContact1,'String',handles.channelInfo.contact1.Numbers);
            set(handles.lstContact2,'String',handles.channelInfo.contact2.Numbers);
            
        case 'NSP:NUMBERS'
            set(handles.lstContact1,'String',handles.channelInfo.contact1.NSP_Numbers);
            set(handles.lstContact2,'String',handles.channelInfo.contact2.NSP_Numbers);
            
        case 'NSP:NAMES'
            set(handles.lstContact1,'String',handles.channelInfo.contact1.NSP_Names);
            set(handles.lstContact2,'String',handles.channelInfo.contact2.NSP_Names);
            
        otherwise % Default is Names
            set(handles.lstContact1,'String',handles.channelInfo.contact1.Names);
            set(handles.lstContact2,'String',handles.channelInfo.contact2.Names);
    end
end


