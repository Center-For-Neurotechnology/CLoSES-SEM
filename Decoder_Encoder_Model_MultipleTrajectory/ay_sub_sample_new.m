function [Ws,Ds]=ay_sub_sample_new(mode,model,sample,in_sample)
% This function take X, run the model, and then create the best subsample
% Here, we assume number of samples in X is much larger than number of
% samples needs to be created

% number of sample 
[ns,ms] = size(model.W); 
% sample per data point
X = [];
for k=1:ns
   % find multiple internal samples
   Mu    = [model.W(k,:) model.Dispersion(k)];
   Sigma = squeeze(model.C(k,:,:));
   Sigma(ms+1,ms+1)= model.DispersionVar(k);     
   rng default  % For reproducibility
   temp_x  = mvnrnd(Mu,Sigma,in_sample);
   X     = [X;temp_x];
end
sample = min(sample,size(X,1));
if mode == 1   % GMM model
   % run GMM with sample cluster, plus a regualrization term
   RegularizationValue = 0.001;
   options = statset('MaxIter',10000);
   gm = fitgmdist(X,sample,...
                'CovarianceType','full',...
                'SharedCovariance',false,...
                'RegularizationValue',RegularizationValue,...
                'Options',options);
   % extract sub-samples
   Ws = gm.mu;
end
if mode ==2   % K-mean clustering
   if sample==1
         Ws = X;
   else
        [~,Ws] = kmeans(X,sample);
   end
end