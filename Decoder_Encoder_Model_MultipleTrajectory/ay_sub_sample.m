function [ret_model]=ay_sub_sample(model,p_sample)
% This function take X, run the model, and then create the best subsample
% number of sample 
[ns,ms] = size(model.W); 
% sample per data point
Ws = [];
for k=1:ns
   % find multiple internal samples
   Mu    = [model.W(k,:) model.Dispersion(k)];
   Sigma = squeeze(model.C(k,:,:));
   Sigma(ms+1,ms+1)= model.DispersionVar(k);     
   rng default  % For reproducibility
   if p_sample == 1
       Ws      = [Ws;Mu];
   else
       temp_x  = mvnrnd(Mu,Sigma,p_sample);
       Ws      = [Ws;temp_x];
   end
end

model.W         = Ws(:,1:end-1);
model.Dispersion= Ws(:,end);
ret_model = model;