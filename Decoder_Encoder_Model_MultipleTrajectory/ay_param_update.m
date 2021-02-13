function UParam = ay_param_update(WhichParam,Param,Est,Data)
%% Parameter Update
% We assume X is scalar -  AR1 model
% X~a*X+b+v
% We assume Y is a vector with a Diagonal Noise
% Each Y is a linear model of Y~c*X+d+w 
UParam = Param;

Ak = Param.Ak;
Bk = Param.Bk;

Ck = Param.Ck;
Dk = Param.Dk;

%% Update a,b
if WhichParam.ab_on
   %- estimate Ak, Bk both scalar 
   A = zeros(2,2);
   B = zeros(2,1);
   
   
   for n=1:length(Est.XSmt)
       if n==1
           A(1,1)= Est.XSmt0^2 + Est.SSmt0;
           A(1,2)= Est.XSmt0;
       else
          A(1,1)= A(1,1)+ Est.XSmt(n-1)^2 + Est.SSmt(n-1);
          A(1,2)= A(1,2)+ Est.XSmt(n-1);
       end
       B(1,1)= B(1,1) + Est.Ckk_1(n);
       B(2,1)= B(2,1) + Est.XSmt(n);
   end
   A(2,1)= A(1,2);
   A(2,2)= length(Est.XSmt);
   
   temp  = pinv(A)*B;
   UParam.Ak = temp(1);
   UParam.Bk = temp(2);
   
   Ak = UParam.Ak;
   Bk = UParam.Bk;
end

if WhichParam.x0_on
    UParam.M0 = (Est.XSmt(1)-Bk)/Ak;
    UParam.S0 = (Est.XSmt(1)^2 + Est.SSmt(1))+ Ak^2 * (Est.XSmt0^2 + Est.SSmt0) + Bk^2 ...
                                            - 2*Ak * Est.Ckk_1(1) - 2*Bk*Est.XSmt(1) + 2*Ak*Bk*Est.XSmt0;
end

%% Update v
if WhichParam.v_on
    S = (Est.XSmt(1)^2 + Est.SSmt(1))+ Ak^2 * (Est.XSmt0^2 + Est.SSmt0) + Bk^2 ...
                                            - 2*Ak * Est.Ckk_1(1) - 2*Bk*Est.XSmt(1) + 2*Ak*Bk*Est.XSmt0;
    for n=2:length(Est.XSmt)
        S = S + (Est.XSmt(n)^2 + Est.SSmt(n))+ Ak^2 * (Est.XSmt(n-1)^2 + Est.SSmt(n-1)) + Bk^2 ...
                                            - 2*Ak * Est.Ckk_1(n) - 2*Bk*Est.XSmt(n) + 2*Ak*Bk*Est.XSmt(n-1);
    end
    UParam.Wk = S/length(Est.XSmt);
end

%% Update c,d
if WhichParam.cd_on
   L = length(Data.Y(:,1)); 
   
   for d=1:L
       
       A = zeros(2,2);
       B = zeros(2,1);
       
       for n=1:length(Est.XSmt)
          A(1,1)= A(1,1)+ Est.XSmt(n)^2 + Est.SSmt(n);
          A(1,2)= A(1,2)+ Est.XSmt(n);
          
          B(1,1)= B(1,1) + Est.XSmt(n)* Data.Y(d,n);
          B(2,1)= B(2,1) + Data.Y(d,n);
       end
       A(2,1)= A(1,2);
       A(2,2)= length(Est.XSmt);
       
       temp  = pinv(A)*B;
       UParam.Ck(d,1) = temp(1);
       UParam.Dk(d,1) = temp(2);
       
   end
   
end

%% Update w
if WhichParam.w_on
    L  = length(Data.Y(:,1)); 
    
    Vk = zeros(L,L);
    
    for d=1:L
        
        S = 0;
        for n = 1:length(Est.XSmt)
            S = S+ Data.Y(d,n)^2 + Ck(d)^2 * (Est.XSmt(n)^2 + Est.SSmt(n))+ Dk(d)^2 ...
                                            -2*Ck(d)* Data.Y(d,n)* Est.XSmt(n) - 2 * Dk(d)* Data.Y(d,n) + 2* Ck(d)*Dk(d)* Est.XSmt(n);
        end
        
        Vk(d,d)= S/length(Est.XSmt);
    end
    
    UParam.Vk = Vk;
end


