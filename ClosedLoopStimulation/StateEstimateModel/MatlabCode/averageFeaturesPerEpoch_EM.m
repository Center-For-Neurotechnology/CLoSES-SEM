function featuresPerEpoch = averageFeaturesPerEpoch_EM(featuresAllTimes, nEpochs)
% gets as input features for each time point and returns average per epoch

lenFeatAllTimes = size(featuresAllTimes, 1);
nOrigFeat = size(featuresAllTimes, 2);

lenPerEpoch = floor(lenFeatAllTimes/nEpochs);

avPerEpoch = zeros(nEpochs, nOrigFeat); %size(featuresAllTimes)); %
featuresPerEpoch = zeros(nEpochs* nOrigFeat,1); %size(featuresAllTimes)); %

for iEpoch =1:nEpochs
    indPerEpoch = linspace((iEpoch-1)*lenPerEpoch + 1, iEpoch*lenPerEpoch, min(lenPerEpoch,2000));
    avPerEpoch(iEpoch, 1:nOrigFeat) = mean(featuresAllTimes(indPerEpoch,1:nOrigFeat), 1);
end
featuresPerEpoch = avPerEpoch(:); %reshape(avPerEpoch, [nEpochs* nOrigFeat,1]);

