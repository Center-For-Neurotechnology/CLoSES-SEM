function [dU,isU,XL] = ay_decoder_ks(Xs,fMap,Y,SL,mode)
% 8/24 new code to test KS test on the test data

% Xs, is the sample over X
% fMap, is the likelihood function - size:  length of observatiob x length(Xs)
% Y is the X samples - size: length of observatiob x number of samples
% SL is KS rate
% mode 1 or 2 -  which is used in KS test
% 1 combines all samples, more conservative test
% 2 checks per sample

% here, we draw sample given the likelihood function
 sMap = cumsum(fMap,2);
 for i=1:size(Y,1)
     for j=1:size(Y,2)
         [~,ind] = min(abs(Y(i,j)-Xs));
         XL(i,j) = sMap(i,ind)/sMap(i,end);
     end
 end
 [dU,isU] = ay_ks_test(XL',SL,mode,0);     