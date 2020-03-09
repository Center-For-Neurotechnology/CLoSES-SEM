function model2=ay_map_to_sim(model)
% load data
load(model);
% get the length
% get the length
Ns  = size(dValid,1);
ind = find(dValid(:,1));
tLen = 1+length( eParam{ind(1),1}.EncModel.XPow);
% re-map the model
for n=1:Ns
    tempW = zeros(1,tLen);
    ind   = 1;
    xLen = 1+length( eParam{n,1}.EncModel.XPow);
    for i = 1:xLen-1
        if eParam{n,1}.EncModel.XPow(i)
            tempW(i) = eParam{n, 1}.W(ind);
            ind      = ind + 1;
        end
    end
    if eParam{n, 1}.EncModel.YPrv
        tempW(end)= eParam{n, 1}.W(ind+1);
    end
    
    eParam{n, 1}.EncModel.XPow= ones(1,tLen-1);
    eParam{n, 1}.EncModel.YPrv   = 1;
    eParam{n, 1}.W = tempW;
end
% save the model
model2=['Decider_',model];
save(model2,'eParam','sParam','dValid','data_type','ModelSetting','training_ind','SampleX');
