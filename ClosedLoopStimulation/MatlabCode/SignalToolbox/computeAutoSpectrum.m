function [Sxx, Xx, F]= computeAutoSpectrum(x,win,nfft,Fs)



% Window the data
xw = bsxfun(@times,x,win);

% Compute the periodogram power spectrum [Power] estimate
% A 1/N factor has been omitted since it cancels

[Xx,F] = computeDFT_FreqBin_EML(xw,nfft,Fs);

%U = sum(win)^2; % bacuse we want ms: if any(strcmpi(esttype,{'ms','power'}))
U = win'*win;

Sxx = Xx.*conj(Xx)/U;                % Auto spectrum.
%Sxx = Xx.*conj(Xx);                % Auto spectrum. - U cancels out in coherence

  %Pxy = bsxfun(@times,Xx,conj(Yy))/U;  % Cross spectrum.  % We use bsxfun here because Yy can be a single vector or a matrix


