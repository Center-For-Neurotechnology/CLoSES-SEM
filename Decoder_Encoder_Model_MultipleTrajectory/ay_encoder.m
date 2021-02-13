function Param =ay_encoder(model,In,Out)
%% Mode
% mode==1, it means batch
% mode==2, it means sampling mode

%% GLM
% model==1, Gamma with exponential link function
% model==2, Log-Normal with identity link function

%% Input and Output
% In (struct, each element is an array of the input) 
% Output (struct, each element is an array of the output - it is an scalar)
%% Recursive Mode
   options=optimset('Display','off');
   % Find parameters per input
   Ns  = length(In);
   Ps  = size(In{1},1);
   
     
   if model==1      % Gamma
        fit_model  = fit_gamma_glm();
        yhat       = predict_gamma(fit_model);
        
        Param.W    = fit_model.Coefficients.Estimate';
        Param.Len  = length(Param.W)+1;
        Param.C    = fit_model.CoefficientCovariance;
        Param.W_SE   = fit_model.Coefficients.SE;
        Param.Dispersion = fit_model.Dispersion;
        Param.Deviance   = fit_model.Deviance;
        Param.BIC        = fit_model.ModelCriterion.BIC;
        Param.R2         = fit_model.Rsquared.Ordinary;
        Param.Y = yhat;
        
   end
   if model==2     % Log Normal
        fit_model  = fit_normal_glm();
        yhat   = predict_normal(fit_model);
        
        Param.W    = fit_model.Coefficients.Estimate';
        Param.Len  = length(Param.W)+1;
        Param.C    = fit_model.CoefficientCovariance;
        Param.W_SE   = fit_model.Coefficients.SE;
        Param.Dispersion = fit_model.Dispersion;
        Param.Deviance   = fit_model.Deviance;
        Param.BIC        = fit_model.ModelCriterion.BIC;
        Param.R2         = fit_model.Rsquared.Adjusted;
        Param.Y = yhat;
   end
   
    function mdl = fit_normal_glm()
        cInX = [];
        cOutX= [];
        for n=1:Ns
            cInX  = [cInX;In{n}];
            cOutX = [cOutX;Out{n}];
        end
        mdl  = fitglm(cInX,cOutX,'Distribution','Normal','link','identity','Intercept',false);
    end
    function mdl = fit_gamma_glm()
        cInX = [];
        cOutX= [];
        for n=1:Ns
            cInX  = [cInX;In{n}];
            cOutX = [cOutX;Out{n}];
        end
        mdl = fitglm(cInX,cOutX,'Distribution','Gamma','link','log','Intercept',false);
    end
    function fn=predict_gamma(fit_model)
        fn = zeros(Ns,Ps);
        for n=1:Ns
            fn(n,:) = feval(fit_model,In{n});
        end
    end
    function fn=predict_normal(fit_model)
        fn = zeros(Ns,Ps);
        for n=1:Ns
            fn(n,:) = feval(fit_model,In{n});
        end
    end
end