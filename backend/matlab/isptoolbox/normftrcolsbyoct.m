function [Y,U,V,M] = normftrcolsbyoct(X,W)
% [Y,U,V,M] = normftrcolsbyoct(X,W)
%   X is spectrogram-like data.  Use a moving average of W octaves 
%   wide to calculate mean and variance, then subtract/divide them 
%   out.  U returns the per-point moving average, and V the stddev.
%   M returns the weighting matrix (each row gives weights for one 
%   output row).
% 2010-07-06 Dan Ellis dpwe@ee.columbia.edu

% make the weighting matrix

[nr, nc] = size(X);

M = zeros(nr, nr);

xx = 0:(nr-1);

lxx = log(1:(nr-1))/log(2);
lxx = [lxx(1) lxx];

%for i = 1:nr
%	ww = (max(1,W*(i-1))).^2;
%	%M(i,:) = exp(-0.5*((xx - (i-1)).^2)/ww);
%	M(i,:) = exp(-0.5*(((lxx - lxx(i))/W).^2));
%end

M = exp(-0.5*(((repmat(lxx,nr,1)-repmat(lxx',1,nr))/W).^2));

%Y = M; return

U = diag(1./sum(M,2))*(M*X);
%X = X-U;
V = sqrt(diag(1./sum(M,2))*(M*(X.^2)));
Y = X./V;
