function RefParam =ay_encoder_selector_stepwise(seq_model,test,model,In,Aux,AuxInd,Out,pVal)
% "test" variable determine which test (F or AIC) will be run
% "mode and model" vairables are used in Encode function

% For the encoder model
% 1. We assume In is the state variable, a vector of length 1
% 2. We also assume Aux include possible covariates (this excludes Out)
% We also assume Out is a vector with similar length of InX

% The optimum encoder picks the encoder using a successive F or AIC test.
% The first step, is checking 1+X, 1+X+X2, 1+X+X3+X4
% The second step, is checking the first step outcome with Out hisotry term
% The last step, is checking the second step outocme with Aux inputs one by one

% The optimum model will be the model with the best F or AIC test
% Param, Yhat, Ymean, and Yvar are the result for the optimum model
if nargin <8
    disp('Insufficient Input')
    return;
end
p_order = 3;

% Get number of Ns
Ns = length(In);
m  = size(In{1},1);
if seq_model == 1    % X, Y(-1), other Ys
    % We assume the reference model is 1
    for n=1:Ns
        RefIn{n} = ones(m,1);
    end
    RefParam = ay_encoder(model,RefIn,Out);
    RefModel = '1';
    EncModel.XPow = [1];
    EncModel.YPrv = [0];
    EncModel.Aux  = [];
    %% Here, we build possible input
    for i=1:p_order
        % perform encoder
        for n=1:Ns
            tmpIn{n}    = [RefIn{n} In{n}.^i];
        end
        tmpParam = ay_encoder(model,tmpIn,Out);
        % run the test
        if test==1 %F-test
            n  = size(tmpIn{1},1)*Ns;
            Dm   = tmpParam.Deviance;
            Disp = tmpParam.Dispersion;
            Dm0  = RefParam.Deviance;
            pret = fcdf((Dm0-Dm)/Disp,1,n-tmpParam.Len,'upper');
            if pret < pVal
                % Update model
                RefParam= tmpParam;
                RefIn   = tmpIn;
                RefModel=strcat(RefModel,'+X^',num2str(i));
                EncModel.XPow=[EncModel.XPow; 1];
            else
                EncModel.XPow=[EncModel.XPow; 0];
            end
        end
        if test==2 %AICay
            RefBIC = RefParam.BIC;
            tmpBIC = tmpParam.BIC;
            if tmpBIC < RefBIC
                % Update model
                RefParam= tmpParam;
                RefIn   = tmpIn;
                RefModel=strcat(RefModel,'+X^',num2str(i));
                EncModel.XPow=[EncModel.XPow; 1];
            else
                EncModel.XPow=[EncModel.XPow; 0];
            end
        end
    end

    if sum(EncModel.XPow)>1
        %% Here, we check History (Out-1)
        % perform encoder
        for n=1:Ns
            temp = [0; Out{n}(1:end-1)];
            tmpIn{n}=[RefIn{n} temp];
        end
        tmpParam = ay_encoder(model,tmpIn,Out);
        % run the test
        if test==1 %F-test
            n    = size(tmpIn{1},1)*Ns;
            Dm   = tmpParam.Deviance(1);
            Disp = tmpParam.Dispersion(1);
            Dm0  = RefParam.Deviance(1);
            pret = fcdf((Dm0-Dm)/Disp,1,n-tmpParam.Len,'upper');
            if pret < pVal
                % Update model
                RefParam = tmpParam;
                RefIn    = tmpIn;
                RefModel = strcat(RefModel,'+Y(-1)');
                EncModel.YPrv=1;
            end
        end
        if test==2 %BIC
            RefBIC = RefParam.BIC;
            tmpBIC = tmpParam.BIC;
            if tmpBIC < RefBIC
                % Update model
                RefParam = tmpParam;
                RefIn    = tmpIn;
                RefModel = strcat(RefModel,'+Y(-1)');
                EncModel.YPrv=1;
            end
        end


        %% Here, we add other possible input one by one
        for i=1:size(Aux{1},2)
            % perform encoder
            for n=1:Ns
                tmpIn{n} = [RefIn{n} Aux{n}(:,i)];
            end
            tmpParam = ay_encoder(model,tmpIn,Out);
            % run the test
            if test==1 %F-test
                n    = size(tmpIn{1},1)*Ns;
                Dm   = tmpParam.Deviance;
                Disp = tmpParam.Dispersion;
                Dm0  = RefParam.Deviance;
                pret = fcdf((Dm0-Dm)/Disp,1,n-tmpParam.Len,'upper');
                if pret < pVal
                    % Update model
                    RefParam= tmpParam;
                    RefIn   = tmpIn;
                    RefModel=strcat(RefModel,'+Aux(',num2str(i),')');
                    EncModel.Aux=[EncModel.Aux; i];
                end
            end
            if test==2 %BIC
                RefBIC = RefParam.BIC(l);
                tmpBIC = tmpParam.BIC(l);
                if tmpBIC < RefBIC
                    % Update model
                    RefParam= tmpParam;
                    RefIn   = tmpIn;
                    RefModel=strcat(RefModel,'+Aux(',num2str(i),')');
                    EncModel.Aux=[EncModel.Aux; i];
                end
            end
        end
    end
end
if seq_model == 2    % X, Y(-1)
    % We assume the reference model is 1
    for n=1:Ns
        RefIn{n} = ones(m,1);
    end
    RefParam = ay_encoder(model,RefIn,Out);
    RefModel = '1';
    EncModel.XPow = [1];
    EncModel.YPrv = [0];
    EncModel.Aux  = [];
    %% Here, we build possible input
    for i=1:p_order
        % perform encoder
        for n=1:Ns
            tmpIn{n}    = [RefIn{n} In{n}.^i];
        end
        tmpParam = ay_encoder(model,tmpIn,Out);
        % run the test
        if test==1 %F-test
            n  = size(tmpIn{1},1)*Ns;
            Dm   = tmpParam.Deviance;
            Disp = tmpParam.Dispersion;
            Dm0  = RefParam.Deviance;
            pret = fcdf((Dm0-Dm)/Disp,1,n-tmpParam.Len,'upper');
            if pret < pVal
                % Update model
                RefParam= tmpParam;
                RefIn   = tmpIn;
                RefModel=strcat(RefModel,'+X^',num2str(i));
                EncModel.XPow=[EncModel.XPow; 1];
            else
                EncModel.XPow=[EncModel.XPow; 0];
            end
        end
        if test==2 %AICay
            RefBIC = RefParam.BIC;
            tmpBIC = tmpParam.BIC;
            if tmpBIC < RefBIC
                % Update model
                RefParam= tmpParam;
                RefIn   = tmpIn;
                RefModel=strcat(RefModel,'+X^',num2str(i));
                EncModel.XPow=[EncModel.XPow; 1];
            else
                EncModel.XPow=[EncModel.XPow; 0];
            end
        end
    end

    if sum(EncModel.XPow)>1
        %% Here, we check History (Out-1)
        % perform encoder
        for n=1:Ns
            temp = [0; Out{n}(1:end-1)];
            tmpIn{n}=[RefIn{n} temp];
        end
        tmpParam = ay_encoder(model,tmpIn,Out);
        % run the test
        if test==1 %F-test
            n    = size(tmpIn{1},1)*Ns;
            Dm   = tmpParam.Deviance(1);
            Disp = tmpParam.Dispersion(1);
            Dm0  = RefParam.Deviance(1);
            pret = fcdf((Dm0-Dm)/Disp,1,n-tmpParam.Len,'upper');
            if pret < pVal
                % Update model
                RefParam = tmpParam;
                RefIn    = tmpIn;
                RefModel = strcat(RefModel,'+Y(-1)');
                EncModel.YPrv=1;
            end
        end
        if test==2 %BIC
            RefBIC = RefParam.BIC;
            tmpBIC = tmpParam.BIC;
            if tmpBIC < RefBIC
                % Update model
                RefParam = tmpParam;
                RefIn    = tmpIn;
                RefModel = strcat(RefModel,'+Y(-1)');
                EncModel.YPrv=1;
            end
        end
    end
end

if seq_model == 4    % Just X
    % We assume the reference model is 1
    for n=1:Ns
        RefIn{n}= ones(m,1);
    end
    RefParam = ay_encoder(model,RefIn,Out);
    RefModel = '1';
    EncModel.XPow = [1];
    EncModel.YPrv = 0;
    EncModel.Aux  = [];
    %% Here, we build possible input
    for i=1:p_order
        % perform encoder
        for n=1:Ns
            tmpIn{n}    = [RefIn{n} In{n}.^i];
        end
        tmpParam = ay_encoder(model,tmpIn,Out);
        % run the test
        if test==1 %F-test
            n    = size(tmpIn{1},1)*Ns;
            Dm   = tmpParam.Deviance;
            Disp = tmpParam.Dispersion;
            Dm0  = RefParam.Deviance;
            pret = fcdf((Dm0-Dm)/Disp,1,n-tmpParam.Len,'upper');
            if pret < pVal
                % Update model
                RefParam= tmpParam;
                RefIn   = tmpIn;
                RefModel=strcat(RefModel,'+X^',num2str(i));
                EncModel.XPow=[EncModel.XPow; 1];
            else
                EncModel.XPow=[EncModel.XPow; 0];
            end
        end
        if test==2 %BICay
            RefBIC = RefParam.BIC;
            tmpBIC = tmpParam.BIC;
            if tmpBIC < RefBIC
                % Update model
                RefParam= tmpParam;
                RefIn   = tmpIn;
                RefModel=strcat(RefModel,'+X^',num2str(i));
                EncModel.XPow=[EncModel.XPow; 1];
            else
                EncModel.XPow=[EncModel.XPow; 0];
            end
        end
    end
end
if seq_model == 5    % Start with the largest and shrink the model
    % We assume the reference model is 1+x+x^2+x^3+x^4
    % We assume model order is set to be 5
    RefModel = '1';
    for n=1:Ns
        temp = ones(m,1);
        for i=1:p_order
             temp = [temp In{n}.^i];
             if n==1
                RefModel = strcat(RefModel,['+X^' num2str(i)]);
             end
        end
        RefIn{n} = temp;
    end
    RefParam = ay_encoder(model,RefIn,Out);
    EncModel.XPow = ones(1,p_order+1);
    EncModel.YPrv = 0;
    EncModel.Aux  = [];

    %% Here, we build possible input
    for i=p_order:-1:1
        % perform encoder
        for n=1:Ns
            tmpIn{n}  = RefIn{n}(:,1:i);
        end
        tmpParam = ay_encoder(model,tmpIn,Out);
        % run the test
        if test==1 %F-test
            n    = size(tmpIn{1},1)*Ns;
            Dm   = RefParam.Deviance;
            Disp = RefParam.Dispersion;
            Dm0  = tmpParam.Deviance;
            pret = fcdf((Dm0-Dm)/Disp,1,n-tmpParam.Len,'upper');
            if pret > pVal
                % Update model
                RefParam = tmpParam;
                RefIn    = tmpIn;
                RefModel = '1';
                for t=1:i-1
                    RefModel = strcat(RefModel,'+X^',num2str(t));
                end
                EncModel.XPow =EncModel.XPow(1:i);
            else
                break;
            end
        end
        if test==2 %BICay
            RefBIC = tmpParam.BIC;
            tmpBIC = RefParam.BIC;
            if tmpBIC > RefBIC
                % Update model
                RefParam= tmpParam;
                RefIn   = tmpIn;
                RefModel= '1';
                for t=1:i-1
                    RefModel = strcat(RefModel,'+X^',num2str(t));
                end
                EncModel.XPow =EncModel.XPow(1:i);
            else
                break;
            end
        end
    end
end
if seq_model == 6    % Start with the largest and shrink the model
    % We assume the reference model is 1+x+x^2+x^3+x^4
%     p_order = 1;
%     % We assume model order is set to be 5
%     RefModel = '1';
%     for n=1:Ns
%         temp = ones(m,1);
%         for i=1:p_order
%              temp = [temp In{n}.^i];
%              if n ==1
%                 RefModel = strcat(RefModel,['+X^' num2str(i)]);
%              end
%         end
%         RefIn{n} = temp;
%     end
%     RefParam      = ay_encoder(model,RefIn,Out);
%     EncModel.XPow = ones(1,p_order+1);
%     EncModel.YPrv = 0;
%     EncModel.Aux  = [];
    for n=1:Ns
        RefIn{n}= [ones(m,1) In{n}];
    end
    RefParam = ay_encoder(model,RefIn,Out);
    RefModel = '1';
    EncModel.XPow = 1;
    EncModel.YPrv = 0;
    EncModel.Aux  = [];
    
    if pVal == 0.01;
        scale=2.58;
    end
    if pVal == 0.05;
        scale=1.96;
    end
    if pVal == 0.001;
        scale=3;
    end
    w_up  = RefParam.W(2)+scale*RefParam.W_SE(2)*sqrt(Ns);
    w_low = RefParam.W(2)-scale*RefParam.W_SE(2)*sqrt(Ns);
    sig_term = (w_up >0 && w_low > 0) || (w_up <0 && w_low < 0);
    if sig_term
         RefModel=strcat(RefModel,'+X^');
         EncModel.XPow=[EncModel.XPow 1];
    end
    
end
if seq_model == 7    % Just X
    % We assume the reference model is 1
    for n=1:Ns
        RefIn{n}= [ones(m,1) In{n}];
    end
    RefParam = ay_encoder(model,RefIn,Out);
    RefModel = '1';
    EncModel.XPow = 1;
    EncModel.YPrv = 0;
    EncModel.Aux  = [];
    %% Here, we build possible input
    if pVal == 0.01;
        scale=2.58;
    end
    if pVal == 0.05;
        scale=1.96;
    end
    if pVal == 0.001;
        scale=3;
    end
    w_up  = RefParam.W(2)+scale*RefParam.W_SE(2)*sqrt(Ns);
    w_low = RefParam.W(2)-scale*RefParam.W_SE(2)*sqrt(Ns);
    sig_term = (w_up >0 && w_low > 0) || (w_up <0 && w_low < 0);
    if sig_term
        EncModel.XPow = ones(1,2);
        EncModel.YPrv = 0;
        EncModel.Aux  = [];
        RefModel=strcat(RefModel,'+X^');
        r2_base = RefParam.R2;

        for i=2:p_order
            % perform encoder
            for n=1:Ns
                tmpIn{n}    = [RefIn{n} In{n}.^i];
            end
            tmpParam = ay_encoder(model,tmpIn,Out);
            if tmpParam.R2 > r2_base
                RefParam= tmpParam;
                RefIn   = tmpIn;
                RefModel=strcat(RefModel,'+X^',num2str(i));
                EncModel.XPow=[EncModel.XPow 1];
                r2_base = tmpParam.R2;
            else
                EncModel.XPow=[EncModel.XPow 0];
                break;
            end
        end
    else
%         for n=1:Ns
%             RefIn{n}= [ones(m,1)];
%         end
%         RefParam = ay_encoder(model,RefIn,Out);
%         RefModel = '1';
%         EncModel.XPow = 1;
%         EncModel.YPrv = 0;
%         EncModel.Aux  = [];
    end
end
%% The Ref Math has the model
EncModel.AuxInd  = AuxInd(EncModel.Aux);
RefParam.RefModel= RefModel;
RefParam.EncModel= EncModel;

