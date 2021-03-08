function [z,t]=nz_bayes_classifier_CLoSES(m,S,X)
% ML Classifier
%   m: the mean of all class ([c,l] Matrix)
%   s: Covariance Matrix of all calss ([c,l,l] Matrix)
%   X: feature vector

[c,l]=size(m); % l=dimensionality, c=no. of classes
%[N,unused]=size(X); % N=no. of vectors
t = zeros(1,c); % RIZ: CAN I FIX it instead of size? -  before: [];
%z = zeros(1,N); 
%constant1 = 1;
%for i=1:N % RIZ removed as only 1 feature is considered each time
    for j=1:c
        t(j)=mvnpdf(X,m(j,:),squeeze(S(j,:,:)));
       % t(j)=constant1*exp(-0.5*(X-m(j,:))*inv(squeeze(S(j,:,:)))*(X-m(j,:))');
     %   t(i,j)=constant1*exp(-0.5*(X(i,:)-m(j,:))*inv(reshape(S(j,:,:),[l,l]))*(X(i,:)-m(j,:))');
    end
    % Determining the maximum quantity Pi*p(x|wi)
    [num,z]=max(t);
%end
