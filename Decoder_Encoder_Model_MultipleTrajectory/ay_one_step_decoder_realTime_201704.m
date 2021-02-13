function [XPos,Estimate,TProb]= ay_one_step_decoder_realTime_201704(modelType, Param_W, Param_Dispersion, Param_EncModel_XPow, XPre, TransP, Xs, valid, Yk, Yprv)
% This returns whole decoder - it is now part of decoder model folder
% Param is cell of lenght Ns - collective model
% Param also keep relationship between Yk and each encoder (Yk is of length NxNs)
% Valid is one on decoder models have a X component - value equal to zero means the decoder is not vaalid
% YK is the input
const_scale = log(1e6);
max_mdl_b   = 10000;

%% Run decoder on each point
% number of features
Ms    = size(Param_W,1);
lTime = length(Xs);
TProb = zeros(1,lTime);   
for m=1:Ms
    if valid(m,1)
        % here, I run over each weight samples
        Ws     = 1; %size(Param.W,2);
        xTProb = zeros(Ws,length(Xs));
        for ws=1:Ws
            % build one temporary model for a set of samples weights
            %tParam   = Param{m};
            tParam_W = Param_W(m,:)';
            tParam_Dispersion = Param_Dispersion(m);
            % check other auxiliary input feature
            tAux = Yprv(m); % Ali - please check that it is correct!
%             if tParam.EncModel.YPrv
%                 tAux = [Yprv(m)  Yprv(tParam.EncModel.AuxInd)];
%             else
%                 tAux = Yprv(tParam.EncModel.AuxInd);
%             end
            % generate data
            Xmdl = Param_EncModel_XPow(m,:);
            %InX  = zeros(length(Xs),sum(Xmdl));
            InX  = zeros(length(Xs),2); % RIZ make sure that it is always 2! if model is different it shuild be changed!!
            fill_ind =0;
            for i=1:length(Xmdl)
                if Xmdl(i)==1
                    fill_ind = fill_ind + 1;
                    InX(:,fill_ind) = Xs.^(i-1);
                end
            end
            % run decoder
            if modelType==1     % Gamma Distribution
                % current step
                In   = [InX repmat(tAux,length(Xs),1)];
                if sum(isinf(In))==0 & sum(isnan(In))==0
                    if isinf(Yk(m))==0 & isnan(Yk(m))==0
                      mdl_a    = tParam_Dispersion; 
                      mdl_b    = max(eps,min(max_mdl_b,exp(In*tParam_W)))/mdl_a;
                      xTProb(ws,:)  = pdf('Gamma',Yk(m),repmat(mdl_a,length(Xs),1),mdl_b);
                    end
                end
            end
            if modelType==2     % Normal
                % current step
                In       = [InX repmat(tAux,length(Xs),1)];
                if sum(isinf(In))==0 & sum(isnan(In))==0
                    if isinf(Yk(m))==0 & isnan(Yk(m))==0
                        mdl_mean = In * tParam_W;
                        mdl_std  = sqrt(tParam_Dispersion);
                        xTProb(ws,:)  = pdf('normal',Yk(m),mdl_mean,repmat(mdl_std,length(Xs),1));
                    end
               end
            end
        end
        % multiplication of models
        if size(xTProb,1) > 1
            TProb = TProb + log(squeeze(sum(xTProb)));
        else
            TProb = TProb + log(squeeze(xTProb));
        end
    end
end
% scale likelihood
TProb = TProb-max(TProb)+const_scale;
% note, we need likelihood not its logarithm
TProb = exp(TProb);

%% Next step is one step prediction and filter
% filter resulr
XPos = zeros(1, lTime);
auxTProb=0;auxXPos=0;
for t=1:length(XPos)
    auxXPos = (TransP(t,:)*XPre');
    auxTProb = TProb(t);
    XPos(t) = auxTProb*auxXPos;
end
%XPos = TProb.*(TransP*XPre')'; % RIZ: this is the original and correct way of doing it - but simulink didn't like the matrix multiplication 

% Normalize Probability and Calculate Statistics
XPos  = XPos/max(eps,sum(XPos));
Smean =0;
for t=1:length(XPos)
    Smean = Smean + XPos(t) * Xs(t);
end
%Smean = XPos * Xs'; % RIZ: this is the original and correct way of doing it - but simulink didn't like the matrix multiplication 

% std - re organize in small steps because compiler didn't like the matrix multiplication
XsNoMean = (Xs-Smean);
sumTemp =0;
for t=1:length(XPos)
    sumTemp = sumTemp + XPos(t) * XsNoMean(t)^2;
end
Sstd  = sqrt(sumTemp);
%Sstd  = sqrt(XPos *((Xs-Smean).^2)'); % RIZ: this is the original and correct way of doing it - but simulink didn't like the matrix multiplication 

SBand = zeros(1,2);
ind=find(cumsum(XPos)<=0.025);
SBand(1)=Xs(1); %RIZ: small change to assign first - required by compiler
if ~isempty(ind)
    SBand(1)=Xs(ind(end));
end
ind=find(cumsum(XPos)>=0.975);
SBand(2)=Xs(end);  %RIZ: small change to assign first - required by compiler
if ~isempty(ind)
    SBand(2)=Xs(ind(1));
end

Estimate.Mean  = Smean;
Estimate.Std   = Sstd;
Estimate.Bound = SBand;

end
