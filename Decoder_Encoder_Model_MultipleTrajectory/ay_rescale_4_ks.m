function RetU = ay_rescale_4_ks(Xs,XPos,Xobs)
% do three steps
 XPos  = XPos/sum(XPos);
 xcdf  = cumsum(XPos);
 RetU  = zeros(length(Xobs),1);
 for l=1:length(Xobs)
    [~,ind] = min(abs(Xs-Xobs(l)));
    RetU(l)    = xcdf(ind);
 end