clear all
close all

%% Extract behavior from xls files
patient='MG112';

dataFiles = {
    'csv/mg106_msit_no-stim_64_01_2017_09_06_11_46_15.csv',...% B1: no stim block1
    'csv/mg106_msit_no-stim_32_01_2017_09_06_11_54_31.csv',... % B2: RVF 7-8, threshold -0.08
    'csv/mg106_msit_no-stim_32_02_2017_09_06_12_04_51.csv',... % B3: RVF 7-8, theshold  -0.06 -> -0.04
    'csv/mg106_msit_no-stim_32_03_2017_09_06_12_14_06.csv',... % B4: LVF 7-8, theshold  -0.04
 }

smallBlockNum = 1:length(dataFiles);
smallBlockStim = {'None','RDorsal','RDorsal','LDorsal'};
smallBlockSubject = {patient,patient,patient,patient};

responseTimes = [];
StimAny = [];
interference = [];
blockNum = [];
blockStim = {};
trialStim = {};
trialNum = [];
responseCorrect = [];
switchType = {};
subject = {};

for f=1:length(dataFiles)

    fData = csvread(dataFiles{f},1);
    
    fHandle = fopen(dataFiles{f});
    fHeader = textscan(fHandle,'%[^0123456789,]','Delimiter',',');
    fHeader = fHeader{1};
    fclose(fHandle);
    
     nTrials = size(fData,1);
     lastIdx = length(responseTimes);
     putIdx = lastIdx + (1:nTrials);
     
     responseTimes(putIdx,1) = fData(:,find(strcmp(fHeader,'ResponseTime')));
     interference(putIdx,1) = fData(:,find(strcmp(fHeader,'Condition'))) == 2;
     StimAny(putIdx,1) = ~strcmp(smallBlockStim{f},'None');
     blockNum(putIdx,1) = smallBlockNum(f);
     blockStim(putIdx,1) = deal(smallBlockStim(f));
     
     for i=1:nTrials
         if (fData(i,find(strcmp(fHeader,'FixStimLength'))) > 0) | ...
              (fData(i,find(strcmp(fHeader,'NumStimLength'))) > 0) | ...
              (fData(i,find(strcmp(fHeader,'RespStimLength'))) > 0)
             trialStim{putIdx(i),1} = smallBlockStim{f};
         else
             trialStim{putIdx(i),1} = 'None';
         end
     end
     
     switchType(putIdx(fData(:,find(strcmp(fHeader,'Conflict'))) == 0),1) = deal({'CC'});
     switchType(putIdx(fData(:,find(strcmp(fHeader,'Conflict'))) == 1),1) = deal({'IC'});
     switchType(putIdx(fData(:,find(strcmp(fHeader,'Conflict'))) == 2),1) = deal({'CI'});
     switchType(putIdx(fData(:,find(strcmp(fHeader,'Conflict'))) == 3),1) = deal({'II'});
     
     trialNum(putIdx,1) = 1:nTrials;
     responseCorrect(putIdx,1) = fData(:,find(strcmp(fHeader,'ResponseAccuracy')));
     subject(putIdx,1) = deal(smallBlockSubject(f));
end
responseTimes(find(responseTimes==0))=nan;
save([patient,'_Behavior_csv.mat'],'responseTimes','interference','blockNum','blockStim','trialStim','trialNum','responseCorrect','switchType');

%% Use behavior model to estimate cognitive state
clear all
patient='MG112';
load([patient,'_Behavior_csv.mat'])

RT=responseTimes;
N = length(RT);
Yn = log(RT);
Yb = ones(N,1);
In = zeros(N,2);
In(:,1)=1;
In(find(interference==2),2)=1;
% Input, Ib equal to In
Ib = In;
% Uk, which is zero
Uk = zeros(N,1);
% Valid, which is valid for observed point
Valid = zeros(N,1);
Valid(find(isfinite(RT)))=1;

Param = compass_create_state_space(2,1,2,2,eye(2,2),[1 2],[0 0],[1 2],[0 0]); % No binary state
% set learning parameters
Iter  = 800;
Param = compass_set_learning_param(Param,Iter,0,1,1,0,1,1,1,2,1); % No binary state 

[XSmt,SSmt,Param,XPos,SPos,ML,YP,~]=compass_em([1 0],Uk,In,Ib,Yn,Yb,Param,Valid); % No binary state

% Check model fit
figure
ml=[];
for i=1:Iter
    ml(i)=ML{i}.Total;
end
plot(ml,'LineWidth',2);
ylabel('ML')
xlabel('Iter');

figure
K  = length(XPos);
xm = zeros(K,1);
xb = zeros(K,1);
for i=1:K
    temp=XPos{i};xm(i)=temp(1);
    temp=SPos{i};xb(i)=temp(1,1);
end
compass_plot_bound(1,(1:K),xm,(xm-2*sqrt(xb))',(xm+2*sqrt(xb))');hold on;plot(Yn)
ylabel('x_k(1)');
xlabel('Trial');

close all
save([patient,'_state.mat'],'Param','SPos','XPos','SSmt','XSmt','RT');

%% Create files to run encoder
clear all

patient='MG112';

NeuralFeatureFile1='neural data\DeciderTrialByTrialData_MSIT_MG112_NSP1_TriggersFromNEV_180414_2017.mat';
NeuralFeatureFile2='neural data\DeciderTrialByTrialData_MSIT_MG112_NSP2_TriggersFromNEV_180415_0905.mat';

load(NeuralFeatureFile1);
Y1=dataTrialByTrial.features;

channel_name1=[];
for ch=1:length(SessionDataConfig.bipolarChannelNames)
    channel_name1{ch,1}=[SessionDataConfig.bipolarChannelNames{ch,1},' ',SessionDataConfig.bipolarChannelNames{ch,2}];
end

load(NeuralFeatureFile2);
Y2=dataTrialByTrial.features;

channel_name2=[];
for ch=1:length(SessionDataConfig.bipolarChannelNames)
    channel_name2{ch,1}=[SessionDataConfig.bipolarChannelNames{ch,1},' ',SessionDataConfig.bipolarChannelNames{ch,2}];
end

channel_name=[channel_name1;channel_name2];

L1=length(channel_name1);
L2=length(channel_name2);

Y=[];

YL=[];

for ff=1:3
    Y=[Y,Y1(:,L1*(ff-1)+1:L1*ff),Y2(:,L2*(ff-1)+1:L2*ff)];
    for ch=1:length(channel_name)
        YL=[YL;[ff,ch,channel_name(ch)]];
    end
end

load([patient,'_state.mat'])
save([patient,'_features_encoder.mat'],'Param','SPos','XPos','SSmt','XSmt','Y','YL','channel_name');

%% Run Main_encoder_model_fit.m