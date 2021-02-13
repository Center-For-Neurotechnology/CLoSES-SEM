function [Sxy]= computeCrossSpectrumFromXxYy(Xx,Yy,win)


%U = sum(win)^2; % bacuse we want ms: if any(strcmpi(esttype,{'ms','power'}))
U = win'*win;

Sxy = bsxfun(@times,Xx,conj(Yy))/U;  % Cross spectrum.  % We use bsxfun here because Yy can be a single vector or a matrix
%Sxy = bsxfun(@times,Xx,conj(Yy)); %U cancels out

