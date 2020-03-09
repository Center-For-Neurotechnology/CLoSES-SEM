function TProb = ay_individual_decoder(model,Param,Xs,valid,Y)
% This returns whole decoder
% Param is cell of lenght Ns - collective model
% Param also keep relationship between Yk and each encoder (Yk is of length NxNs)
% Valid is one on decoder models have a X component - value equal to zero means the decoder is not vaalid
% YK is the input
max_mdl_b   = 10000;
%% Run decoder on each point
% number of features
Ms       = length(Param);
TProb    = cell(Ms,1);   
%% we have build the decoder per valid feature
% we might use previous point of feature
Yprv = zeros(1,Ms);
for s=1:size(Y,1)
    % on each sample
    Yk = Y(s,:);
    for m=1:Ms
        TProb{m}.valid=0;
        if valid(m,1)
            TProb{m}.valid=1;
            % here, I run over each weight samples
            Ws     = size(Param{m}.W,1);
            xTProb = zeros(Ws,length(Xs));
            for ws=1:Ws
                % build one temporary model for a set of samples weights
                tParam   = Param{m};
                tParam.W = Param{m}.W(ws,:)';
                tParam.Dispersion = Param{m}.Dispersion(ws);
                % check other auxiliary input feature
                if tParam.EncModel.YPrv
                    tAux = [Yprv(m)  Yprv(tParam.EncModel.AuxInd)];
                else
                    tAux = Yprv(tParam.EncModel.AuxInd);
                end
                % generate data
                Xmdl = tParam.EncModel.XPow;
                InX  = zeros(length(Xs),sum(Xmdl));
                fill_ind =0;
                for i=1:length(Xmdl)
                    if Xmdl(i)==1
                        fill_ind = fill_ind + 1;
                        InX(:,fill_ind) = Xs.^(i-1);
                    end
                end
                % run decoder
                if model==1     % Gamma Distribution
                    % current step
                    In   = [InX repmat(tAux,length(Xs),1)];
                    if sum(isinf(In))==0 & sum(isnan(In))==0
                        if isinf(Yk(m))==0 & isnan(Yk(m))==0
                          mdl_a    = 1/tParam.Dispersion; 
                          mdl_b    = max(eps,min(max_mdl_b,exp(In*tParam.W)))/mdl_a;
                          xTProb(ws,:)  = pdf('Gamma',Yk(m),repmat(mdl_a,length(Xs),1),mdl_b);
                        end
                    end
                end
                if model==2     % Normal
                    % current step
                    In       = [InX repmat(tAux,length(Xs),1)];
                    if sum(isinf(In))==0 & sum(isnan(In))==0
                        if isinf(Yk(m))==0 & isnan(Yk(m))==0
                            mdl_mean = In * tParam.W;
                            mdl_std  = sqrt(tParam.Dispersion);
                            xTProb(ws,:)  = pdf('normal',Yk(m),mdl_mean,repmat(mdl_std,length(Xs),1));
                        end
                   end
                end
            end
            % multiplication of models
            if size(xTProb,1) > 1
                TProb{m}.prb(s,:) = squeeze(sum(xTProb));
            else
                TProb{m}.prb(s,:) = squeeze(xTProb);
            end
            TProb{m}.prb(s,:) = TProb{m}.prb(s,:)/max(sum(TProb{m}.prb(s,:)),eps); 
        end
    end
    Yprv = Yk;
end

end