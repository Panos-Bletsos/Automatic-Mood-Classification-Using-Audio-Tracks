function [S,C,D] = score_chord_id(T,R,Tisharte,Risharte,ruleset,sysoffst)
% [S,C,D] = score_chord_id(T,R,Tisharte,Risharte,ruleset,sysoffst)
%     Score chord recognition systems.  
%     T is the test data (system output), R is the reference
%     (truth) data.  
%     T and R can be any of:
%      - single two-column arrays with the first column the start
%        time (in secs) and the second col the label (e.g. 0..24)
%      - a string containing the name of a file in this format
%      - a cell array consisting of multiple file name strings,
%        paired between T and R.
%     S returns as the overall accuracy (between 0 and 1); C
%     returns a confusion matrix (e.g. 25 x 25)
%     <isharte> nonzero means data files are <start> <end>
%     <asciilabel> instead of <start> <chord0..24>
%     <sysoffst> is added to all system times before scoring.
%     D returns per-track accuracies
% 2008-08-24 Dan Ellis dpwe@ee.columbia.edu

if nargin < 3;    Tisharte = 0;  end
if nargin < 4;    Risharte = Tisharte; end
if nargin < 5;    ruleset = 0; end
if nargin < 6;    sysoffst = 0; end

% Normalize input formats
% If they are single filenames (or data matrices), 
% make them one-element cell arrays
if ~iscell(T)  tmp = T;  T = cell(1,1);  T{1} = tmp;  end
if ~iscell(R)  tmp = R;  R = cell(1,1);  R{1} = tmp;  end

npmodels = 3;
nchroma = 12;
nlabels = npmodels * nchroma + 1;

C = zeros(nlabels, nlabels);

D = zeros(1,length(T));

NOCHORD = 0;

for i = 1:length(T)
  TT = T{i};
  RR = R{i};
  % If they are filenames, just read in the data
  if Tisharte == 0
    if isstr(TT)   TT = readmatti(TT);  end
  else
    if isstr(TT)   TT = readharte(TT);  end
  end
  if Risharte == 0
    if isstr(RR)   RR = readmatti(RR, ruleset);  end
  else
    if isstr(RR)   RR = readharte(RR, ruleset);  end
  end

  % apply sysoffst
  TT(:,1) = TT(:,1)+sysoffst;
  
  % Now the main routine: TT and RR are two <start time> <label> 
  % streams.  Calculate their total times in each pair of states
  alltimes = unique(sort([TT(:,1)',RR(:,1)']));
  
  % track error in this one track too
  CC = 0;
  EE = 0;
  % We ignore the final symbol since we don't have an end time for it
  for j = 1:length(alltimes)-1
    thistime = alltimes(j);
    nexttime = alltimes(j+1);
    segdur = nexttime - thistime;
    Tsym = lookup(TT,thistime,NOCHORD);
    Rsym = lookup(RR,thistime,NOCHORD);

    % update confusion matrix with this amount of time
    C(1+Rsym,1+Tsym) = C(1+Rsym,1+Tsym) + segdur;
  
    if Tsym == Rsym
      if Tsym ~= NOCHORD
        CC = CC + segdur;
      end
    else
      EE = EE + segdur;
    end
    
  end
  
  D(i) = CC/(CC+EE);
  
end

% Actual accuracy %.  
% Exclude regions where both streams report No Chord (e.g. lead
% in/lead out)

XX = C(NOCHORD+1, NOCHORD+1);

S = (sum(diag(C))-XX) / (sum(C(:))-XX);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function L = lookup(D,T,NOCHORD)
% L = lookup(D,T,NOCHORD)
%    D is a set of rows <starttime> <label>
%    Find the interval D(i,1) <= T && D(i+1,1) > T
%    and return L = D(i,2)
%    return NOCHORD if no match
% 2008-08-24 Dan Ellis dpwe@ee.columbia.edu

% Make sure there is a zero entry, but return special symbol if it's used
% (will be superceded by a real zero entry)


D = [[0,NOCHORD];D];
%D = [D;[inf,NOCHORD]];  % never needed by design

L = D(max(find(D(:,1)<=T)),2);

