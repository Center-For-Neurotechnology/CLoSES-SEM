% clear previous files
close all
clear all
% set file name
FileNo       = 3;
% Internal parameters
% File 2, state 1
which_state  = 1;   % Which state variables to link
model        = 2;   % Encoder Model gamma (1), log-normal (2)
mode         = 2;   % Training Mode 1=batch, 2=multiple result
kfold        = 3;   % K-folds
sample       = 1;   % data sample
p_sample     = 10;  % paremeter sample
sel_pVal     = 0.0001;
sel_mode     = 4;
sParam.a     = 0.99;
sParam.sv    = 0.01; 
% File List (Feature and State Files)
F_FileName={'m96.mat',
            'm99.mat',
            'proc_mg102.mat',
            'm104.mat',
            'proc_mg105.mat',
            'm106.mat'};       
%--------------------
% load feature file       
file_name = F_FileName{FileNo};
load(file_name);
%--------------------
%ind=find(Y<=0);Y(ind)=eps;
no_feature = size(Y,2);
% if model==2
%     Y=log(1+Y);
% end

%--------------------
% take state variable from the state file (we need only mean) - X is the state
temp = cell2mat(XPos');
X     = temp(which_state,:)';
for t=1:length(SPos)
        X_low(t)  = X(t)-2*sqrt(SPos{t}(which_state,which_state));
        X_high(t) = X(t)+2*sqrt(SPos{t}(which_state,which_state));
end
no_trials  = length(X);
%-------------------
% Run Encoder/Decoder
PERF    = zeros(3,1);
indices = crossvalind('KFold',no_trials,kfold);
for k=1:kfold
    % test index
    test_ind  = find(indices==k);
    test_ind  = test_ind(find(test_ind>1));
    % train idex
    train_ind = find(indices~=k);
    train_ind = train_ind(find(train_ind>1));
    % model is trained by train_ind subset
    Yi = cell(sample,1);
    Xi = cell(sample,1);
    Aux= cell(sample,1);
    eParam = cell(no_feature,1);
    for fn = 1:no_feature
       % To avoid circular issue, make the condition as 
       AuxInd = [1:fn-1]; 
       AuxInd = [];
       for s = 1:sample
             % causal component
             Aux{s}= Y(train_ind-1,AuxInd);     
             % observation
             Yi{s} = Y(train_ind,fn);
             % 
             Xi{s} = X(train_ind,s);
       end
       model_a=ay_encoder_selector_stepwise(sel_mode,1,mode,model,Xi,Aux,AuxInd,Yi,sel_pVal);
       eParam{fn}= model_a;
    end
    
    % decoder model(only pick valid models)
    dParam = cell(no_feature,1);
    dValid = zeros(no_feature,2);
    for fn=1:no_feature
        tmp_model    = eParam{fn};
        dValid(fn,1)   = sum(tmp_model.EncModel.XPow)>1;
        dValid(fn,2)   = tmp_model.AIC;
        if dValid(fn)
            % here, we assume the sample is mean and we sample multiple points
            tmp_model = ay_sub_sample(tmp_model,p_sample);
        end    
        %tmp_model.Len= size(tmp_model.W,2) * ones(size(tmp_model.W,1),1);
        dParam{fn}=tmp_model;
    end
    
    for l=1:no_feature
        figure(l)
        subplot(2,1,1)
        plot(X,'k','LineWidth',2);hold on;plot(X_low,'b');plot(X_high,'b');hold off;
        ylabel('State Variable');
        axis tight
        if dValid(l)==1
            title('To be used in the decoder model')
        else
            title('Rejected by the encoder selection process')
        end
        subplot(2,1,2)
        plot(Y(:,l),'k','LineWidth',2);
        ylabel(['Neural Feature ' num2str(l)])
        axis tight
    end
    close all;
    % sort the models given their deviance - pick top N
%     if sum(dValid(:,1))
%          valid_ind = find(dValid(:,1));
%          valid_AIC = dValid(valid_ind,2);
%          [sort_AIC,tmp_ind]  = sort(valid_AIC);
%          tmp_ind = valid_ind(tmp_ind(find(sort_AIC <= 10*sort_AIC(1))));
%          dValid(:,1)=0;dValid(tmp_ind,1)=1;
%     end
    % encoder model
    [s_estimate,x_estimate]=ay_full_decoder_multi_sample(model,sParam,dParam,dValid,Y);
     if sum(dValid(:,1))
        figure()
        plot(X,'k','LineWidth',2);hold on;plot(X_low,'b');plot(X_high,'b');plot(s_estimate.Mean,'r','LineWidth',2);
        plot(test_ind,s_estimate.Mean(test_ind),'go');
        hold off;
        legend('X','Xlow','Xhigh','Xprd');
        
        figure()
        subplot(2,1,1)
        title('Likelihood Estimate')
        imagesc(1:no_trials,s_estimate.Xs,x_estimate.Prob');
        axis([-inf inf -0.6 0.0])
        
        title('Likelihood Estimate')
        subplot(2,1,2)
        title('Filter Estimate')
        imagesc(1:no_trials,s_estimate.Xs,s_estimate.Prob');
        axis([-inf inf -0.6 0.0])
        title('Filter Estimate')
        
        
        figure()
        imagesc(1:no_trials,s_estimate.Xs,s_estimate.Prob');
        axis([-inf inf -0.6 0.0]);
        hold on;
        plot(1:no_trials,X,'w','LineWidth',2);
        plot(1:no_trials,X_low,'w-','LineWidth',0.5);
        plot(1:no_trials,X_high,'w-','LineWidth',0.5);
        plot(1:no_trials,s_estimate.Mean,'g','LineWidth',2);
        title('Filter Estimate')
        hold off;
    end
    % performance check
    Xk = X(test_ind);
    for fn=1:length(test_ind)
        % sort pdf along with x
        x_pdf = x_estimate.Prob(fn,:);
        x_s   = x_estimate.Xs;
        [x_pdf,x_ind] = sort(x_pdf,'descend');
        x_s   = x_s(x_ind);
        x_pdf = cumsum(x_pdf);
        % find xs
        x_t = Xs(:,fn);
        px  =[];
        % match x_t to x_s
        for t=1:length(x_t)
            [~,t_ind]=min(abs(x_t(t)-x_s));
            px(t)=x_pdf(t_ind);
        end
        PERF(1)=PERF(1)+sum((px-0.95)<0);
        PERF(2)=PERF(2)+length(x_t);
    end
    PERF(3)= PERF(3) + (sum((mean(Xk)-x_estimate.Mean).^2)/length(test_ind));
end
REF(3)=REF(3)/kfold;
save('test_a','PERF');

% plot(SampleEstimate.Mean,'b','LineWidth',1);
% hold on;
% plot(m_which_state,'k-','LineWidth',4);
% plot(m_which_state-2*sqrt(s_which_state),'k--','LineWidth',2);
% % plot(m_which_state+2*sqrt(s_which_state),'k--','LineWidth',2);
% % hold on;
% % plot(SmoothEstimate.Mean,'r','LineWidth',4);
% % hold off;

