function TL = ay_likelihood_encoder(model,Param,feat_ind,Xs,Aux,Yk)
% This returns whole decoder
% Param is cell of lenght Ns - collective model
% Param also keep relationship between Yk and each encoder (Yk is of length NxNs)
% Valid is one on decoder models have a X component - value equal to zero means the decoder is not vaalid
% YK is the input
max_mdl_b   = 10000;

%% Run decoder on each point
% number of features
% here, I run over each weight samples
TL = zeros(length(Xs),length(Yk{1}));
% generate data
Xmdl = Param.EncModel.XPow;
for n=1:length(Xs)
    % build the data per sample
    InX      = [];
    fill_ind = 0;
    for i=1:length(Xmdl)
        if Xmdl(i)==1
            fill_ind = fill_ind + 1;
            InX(:,fill_ind) = Xs{n}.^(i-1);
        end    
    end
    if Param.EncModel.YPrv
        Yprv = [0;Yk{n}(1:end-1)];
        InX  = [InX Yprv];
    end
    if ~isempty(Param.EncModel.AuxInd)
        InX = [InX Aux{n}(:,Param.EncModel.AuxInd)];
    end
    if model==1     % Gamma Distribution
        % use the data to find likelihood
        mdl_a  = 1/Param.Dispersion; 
        mdl_b  = max(eps,min(max_mdl_b,exp(InX*Param.W')))/mdl_a;
        TL(n,:)= cdf('Gamma',Yk{n},repmat(mdl_a,length(Yk{n}),1),mdl_b);
    end
    if model==2     % Normal
        mdl_mean = InX * Param.W';
        mdl_std  = sqrt(Param.Dispersion);
        TL(n,:)  = cdf('normal',Yk{n},mdl_mean,repmat(mdl_std,length(Yk{n}),1));
    end

end
end