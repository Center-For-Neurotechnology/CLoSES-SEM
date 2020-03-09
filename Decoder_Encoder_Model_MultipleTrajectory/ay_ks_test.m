function [dU,isU] = ay_ks_test(Us,SL,mode,PlotGraph)
% 8/24 I thin this is the newer version
if nargin==1
    SL = 1;
    mode = 2;
    PlotGraph = 0;
end
if nargin==2
    mode = 2;
    PlotGraph = 0;
end
if nargin==3
    PlotGraph = 0;
end

if SL==10,  Kc=1.224; end
if SL==5,   Kc=1.358; end
if SL==1,   Kc=1.628; end
sr   = 0:0.01:1;
if mode==1
    dU = 0;
    [Samp,Len] = size(Us);
    H0         = zeros(Samp,1);
    for l=1:Samp
        % run hist
        su = hist(Us(l,:),sr);
        sp = cumsum(su)/Len;
        [dUt,ind] = max(abs(sp-sr));
    
    if PlotGraph
        plot(sr,sr);hold on;plot(sr,sp);
        plot([sr(ind);sr(ind)],[sp(ind);sr(ind)]);
        hold off;
    end
        H0(l) =  sqrt(Len)*dUt < Kc ;
    %   if PlotGraph
    %         title(['d=' num2str(dU) ', n=' num2str(length(Us)) ', isU=' num2str(isU)])
    %   end
        dU = max(dU,dUt);
    end
    [~,low_up] = binofit(sum(H0),Samp,SL/100);
    isU  = low_up(2) >= (100-SL)/100;
    %isU = (sum(H0)/Samp) < max(eps,sl - 2 * sqrt(sl*(1-sl)/Samp));
else
    [Samp,Len] = size(Us);
    su = hist(reshape(Us,[1 Samp*Len]),sr);
    sp = cumsum(su)/(Len*Samp);
    [dU,ind] = max(abs(sp-sr));
    isU =  sqrt(Len*Samp)*dU < Kc ;
end
 