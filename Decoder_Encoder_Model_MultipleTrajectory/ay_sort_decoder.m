function [feature_ind,rmse_curve,optim_mX] = ay_sort_decoder(TProb,Xs,valid,Xm)
%% Find the best set of features
Prb     = TProb(find(valid));
[ls,lx] = size(Prb{1}.prb);
no_feature   = length(Prb);
feature_ind  = find(valid);
prev_winner  = zeros(no_feature,1);
rmse_curve   = zeros(no_feature,1);
optim_mX     = zeros(no_feature,ls);

for i= 1:no_feature
    % define base prob
    base_prb  = zeros(ls,lx);
    for j=1:i-1
        base_prb = base_prb + log(Prb{prev_winner(j)}.prb);
    end
    % now, check which should be added
    temp_ind = zeros(no_feature,1);
    temp_ind(prev_winner(1:i-1))=1;
    check_ind = find(~temp_ind);
    rmse   = zeros(length(check_ind),1);
    tmp_mX = zeros(length(check_ind),ls);
    for j=1:length(check_ind)
        % build the overal distribution
        cur_prb  = base_prb + log(Prb{check_ind(j)}.prb);
        cur_prb  = exp(cur_prb);
        % now normalize
        for k=1:ls
            cur_prb(k,:)=cur_prb(k,:)/max(eps,sum(cur_prb(k,:)));
        end
        % now calculate means
        mX  = cur_prb*Xs';
        tmp_mX(j,:)=mX';
        err = 0;
        for k=1:size(Xm,1)
            err = err + sum((mX'-Xm(k,:)).^2);
        end
        rmse(j)  = sqrt(err/numel(Xm)); 
    end
    % find min and put in the list
    [min_val,min_ind]= min(rmse);
    prev_winner(i)= check_ind(min_ind);
    rmse_curve(i) = min_val;
    optim_mX(i,:) = tmp_mX(min_ind,:);

end
feature_ind = feature_ind(prev_winner);