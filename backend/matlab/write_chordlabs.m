function write_chordlabs(t,c,fn,isharte)
% write_chordlabs(t,c,fn,isharte)
%    Write chord label file in MIREX/Harte <start> <end>
%    <asciilabel> format.  t is start times, c is 0..24 chord 
%    index, fn is the file name.
%    if isharte == 0, write <starttime> <chord0..24> files
%    else write <start> <end> <chordname> (Chris Harte style).
% 2009-10-02 Dan Ellis dpwe@ee.columbia.edu

if nargin < 4
  isharte = 1;
end

%keytab = {'N', ...
%          'C:maj','C#:maj','D:maj','D#:maj','E:maj','F:maj', ...
%          'F#:maj','G:maj','G#:maj','A:maj','A#:maj','B:maj', ...
%          'C:min','C#:min','D:min','D#:min','E:min','F:min', ...
%          'F#:min','G:min','G#:min','A:min','A#:min','B:min', ...
%          'C:7','C#:7','D:7','D#:7','E:7','F:7', ...
%          'F#:7','G:7','G#:7','A:7','A#:7','B:7' };

NOCHORD = 0;

f = fopen(fn,'w');

if length(t) == length(c)
  % add final time
  t = [t, 2*t(end) - t(end-1)];
end

if t(1) > 0
  if c(1) == NOCHORD
    t(1) = 0;
  else
    % no NOCHORD at the beginning, insert it
    t = [0,t];
    c = [NOCHORD, c];
  end
end

% Add lead-out label
if c(end) ~= NOCHORD
  t = [t, 2*t(end) - t(end-1)];
  c = [c, NOCHORD];
end

% Collapse repeated labels
cdiff = [1,1+find(c(1:end-1) ~= c(2:end))];
c = c(cdiff);
t = [t(cdiff),t(end)];
         
if isharte
  for i = 1:length(c)
    %fprintf(f,'%.3f %.3f %s\n', t(i), t(i+1), char(num2keyname(c(i))));
    %Print only the keyname
    fprintf(f,'%s\n', char(num2keyname(c(i))));
  end
else
  fprintf(f,'%f %d\n',[t(1:length(c));c]);
end
  
fclose(f);
