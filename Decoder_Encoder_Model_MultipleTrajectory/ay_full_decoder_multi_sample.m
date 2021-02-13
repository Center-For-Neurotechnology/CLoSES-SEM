function [SmoothEstimate,SampleEstimate]=ay_full_decoder_multi_sample(model,sParam,Param,Valid,Yk)
% This returns whole decoder
% Param is cell of lenght Ns - collective model
% Param also keep relationship between Yk and each encoder (Yk is of length NxNs)
% Valid is one on decoder models have a X component - value equal to zero means the decoder is not vaalid
% YK is the input

%% generate the samples of the possible range
x_min=-3;x_max=3;sample=3000;
Xs=linspace(x_min,x_max,sample);
transP=ones(length(Xs),length(Xs));
for i=1:length(Xs)
    transP(i,:)=pdf('normal',Xs(i),sParam.a*Xs,sqrt(sParam.sv));
end

%% Run on each point
% number of model
Ms = length(Param);
% number of observation
N  = size(Yk,1);
% keep model estimate
Tmean = zeros(N,1); % moment mean
Tstd  = zeros(N,1); % moment Std
TBand = zeros(N,2); % moment Std
TProb = zeros(N,length(Xs)); % filtered moment Std

Smean = zeros(N,1); % filtered moment mean
Sstd  = zeros(N,1); % filtered moment Std
SBand = zeros(N,2); % filtered moment Std
SProb = ones(N,length(Xs)); % filtered moment Std

% Run for each M
% Now, I have something for each model
for m=1:Ms
    if Valid(m,1)
        Ws = size(Param{m}.W,1);
        xTProb = zeros(Ws,N,length(Xs));

        for ws=1:Ws
            [m ws]
            prvPx = ones(1,sample)/sample;  % prior
            tParam{1}   = Param{m};
            tParam{1}.W = Param{m}.W(ws,:)';
            tParam{1}.Dispersion = Param{m}.Dispersion(ws);

            for n=1:N
                if tParam{1}.EncModel.YPrv
                    if n==1
                        tAux{1}=[0          zeros(1,length(tParam{1}.EncModel.AuxInd))];
                    else
                        tAux{1}=[Yk(n-1,m)  Yk(n-1,tParam{1}.EncModel.AuxInd)];
                    end
                else
                    if n==1
                         tAux{1}= zeros(1,length(tParam{1}.EncModel.AuxInd));
                    else
                         tAux{1}= Yk(n-1,tParam{1}.EncModel.AuxInd);
                    end
                end
                tOut = Yk(n,m);
                % This will be addition of multiple samples
                [~,TPx]=ay_decoder(model,tParam,Xs,tAux,tOut,transP,prvPx);
                xTProb(ws,n,:) = TPx;
            end
        end
        % multiplication of models
        if size(xTProb,1) > 1
            TProb=TProb+log(squeeze(sum(xTProb)));
        else
            TProb=TProb+log(squeeze(xTProb));
        end
    end
end
TProb = TProb/abs(max(max(TProb)));
TProb = exp(TProb);
% prcvPx 
prvPx = ones(1,sample)/sample;  % prior
sPx=transP*prvPx';
for n=1:N
    % smoothing
    SProb(n,:) =  TProb(n,:).*sPx';
    % normalization
    SProb(n,:) =  SProb(n,:)./max(eps,sum(SProb(n,:)));
    % update sPx
    sPx = transP*SProb(n,:)';
end

% Normalize Probability and Calculate Statistics
for n=1:N
    % smooth
    SProb(n,:)= SProb(n,:)/max(eps,sum(SProb(n,:)));
    Smean(n)  = SProb(n,:)* Xs';
    Sstd(n)   = sqrt(SProb(n,:) *((Xs-Smean(n)).^2)');
    
    ind=find(cumsum(SProb(n,:))<=0.025);
    if isempty(ind)
        SBand(n,1)=Xs(1);
    else
        SBand(n,1)=Xs(ind(end));
    end
    
    ind=find(cumsum(SProb(n,:))>=0.975);
    if isempty(ind)
        SBand(n,2)=Xs(end);
    else
        SBand(n,2)=Xs(ind(1));
    end

    % moment
    TProb(n,:)= TProb(n,:)/max(eps,sum(TProb(n,:)));
    Tmean(n)  = TProb(n,:)* Xs';
    Tstd(n)   = sqrt(TProb(n,:) *((Xs-Tmean(n)).^2)');
    
    ind=find(cumsum(TProb(n,:))<=0.025);
    if isempty(ind)
        TBand(n,1)=Xs(1);
    else
        TBand(n,1)=Xs(ind(end));
    end
    
    ind=find(cumsum(TProb(n,:))>=0.975);
    if isempty(ind)
        TBand(n,2)=Xs(end);
    else
        TBand(n,2)=Xs(ind(1));
    end
end   


SampleEstimate.Prob  = TProb;
SampleEstimate.Mean  = Tmean;
SampleEstimate.Std   = Tstd;
SampleEstimate.Xs    = Xs;
SampleEstimate.Bounds= TBand;

SmoothEstimate.Prob  = SProb;
SmoothEstimate.Mean  = Smean;
SmoothEstimate.Std   = Sstd;
SmoothEstimate.Xs    = Xs;
SmoothEstimate.Bounds= SBand;


end