function [z,t]=nz_bayes_classifier_CLoSES(m,S,X)
% ML Classifier
%   m: the mean of all class ([c,l] Matrix)
%   s: Covariance Matrix of all calss ([c,l,l] Matrix)
%   X: feature vector

[c,l]=size(m); % l=dimensionality, c=no. of classes
%[N,unused]=size(X); % N=no. of vectors
t = zeros(1,c); % RIZ: CAN I FIX it instead of size? -  before: [];
%z = zeros(1,N); 
%for i=1:N % RIZ removed as only 1 feature is considered each time
    for j=1:c
		t(j) = (2*pi)^(-length(m(j,:))/2)*det(squeeze(S(j,:,:)))^(-1/2)*exp(-0.5*(X-m(j,:))*inv(squeeze(S(j,:,:)))*(X-m(j,:))');
    end
    % Determining the maximum quantity Pi*p(x|wi)
    [num,z]=max(t);
%end
end
