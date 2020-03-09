function TL = ay_likelihood(model,Param,feat_ind,Xs,Yk,Yprv)
% This returns whole decoder
% Param is cell of lenght Ns - collective model
% Param also keep relationship between Yk and each encoder (Yk is of length NxNs)
% Valid is one on decoder models have a X component - value equal to zero means the decoder is not vaalid
% YK is the input
max_mdl_b   = 10000;

%% Run decoder on each point
% number of features
% here, I run over each weight samples
TL = zeros(1,length(Xs));
   
% check other auxiliary input feature
if Param.EncModel.YPrv
       tAux = [Yprv(feat_ind)  Yprv(Param.EncModel.AuxInd)];
else
       tAux = Yprv(Param.EncModel.AuxInd);
end
% generate data
Xmdl = Param.EncModel.XPow;
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
       if isinf(Yk)==0 & isnan(Yk)==0
              mdl_a    = 1/Param.Dispersion; 
              mdl_b    = max(eps,min(max_mdl_b,exp(In*Param.W')))/mdl_a;
              TL  = pdf('Gamma',Yk,repmat(mdl_a,length(Xs),1),mdl_b);
       end
   end
end
if model==2     % Normal
    % current step
    In       = [InX repmat(tAux,length(Xs),1)];
    if sum(isinf(In))==0 & sum(isnan(In))==0
        if isinf(Yk)==0 & isnan(Yk)==0
            mdl_mean = In * Param.W';
            mdl_std  = sqrt(Param.Dispersion);
            TL  = pdf('normal',Yk,mdl_mean,repmat(mdl_std,length(Xs),1));
        end
   end
end
TL = TL/sum(TL);

end