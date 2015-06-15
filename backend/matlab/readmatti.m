function [T,L] = readmatti(X,R)
% [T,L] = readmatti(X,R)
%    Read the Matti-format chord label file X 
%    and return its contents in T (start times) and L (chord index,
%    0..24, 24 = no chord).  
%    If L is omitted, return T as a two-column matrix of 
%    [time labelix] rows.
%    R specifies the ruleset (0,1,2) but is currently ignored.
% 2009-10-02 Dan Ellis dpwe@ee.columbia.edu

[ts,lx] = textread(X,'%f %f');

NOCHORD=24;

if lx(end) ~= NOCHORD
  ts = [ts;2*ts(end)-ts(end-1)];
  lx = [lx;NOCHORD];
end

if nargout == 1
  T = [ts,lx];
elseif nargout > 1
  T = ts;
  L = lx;
end

