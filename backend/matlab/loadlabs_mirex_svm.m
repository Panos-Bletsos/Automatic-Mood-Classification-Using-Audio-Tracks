function [Y_data,L,T] = loadlabs_mirex_svm(A,train12fold,maxframes)
% [Y_data,L,T] = loadlabs_mirex_svm(A,train12fold,maxframes)
%     Read in labels for data items defined by a file or cell list
%     - version for SVMstruct classifier.
%     A is the name of a list file defining a set of tracks
%     (or a cell array containing all the file ID strings).
%     L returns as one 1xN matrix of label indices.
%     T is a vector of the start frames of each individual track.
%     maxframes truncates individual files to the first <maxframes> frames.
% 2008-08-11 Dan Ellis dpwe@ee.columbia.edu
% 2009-09-19 modified by Adrian Weller aw2506@columbia.edu
% now makes Y_data labels suitable for SVM-HMM

if nargin<2; train12fold=0; end
if nargin<3; maxframes = 0; end

% optional common filename prefix
dataroot = '';

if iscell(A)
  trks = A;
else
  trks = listfileread(A);
end

ntrks = length(trks);
F = []; 
L = [];

for i=1:ntrks; 
  LL=load(fullfile(dataroot, trks{i}));
  %L=[L;LL.L];
  %T(i) = size(LL,2);
  nframes = length(LL.L);
  if (maxframes > 0) && (nframes > maxframes)
    nframes = maxframes;
  end
  for shift=0:(11*train12fold)
    index=i+shift*ntrks;
    Y_data{index}=ShiftLabs(LL.L(1:nframes),shift);
  end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [M] = ShiftLabs(L,shift)
%[M] = ShiftLabs[L,shift]
%L is the raw song labels vector (1-25 format), no. frames * 1
%shift is the number of semitones to shift, 1-11

NOCHORD = 0;
nochords = find(L==NOCHORD);
M = 1 + 12*(floor((L-1)/12)) + rem(L-1+12-shift, 12);
M(nochords) = NOCHORD;


%N=length(L);
%M=zeros(N,1);
%for i=1:N
%    M(i)=ShiftLab(L(i),-shift); %see how this goes, may need -shift; yes -shift seems right
%end   
%end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [y] = ShiftLab(x,s)
%%1-12 major, 13-24 minor, 25 nothing
%if x>24
%    y=x;
%elseif x<13
%    y=x+s-12*(x+s>12)+12*(x+s<1);
%else y=x+s-12*(x+s>24)+12*(x+s<13);
%end
%end
