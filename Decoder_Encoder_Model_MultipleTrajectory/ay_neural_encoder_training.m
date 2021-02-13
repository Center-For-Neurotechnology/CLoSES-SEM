function Name=ay_neural_encoder_training(file_name,ModelSetting,training_ind)
% 8/24 Check what I am sending out
%% This function load feature data and state-estimation result and returns encoder model paramaters
if nargin==1
    ModelSetting.pVal    = 0.01;
    ModelSetting.SelMode = 6;
    ModelSetting.NoStateSamples = 100;
    ModelSetting.which_state = 1;
    ModelSetting.training_section = 2;  
end
% encoder model: log-normal(2), gamma (1)
data_type  = 2;
% model selection p-value
sel_pVal  = ModelSetting.pVal;
% model selection mode
sel_mode  = ModelSetting.SelMode;

% data sample
Ns        = ModelSetting.NoStateSamples;
% which_state
which_state = ModelSetting.which_state;
%% load the file
load(file_name);

%% state transition model assumption (assume model si diagonal)
sParam.a   = Param.Ak(which_state,which_state);
sParam.sv  = Param.Wk(which_state,which_state);

%% generate samples
if Ns ==1
%   Xs = zeros(1,length(XSmt),size(XSmt{1},1));
%   Xs(1,:,:) = cell2mat(XSmt')';
    Xs = zeros(1,length(XPos),size(XPos{1},1));
    Xs(1,:,:) = cell2mat(XPos')';
else
    Xs = ay_state_sample(Ns,XSmt,SSmt,XPos,SPos,Param);
end
% take state of interest
% if training_section==1 % every other data
%    training_ind = 1:2:length(XPos); 
%    test_ind     = 2:2:length(XPos); 
% end
% if training_section==2 % first half
%    training_ind = 1:round(length(XPos)/2);
%    test_ind = 1+round(length(XPos)/2):length(XPos);
% end
% if training_section==3 % first half
%    training_ind = 1+round(length(XPos)/2):length(XPos);
%    test_ind = 1:round(length(XPos)/2);
% end
% if training_section==4 % specific
%    training_ind = 1:length(XPos);
%    test_ind     = [];
% end
% 8/24 Here, I try to get test data for KS test
Xo= squeeze(Xs(:,:,which_state));
% find number of features
no_feature = size(Y,2);

%% Take specific state variable from XSmt or XPos for case Ns 1
Yi  = cell(Ns,1);
Xi  = cell(Ns,1);
Aux = cell(Ns,1);
eParam = cell(no_feature,1);
dValid = zeros(no_feature,4);
for fn = 1:no_feature
    disp(['processing feature ' num2str(fn)])
    disp('-encoding')
    % To avoid circular issue, make the condition as 
    AuxInd = 1:fn-1; 
    for s  = 1:Ns
        % causal component
        if find(training_ind==1)
            Aux{s} = [ zeros(1,length(AuxInd));
                      Y(training_ind(2:end)-1,AuxInd)];     
        else
            Aux{s} = Y(training_ind-1,AuxInd);     
        end
        % observation
        Yi{s} = Y(training_ind,fn);
        % regressor
        Xi{s} = squeeze(Xs(s,training_ind,which_state)');
    end
    model_a      = ay_encoder_selector_stepwise(sel_mode,1,data_type,Xi,Aux,AuxInd,Yi,sel_pVal);
    eParam{fn}   = model_a;
    dValid(fn,2) = sum(model_a.EncModel.XPow)>1;
    dValid(fn,4) = model_a.R2;
end
dValid(:,1) = dValid(:,2);
SampleX=Xo;
c=clock;
temp=num2str(c(1));
for ii=2:length(c)
temp=[temp,'_',num2str(round(c(ii)))];
end
Name=['Model_',ModelSetting.pName,'_',temp,'.mat'];
save(Name,'eParam','sParam','dValid','data_type','ModelSetting','training_ind','SampleX');

