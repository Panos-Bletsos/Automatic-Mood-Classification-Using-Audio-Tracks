function A = num2keyname(N,S)
% A = num2keyname(N,S)
%   Convert a vector of 0..24 or 36 chord indices into a cell array of
%   names.  0 = N.
%   S = 1 means use short names (g instead of G:min).
% 2009-09-25 Dan Ellis dpwe@ee.columbia.edu

if nargin < 2
  S = 0;
end

keytab = {'N', ...
          'C:maj','C#:maj','D:maj','D#:maj','E:maj','F:maj', ...
          'F#:maj','G:maj','G#:maj','A:maj','A#:maj','B:maj', ...
          'C:min','C#:min','D:min','D#:min','E:min','F:min', ...
          'F#:min','G:min','G#:min','A:min','A#:min','B:min', ...
          'C:7','C#:7','D:7','D#:7','E:7','F:7', ...
          'F#:7','G:7','G#:7','A:7','A#:7','B:7' };

keytabshort = {'N', ...
          'C','C#','D','D#','E','F', ...
          'F#','G','G#','A','A#','B', ...
          'c','c#','d','d#','e','f', ...
          'f#','g','g#','a','a#','b', ...
          'C7','C#7','D7','D#7','E7','F7', ...
          'F#7','G7','G#7','A7','A#7','B7' };


NOCHORD = 0;

if S == 1
  keytab = keytabshort;
end

for i = 1:length(N)
  A(i) = keytab(1+N(i));
end


%keytab = {'C','C#','D','D#','E','F','F#','G','G#','A','A#','B', ...
%          'c','c#','d','d#','e','f','f#','g','g#','a','a#','b', ...
%          'X'};
%
%keyalt = {'C','Db','D','Eb','E','F','Gb','G','Ab','A','Bb','B', ...
%          'c','db','d','eb','e','f','gb','g','ab','a','bb','b', ...
%          'N'};
%
%nN = length(N);
%
%for i = 1:nN
%
%  A(i) = keytab(1+N(i));
%
%end


  