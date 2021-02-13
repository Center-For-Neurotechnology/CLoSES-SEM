% now we are part of github for real!
clear all

file_name = 'MG112_features_encoder.mat';
ModelSetting.pName             = 'MG112_test';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Training Phase (Ishita or Angelique might help for this step)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x_min = -2;
x_max =  2;
sample= 2000;
Xs    = linspace(x_min,x_max,sample);

%%--------------------------------------------------------------
% call this on learning data
% define file name and state variable that being estimated
ModelSetting.pVal             = 0.01;       % 0.05, 0.01, 0.001
ModelSetting.SelMode          = 6;          % 6 or 7
ModelSetting.NoStateSamples   = 1000;
ModelSetting.which_state      = 1;
ModelSetting.Xs = Xs;  

% Load file containing neural features and state values
load(file_name);
temp = cell2mat(XPos');
XM   = temp(ModelSetting.which_state,:);
no_feature = size(Y,2);
%TrainInd=[128:254];
TrainInd=1:length(XM);
TestInd=setdiff(1:length(XM),TrainInd);

ModelName1=ay_neural_encoder_training(file_name,ModelSetting,TrainInd);
ModelName2=ay_map_to_sim(ModelName1);
%%----------------------------------------------------
% Real-Time Procdure
% load the model
load(ModelName2);
ind=find(dValid(:,1)==1);  % If there are too many features that were passed by f-test , can reduce pvalue and run again

%%---------------------------------------------
% build state-transition distribution
TransP = ones(length(Xs),length(Xs));
for i=1:length(Xs)
    TransP(i,:)=pdf('normal',Xs(i),sParam.a*Xs,sqrt(sParam.sv));
end

%%-----------------------------------------------

figure(1)
plot(dValid(:,4),'LineWidth',2);
hold on
ind =find(dValid(:,1));
plot(ind,dValid(ind,4),'o','LineWidth',2);
box off
title('R^2 and Valid Features')
xlabel('Feature Index')
ylabel('R^2')

figure(2)
[~,m_ind] = max(dValid(:,4));
[~,c_ind] = min(dValid(:,4));
tY = mean(eParam{m_ind}.Y);
fY = Y(TrainInd,m_ind);
subplot(3,1,1)
plot(fY,'LineWidth',2);
hold on
plot(tY,'LineWidth',2);
box off
title(['model ' eParam{m_ind}.RefModel  ', slope(x)=' num2str(eParam{m_ind}.W(2))])
legend('Feature','Prediction')
axis tight
%ylabel(channel_name(Yl(m_ind,2)))
subplot(3,1,2)
plot(TrainInd,XM(TrainInd),'LineWidth',2);
xlabel('Training Index')
ylabel('X');box off
axis tight
subplot(3,1,3)
plot(XM(TrainInd),Y(TrainInd,m_ind),'*');hold on;plot(XM(TrainInd),Y(TrainInd,c_ind),'o');
xlabel('X')
%ylabel(channel_name(Yl(m_ind,2))); 
ylabel('Z')
box off
axis tight
title('Scatter Plot')

%%------------------------------------
%This is the 2nd step for shrinking neural features

TProb = ay_individual_decoder(data_type,eParam,Xs,dValid(:,1),Y);
XProb = TProb;

% Subset feature given Training Data
for f=1:length(TProb)
    if  TProb{f}.valid
        TProb{f}.prb=TProb{f}.prb(TrainInd,:);
    end
end
[rmse_ind,rmse_curve,optim_curve,winner_list] = ay_sort_decoder_sub(TProb,Xs,dValid(:,1),SampleX(:,TrainInd));
tdValid=zeros(length(dValid(:,1)),1);
[~,ind]=min(rmse_curve);
opt_train=rmse_ind{ind};

figure(3)
subplot(2,1,1)
plot(rmse_curve,'LineWidth',2);hold on
title('Model Selection Given Training Data');
axis tight
subplot(2,1,2)
plot(optim_curve(ind,:),'LineWidth',2);
hold on
plot(XM(TrainInd),'LineWidth',2);
hold off
ylabel('Y')
xlabel('TrainInd')
axis tight
disp('Optimal Feature Set Given Training Data')

%%----------------------------------------------
% Subset feature given Test Data
for f=1:length(XProb)
    if  XProb{f}.valid
        XProb{f}.prb=XProb{f}.prb(TestInd,:);
    end
end
[xrmse_ind,xrmse_curve,xoptim_curve,xwinner_list] = ay_sort_decoder_sub(XProb,Xs,dValid(:,1),SampleX(:,TestInd));
tdValid=zeros(length(dValid(:,1)),1);
[~,ind]=min(xrmse_curve);
opt_test=xrmse_ind{ind};

figure(4)
subplot(2,1,1)
plot(xrmse_curve,'LineWidth',2)
title('Model Selection Given Test Data');
axis tight
subplot(2,1,2)
plot(xoptim_curve(ind,:),'LineWidth',2);
hold on
plot(XM(TestInd),'LineWidth',2);
hold off
ylabel('Y')
xlabel('TestInd')
axis tight
disp('Optimal Feature Set Given Test Data')


%% Alternative choice for model selection
% First L features with highest r2
L=25;
[sval,sid]=sort(dValid(:,4),'descend');
opt_rsq=sid(1:L);

% Visualizing what the mean decoded state looks like with the reduced
% features v all

opt_id=opt_train; 

tdValid=zeros(length(dValid(:,1)),1);
tdValid(opt_id)=1;
%%---------------------------------------------------
% we keep previous posterior - initialize XPre
%XPre = ones(1,size(TransP,1));
XPre = pdf('normal',Xs,XPos{1}(1),10.*sqrt(SPos{1}(1,1))); 
% we might use previous point of feature
Yprv = zeros(1,no_feature);
% this is the hypothetical real-time loop
% I am keeping mean of estimate here
MEAN=[]; LOW=[]; HI=[]; lMap=[]; fMap=[];
for n=1:size(Y,1)
    % load Yk
    Yk = Y(n,:);
    % decoder model 
    % Using subset of features
    [XPos,CurEstimate,Xll] = ay_one_step_decoder(data_type,eParam,XPre,TransP,Xs,tdValid,Yk,Yprv);
    lMap = [lMap;Xll];
    fMap = [fMap;XPos];
    % next step
    XPre = XPos;
    Yprv = Yk;
    % result
    MEAN = [MEAN;CurEstimate.Mean];
    LOW  = [LOW; CurEstimate.Bound(1)];
    HI   = [HI;  CurEstimate.Bound(2)];
end

%%--------------------------------------------
% plot figure, State Mean plus Mean+/-Std Estimate
figure(5)
subplot(2,1,1)
plot(XM,'b','LineWidth',2);hold on;
plot(MEAN,'r','LineWidth',2);
plot(HI,'r--');
plot(LOW,'r--');
legend('behavior estimate','neural estimate');
title('State Estimate with features using test data');
box off

% we keep previous posterior - initialize XPre
XPre = ones(1,size(TransP,1));
% we might use previous point of feature
Yprv = zeros(1,no_feature);
% this is the hypothetical real-time loop
% I am keeping mean of estimate here
MEAN=[]; LOW=[]; HI=[]; lMap=[]; fMap=[];
for n=1:size(Y,1)
    % load Yk
    Yk = Y(n,:);
    % decoder model 
    % Using all features 
    [XPos,CurEstimate,Xll] = ay_one_step_decoder(data_type,eParam,XPre,TransP,Xs,dValid(:,1),Yk,Yprv);
    lMap = [lMap;Xll];
    fMap = [fMap;XPos];
    % next step
    XPre = XPos;
    Yprv = Yk;
    % result
    MEAN = [MEAN;CurEstimate.Mean];
    LOW  = [LOW; CurEstimate.Bound(1)];
    HI   = [HI;  CurEstimate.Bound(2)];
end

subplot(2,1,2)
plot(XM,'b','LineWidth',2);hold on;
plot(MEAN,'r','LineWidth',2);
plot(HI,'r--');
plot(LOW,'r--');
title('State Estimate with larger feature subset');
legend('neural estimate','behavior estimate');
box off


figure(6)
imagesc(1:length(XM),Xs,(lMap'));
hold on
plot(1:length(XM),XM,'w.');
title('Likelihood');
xlabel('Trial Index')
ylabel('State Estimate')
hold off

% plot figure, filter estimate plus State Mean
figure(7)
imagesc(1:length(XM),Xs,(fMap'));
hold on
plot(1:length(XM),XM,'w.');
title('Filter Estimate');
xlabel('Trial Index')
ylabel('State Estimate')
hold off
axis tight

% Metrics for decoder performance
for i=1:length(XM)
    temp=SPos{i};XS(i)=temp(1,1);
end

cc=corrcoef(XM,MEAN); % Correlation bw mean decoded states
rmse=mean((XM-MEAN).^2)/(max(XM)-min(XM)); % RMSE over range

XMh=XM+2.*sqrt(XS);
XMl=XM-2.*sqrt(XS);

Nin=[length(find((MEAN'<XMh)&(MEAN'>XMl)))];
Hdr=Nin/length(XM);

% Stimulation analysis.
Th1=quantile(XMh(TrainInd),0.1);
Th2=quantile(HI(TrainInd),0.1);

stim1=zeros(1,length(XM));
stim2=stim1;

id1=find(XMh(1:10)>Th1);
if(length(id1)>5)
    stim1(id1(1:5))=1;
else
    stim1(id1)=1;
end
id2=find(HI(1:10)>Th2);
if(length(id2)>5)
    stim2(id2(1:5))=1;
else
    stim2(id2)=1;
end

for ii=11:length(XM)
    if(XMh(ii)>Th1 && sum(stim1(ii-10:ii-1))<5)
        stim1(ii)=1;
    end
    if(HI(ii)>Th2 && sum(stim2(ii-10:ii-1))<5)
        stim2(ii)=1;
    end
end

imagesc([stim1;stim2]);
set(gca,'ytick',[1,2],'yticklabel',[{'Behavior'},{'Neural'}])

% Finding confusion matrix entries
[C,ord]=confusionmat(stim1,stim2)

%% Threshold Estimation
opt_id=ind;
Threshold=Th2;
channel_list=unique(unique(YL(opt_id,3)));

%% Final Model for decoding
Patient='MG112';
Feature_id=[];
for ch=1:length(channel_list)
    Feature_id=[Feature_id,find(strcmp(YL(:,3),channel_list{ch})==1)];
end

Feature_id=reshape(Feature_id',size(Feature_id,1)*size(Feature_id,2),1);

YL(Feature_id,:)

tdValid=zeros(length(dValid(:,1)),1);
tdValid(opt_id)=1;
dValid(:,1)=tdValid;

dValid=dValid(Feature_id,:);
eParam=eParam(Feature_id,:);
numEpochs=1;
numFeaturesPerEpoch=length(channel_list)*3;

save([Patient,'_decoder_model.mat'],'dValid','eParam','numEpochs','numFeaturesPerEpoch','data_type','sParam');

%% Test if reduced decoder model is right
Y=Y(:,Feature_id);
XPre = ones(1,size(TransP,1));
% we might use previous point of feature
Yprv = zeros(1,no_feature);
% this is the hypothetical real-time loop
% I am keeping mean of estimate here
MEAN=[]; LOW=[]; HI=[]; lMap=[]; fMap=[];
for n=1:size(Y,1)
    % load Yk
    Yk = Y(n,:);
    % decoder model 
    % Using all features 
    [XPos,CurEstimate,Xll] = ay_one_step_decoder(data_type,eParam,XPre,TransP,Xs,dValid(:,1),Yk,Yprv);
    lMap = [lMap;Xll];
    fMap = [fMap;XPos];
    % next step
    XPre = XPos;
    Yprv = Yk;
    % result
    MEAN = [MEAN;CurEstimate.Mean];
    LOW  = [LOW; CurEstimate.Bound(1)];
    HI   = [HI;  CurEstimate.Bound(2)];
end

plot(XM,'b','LineWidth',2);hold on;
plot(MEAN,'r','LineWidth',2);
plot(HI,'r--');
plot(LOW,'r--');

figure;
plot(XM,'b','LineWidth',2);hold on;
plot(MEAN,'r','LineWidth',2);
plot(HI,'r--');
plot(LOW,'r--');