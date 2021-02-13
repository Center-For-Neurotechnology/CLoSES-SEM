function [coherenceValue] = runCoherence_MatrixForm_NoDownsampling_EML(filteredData, lowFreq, highFreq, Fs, detectPairInds, overlapSamples)
%#codegen
% Returns magnitude-square coherence averaged across channels.
% Coherence is computed between pairs of channels for the whole time window in the specified frequency bins
% Run mscohere in filteredData
% Could probably be made quicker by computing only Pxy (cross PSD) instead of coherence

%Inputs:
%   1. filteredData time x channels matrix with data from which to compute coherence
%   2. freqBins: specify frequencies of interest (to avoid computing coherence in whole spectrum)
%   3. Fs: Sampling Frequency
%
%Output:
%   1. magnitude-square coherence. diagonal is 1 as it is the coherence of channels with themselves.
%coder.extrinsic('tic');
%coder.extrinsic('toc');
%coder.extrinsic('num2str');

%Lots of persistent data to make faster (they only need to be computed once -> perhaps could be taken out)
persistent lenDataPrev win;
persistent tSamples;
persistent coherenceValuePersist;

% CONFIG
nFreqs = 4; % RIZ: This is really the number of points of interest t FIX because it is needed for simulink real time!
nChannels = size(filteredData,2);

% If it is the first time or if sel Channels changed, assign value to persistent variables
if isempty(tSamples), tSamples=0; end 

% Initialize variable size
nPairs =  nChannels * (nChannels-1) /2;
%pairChannels = zeros(1, nPairs);

if isempty(coherenceValuePersist), coherenceValuePersist= zeros(1, nPairs); end

%Create list of pairs and get channels of detected pairs
[pairChannels, detectChannInds] = getPairsAndDetectedChannels([1:nChannels],detectPairInds) ;

coherenceValueAllFreqs = zeros(nFreqs/2+1, nPairs);
coherenceValue = zeros(1, nPairs);

% If there is NO data -> return
if sum(filteredData(:))==0 || ~all(size(filteredData)>1) 
    return;
end


% Only compute once per interval
if mod(tSamples,overlapSamples)>0
    coherenceValue = coherenceValuePersist; % hold previous values
    tSamples = tSamples +1;
    return;
end
tSamples = tSamples +1;

%Only keep data of interest

filteredDataToUse = filteredData; %downsample(filteredData,25); %round(Fs/(highFreq*10))); % keep 10 times highest frequency (could be less)
lenData = size(filteredDataToUse,1);

if isempty(lenDataPrev), lenDataPrev = lenData; end
%Configuration (modified in part from pwelchparse
L = fix(fix(lenData./5)*2);    %ONLY 4 sections to reduce time! %fix(lenData./4.5);    % 8 sections
if isempty(lenData)|| isempty(win) || lenData~=lenDataPrev
    win = hamming(L,'periodic'); % use Hamming window
    lenDataPrev = lenData;
end

noverlap = fix(0.5.*L); % 50% overlap
% Compute the number of segments
k = round((lenData-noverlap)./(L-noverlap));
LminusOverlap = L-noverlap;
xStart = 1:LminusOverlap:k*LminusOverlap;
xEnd   = xStart+L-1;
freqBins = linspace(lowFreq, lowFreq+highFreq, nFreqs);
options.nfft = freqBins; %RIZ: DO NOT CHANGE! - only FFT method can be used in simulink real time and I had to hardcode NFFT=32 in computeDFT_FFT_EML.m!!! freqBins; %At which frequenceies to compute periodogram
options.Fs = Fs;

% ******** Compute Coherence **********
%Initialize variables (needed for Simulink real-time)
    nDetChannels = length(detectChannInds);

    Pxx = zeros(nFreqs/2+1, nChannels);
    PxxTemp = zeros(nFreqs/2+1, nDetChannels);
    Pxy = zeros(nFreqs/2+1, 1);
    coherValPerPair = zeros(nFreqs/2+1, 1);
    Sxx = zeros(nFreqs,nDetChannels,class(filteredDataToUse));
    Sxy = zeros(nFreqs,1,class(filteredDataToUse));
    Xx = complex(zeros(k,nFreqs,nChannels,class(filteredDataToUse)));

    % Compute Spectrum for each channel that corresponds to selected pairs
    cmethod = @plus;
    
    [PxxTemp, XxTemp] = localComputeAutoSpectra(Sxx,filteredDataToUse(:,detectChannInds),xStart,xEnd,win,options,k,cmethod);
    Pxx(:,detectChannInds) = PxxTemp;
    Xx(:,:,detectChannInds) = XxTemp;
    %Pyy = localComputeSpectra(Syy,y,[],xStart,xEnd,win,options,esttype,k,cmethod,freqVectorSpecified);
    % Cross PSD.  The frequency vector and xunits are not used.
    
    for iPair=1:nPairs % Only compute pxy for paris of values!
        if ~isempty(intersect(detectPairInds, iPair)) %Only compute for those pairs that will be used for detection!
            indCh1 = pairChannels(iPair,1);
            indCh2 = pairChannels(iPair,2);
            [Pxy] = localComputeCrossSpectra(Sxy,Xx(:,:,indCh1),Xx(:,:,indCh2),win,options,k,cmethod);
            coherValPerPair = (Pxy.^2)./bsxfun(@times,Pxx(:,indCh1),Pxx(:,indCh2)); % Cxy
            coherenceValueAllFreqs(1:size(Pxy,1), iPair) = coherValPerPair;
            coherenceValue(1,iPair) = mean(coherValPerPair,1);
        end
    end
    % end of code from welch.m
    
    
    coherenceValuePersist = coherenceValue;
    %[psdx, freq] = computePSDusingFFT(x, N, Fs)

end

function [Pxx,Xx,w] = localComputeAutoSpectra(Sxx,x,xStart,xEnd,win,options,k,cmethod)
    w=zeros(length(options.nfft)/2+1, 1);
    Xx=complex(zeros(k,size(Sxx,1),size(Sxx,2)));
    for ik = 1:k
        [Sxxk, Xxk, w]= computeAutoSpectrum(x(xStart(ik):xEnd(ik),:),win,options.nfft,options.Fs);
        
        %[Sxxk,w] = computeperiodogram_EML({x(xStart(ii):xEnd(ii),:)},win,options.nfft,esttype,options.Fs);
        Sxx  = cmethod(Sxx,real(Sxxk));
        Xx(ik,:,:) = Xxk;
    end
    Sxx = Sxx./k; % Average the sum of the periodograms
    [Pxx, w] = computeMeanSquarePower(Sxx, w, numel(options.nfft));
end

function [Pxy] = localComputeCrossSpectra(Sxy,XxCh,YyCh,win,options,k,cmethod)
    for ik = 1:k
        [Sxyk]= computeCrossSpectrumFromXxYy(XxCh(ik,:),YyCh(ik,:),win)';
        %     [Sxxk,w] =  computeperiodogram_EML({x(xStart(i):xEnd(i),:),y(xStart(i):xEnd(i),:)},win,options.nfft,esttype,options.Fs);
        Sxy  = cmethod(Sxy,real(Sxyk));
    end
    Sxy = Sxy./k; % Average the sum of the periodograms
    [Pxy] = computeMeanSquarePower(Sxy, [], numel(options.nfft));
end

function [Sxx, w] = computeMeanSquarePower(Sxx, w, nfft)
   if rem(nfft,2),
      select = 1:(nfft+1)/2;  % ODD
      Sxx_unscaled = Sxx(select,:); % Take only [0,pi] or [0,pi)
      Sxx = [Sxx_unscaled(1,:); 2*Sxx_unscaled(2:end,:)];  % Only DC is a unique point and doesn't get doubled
   else
      select = 1:nfft/2+1;    % EVEN
      Sxx_unscaled = Sxx(select,:); % Take only [0,pi] or [0,pi)
      Sxx = [Sxx_unscaled(1,:); 2*Sxx_unscaled(2:end-1,:); Sxx_unscaled(end,:)]; % Don't double unique Nyquist point
   end
   if ~isempty(w)
       w = w(select);
   end
end

function [psdx, freq] = computePSDusingFFT(x, N, Fs)

    xdft = fft(x);
    xdft = xdft(1:N/2+1);
    psdx = (1/(Fs*N)) * abs(xdft).^2;
    psdx(2:end-1) = 2*psdx(2:end-1);
    freq = 0:Fs/length(x):Fs/2;
end


    %   coherenceValue1 = mscohere(filteredData, filteredData, windowType, noverlap, freqBins, Fs);
    %mscohere is NOT supported by CODER -> we need to compute using FFT
    % Cxy = (Sxy)^2 / (Sxx Syy)
    %coherenceValue = welch({filteredData, filteredData},'mscohere', windowType, noverlap, freqBins, Fs);
    %code modified from welch.m

