function Est = ay_filter_smoother(Param,Data)

%% Smoother-Filter Result Array
% filter mean
XPre= cell(Data.ObsrvLen,1);
% filter covariance
SPre= cell(Data.ObsrvLen,1);
% filter mean
XPos= cell(Data.ObsrvLen,1);
% filter covariance
SPos= cell(Data.ObsrvLen,1);
% smoother mean
XSmt= cell(Data.ObsrvLen,1);
% smoother covriance
SSmt= cell(Data.ObsrvLen,1);


%% State-Transition Model Parameter
Ak  = Param.Ak;
Bk  = Param.Bk;
Wk  = Param.Wk;

Ck  = Param.Ck;
Dk  = Param.Dk;
Vk  = Param.Vk;

% initial value
X0  = Param.M0';
W0  = Param.S0;


%% Run Filter Section
for k = 1:Data.ObsrvLen
    %% One step prediction
    if k == 1
        XPre{k} = Ak * X0 + Bk;
        SPre{k} = Ak * W0 * Ak' + Wk;
    else
        XPre{k} = Ak * XPos{k-1} + Bk ;
        SPre{k} = Ak * SPos{k-1} * Ak' + Wk;
    end
    
    %% Filter
    Yk = Data.Y(:,k);
    Sk = Ck * SPre{k} * Ck' + Vk;
    Yp = Ck * XPre{k} + Dk;
    XPos{k} =  XPre{k} + SPre{k} * Ck'* Sk^-1 * (Yk - Yp);
    SPos{k} = (SPre{k}^-1 + Ck' * Vk^-1 * Ck)^-1;
end
%% Run Smoother Section
As        = cell(Data.ObsrvLen,1);
% posterior mean and variance
XSmt{end} = XPos{end};
SSmt{end} = SPos{end};
for k=Data.ObsrvLen-1:-1:1
    % Ak, equation (A.10)
    As{k} = SPos{k} * Ak' *  SPre{k+1}^-1 ;
    % Smting function, equation (A.9)
    XSmt{k} = XPos{k} + As{k} * (XSmt{k+1}- XPre{k+1});
    % Variance update, equation (A.11)
    SSmt{k} = SPos{k} + As{k} * (SSmt{k+1}- SPre{k+1}) * As{k}';
end
% Kalman smoother for time 0
As0   = W0 * Ak' *  SPre{1}^-1;
XSmt0 = X0 + As0 * (XSmt{1} - XPre{1}) ;
SSmt0 = W0 + As0 * (SSmt{1} - SPre{1}) * As0';

%% Extra Component of the State Prediction Ckk = E(Xk*Xk-1)
% Ckk_1=E(Xk-1*Xk) prediction by smoothing - it is kept at index K
% Wkk_1= Ckk_1 + Bias
% Covariance for smoothed estimates in state space models - Biometrica
% 1988- 601-602
Ckk_1 = cell(Data.ObsrvLen,1);
Wkk_1 = cell(Data.ObsrvLen,1);
for k = 1:Data.ObsrvLen
    % Wkk update - Smoothing Xk-1*Xk
    if k>1
        Wkk_1{k} = As{k-1} * SSmt{k};
        Ckk_1{k} = Wkk_1{k} + XSmt{k} * XSmt{k-1}'; 
    else
        Wkk_1{k} = As0 * SSmt{k};
        Ckk_1{k} = Wkk_1{k} + XSmt{k} * XSmt0'; 
    end
end


%% Return Result
Est.XPos = cell2mat(XPos)';
Est.SPos = cell2mat(SPos)';
Est.XSmt = cell2mat(XSmt)';
Est.SSmt = cell2mat(SSmt)';
Est.XSmt0 = XSmt0;
Est.SSmt0 = SSmt0;
Est.Wkk_1 = cell2mat(Wkk_1)';
Est.Ckk_1 = cell2mat(Ckk_1)';
