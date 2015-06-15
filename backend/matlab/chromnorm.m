function [N,S] = chromnorm(F,P)
% [N,S] = chromnorm(F,P)
%    Normalize each column of a chroma ftrvec to unit norm
%    so cross-correlation will give cosine distance
%    S returns the per-column original norms, for reconstruction
%    P is optional exponent for the norm, default 2.
% 2006-07-14 dpwe@ee.columbia.edu

if nargin < 2;  P = 2;  end

[nchr, nbts] = size(F);

if ~isinf(P)
  S = sum(F.^P).^(1/P);
else
  S = max(F);
end

N = F./repmat(S+(S==0), nchr, 1);
