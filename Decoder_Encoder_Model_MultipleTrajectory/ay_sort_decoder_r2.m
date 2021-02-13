function [feature_map,rmse_curve,optim_mX,winner_list] = ay_sort_decoder_r2(X,Y,valid,test_ind)
% first find valid features
f_ind = find(valid);
% feature subset
yf  = Y(f_ind,test_ind);
% x train set
x_train = X(:,test_ind);
% x test set

%% Find the best set of features
Prb     = TProb(find(valid));
[ls,lx] = size(Prb{1}.prb);
no_feature   = length(Prb);
feature_ind  = find(valid);
prev_winner  = ones(no_feature,1);
rmse_curve   = zeros(no_feature,1);
optim_mX     = zeros(no_feature,ls);


prv_ind  = find(prev_winner>0);
base_prb = zeros(ls,lx);
for j=1:length(prv_ind)
        base_prb = base_prb + log(realmin+Prb{prv_ind(j)}.prb);
end
cur_prb  = exp(base_prb);
% now normalize
for k=1:ls
     cur_prb(k,:)=cur_prb(k,:)/max(realmin,sum(cur_prb(k,:)));
end
% now calculate means
mX  = cur_prb*Xs';
err = 0;
for k=1:size(Xm,1)
        err = err + sum((mX'-Xm(k,:)).^2);
        %err = err + sum(abs(mX'-Xm(k,:)));
end
rmse_curve(end)  = sqrt(err/numel(Xm));
     

for i= no_feature:-1:2
    % define base prob
    prv_ind  = find(prev_winner>0);
    base_prb = zeros(ls,lx);
    for j=1:length(prv_ind)
        base_prb = base_prb + log(realmin+Prb{prv_ind(j)}.prb);
    end
    % now, check which should be added
    check_ind = find(prev_winner==1);
    rmse      = zeros(length(check_ind),1);
    tmp_mX    = zeros(length(check_ind),ls);
    for j=1:length(check_ind)
        % build the overal distribution
        cur_prb  = base_prb - log(realmin+Prb{check_ind(j)}.prb);
        cur_prb  = exp(cur_prb);
        % now normalize
        for k=1:ls
            cur_prb(k,:)=cur_prb(k,:)/max(realmin,sum(cur_prb(k,:)));
        end
        % now calculate means
        mX  = cur_prb*Xs';
        tmp_mX(j,:)=mX';
        err = 0;
        for k=1:size(Xm,1)
            err = err + sum((mX'-Xm(k,:)).^2);
            %err = err + sum(abs(mX'-Xm(k,:)));
        end
        rmse(j)  = sqrt(err/numel(Xm)); 
    end
    % find min and put in the list
    [~,min_ind] = min(rmse);
     prev_winner(check_ind(min_ind)) = i-no_feature-1 ;
     % regenerate again
     prv_ind  = find(prev_winner>0);
     base_prb = zeros(ls,lx);
     for j=1:length(prv_ind)
            base_prb = base_prb + log(realmin+Prb{prv_ind(j)}.prb);
     end
     cur_prb  = exp(base_prb);
     % now normalize
     for k=1:ls
         cur_prb(k,:)=cur_prb(k,:)/max(realmin,sum(cur_prb(k,:)));
     end
     % now calculate means
     mX  = cur_prb*Xs';
     err = 0;
     for k=1:size(Xm,1)
            err = err + sum((mX'-Xm(k,:)).^2);
            %err = err + sum(abs(mX'-Xm(k,:)));
     end
     rmse_curve(i-1)  = sqrt(err/numel(Xm));
     optim_mX(i-1,:)  = mX';
end

feature_map = cell(no_feature,1);
for i= no_feature:-1:1
    ind = find(prev_winner<=i-no_feature);
    feature_map{i}=feature_ind(ind);
end
winner_list = prev_winner + length(prev_winner)+1;