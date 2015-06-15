function r = mymkdir(dir)
% r = mymkdir(dir)
%   Ensure that dir exists by creating all its parents as needed.
% 2006-08-06 dpwe@ee.columbia.edu

r = 0;

if length(dir) == 0
  return;
end

[x,m,i] = fileattrib(dir);
if x == 0
  [pdir,nn] = fileparts(dir);
  disp(['creating ',dir,' ... ']);
  r = mymkdir(pdir);
  % trailing slash results in empty nn
  if length(nn) > 0
    if length(pdir) == 0
      pdir = pwd;
    end
    mkdir(pdir, nn);
    r = 1;
  end
end
