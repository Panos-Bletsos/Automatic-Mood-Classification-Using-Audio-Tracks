function [X_data,B] = loadftrs_mirex_svm(A,lowchroma,nflag,pflag,qflag,train12fold,maxframes)
% [X_data,B] = loadftrs_mirex_svm(A,use100,nflag,pflag,qflag,train12fold,maxframes)
%     Read in features for data items defined by a file or cell
%     list - version for SVMstruct classifier.
%     A is the name of a list file defining a set of tracks
%     (or a cell array containing all the file ID strings).
%     X_data returns svmhmm format cell structure with the processed features
%
%     F returns as one 12xN matrix of chroma features
%     B returns the beat times within each block.
%
%     maxframes truncates individual files to the first <maxframes> frames.
% 2008-08-11 Dan Ellis dpwe@ee.columbia.edu
% 2009-09-19 modified by Adrian Weller aw2506@columbia.edu

if nargin<7; maxframes = 0; end
if nargin<6; train12fold=0; end
if nargin<5; qflag=0; end
if nargin<4; pflag=0; end
if nargin<3; nflag=0; end
if nargin<2; lowchroma=0; end

% optional common filename prefix
dataroot = '';

% Exponent for calculating norm in chromnorm. Inf => norm by max
% for -100 features
lownormp = 2.0;
lowpwr = 0.26;
% Don't ask me.  These ones work best for beatles 4-way

if iscell(A)
  trks = A;
else
  trks = listfileread(A);
end

ntrks = length(trks);
%F = []; 
B = [];
%T = [];

key = 0;

clear X_data;

for i=1:ntrks; 

  fn = fullfile(dataroot, trks{i});
  FF=load(fn);
  nframes = length(FF.bts);
  if (maxframes > 0) && (nframes > maxframes)
    nframes = maxframes;
  end
  for shift = 0:(11*train12fold)
    X1=PreProcessFeats(chromrot2(FF.F(:,1:nframes),shift),FF.bts(1:nframes),nflag,pflag,qflag,key);
    if lowchroma > 0
      % convert "-400" into "-100"
      fn2 = fn;
      fn2(max(find(fn2=='4'))) = '1';
      FF2=load(fn2);
      if lowchroma > 1
	%% for models 11,12,13
	X2 = PreProcessFeats(chromrot2(FF2.F(:,1:nframes),shift),FF2.bts(1:nframes),nflag,pflag,qflag,key);
	X1 = [X1;X2];
      else
	%% for everything except models 11,12,13
	f2 = chromnorm(chrompwr(chromrot(FF2.F(:,1:nframes), key+shift), lowpwr), lownormp);
	X1 = [X1;f2];
      end
    end
  end
  X_data{i}=X1'; %transpose for SVMstruct convention
 
  B = FF.bts(1:nframes); %Really just used when there's one test file being examined

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [G] = PreProcessFeats(F,bts,nflag,pflag,qflag,key) %standardize/whiten?
%[G] = PreProcessFeats[F,bts,nflag,pflag,qflag]
%>>In version 3 here, we don't transpose at the end
%F is the song features vector, 12*no. frames
%bts is the frame times 1*no. frames
%qflag~=0 -> add quadratic terms; default is 0. >1=>leave last qflag
%(prev frames go before next frames, if any)
%nflag=0,1,2,3 -> add that many next frames' features
%pflag=0,1,2,3 -> add that many previous frames' features
%Here we handle chroma normalization per Dan
%but also add pre and post features as per Tony
%can add diff of beat times as a feature
%transpose for SVMstruct convention
%v2 uses diff sequence of variables to previous, so kept that unchanged

if nargin<5; qflag=0; end
if nargin<4; pflag=0; end
if nargin<3; nflag=0; end
if nargin < 6;  key = 0;  end

% Exponent for calculating norm in chromnorm. Inf => norm by max
%normp = Inf;  
normp = 2;  
% Compressive exponent
%pwr = 0.17;  % closely optimized for Beatles
pwr = 0.25;  % default

N = length(bts);
G = chromnorm(chrompwr(chromrot(F, key), pwr), normp);

prev=G(:,[1 1:(N-1)]); %repeat first frame at start
prev2=prev(:,[1 1:(N-1)]);
prev3=prev2(:,[1 1:(N-1)]);
next=G(:,[2:N N]); %and repeat last frame at end
next2=next(:,[2:N N]);
next3=next2(:,[2:N N]);

%diffbts=bts-bts([1 1:(N-1)]); %first elt is 0 then diff from prev to this beat
%diffbts(1)=mean(diffbts); %guessing this will cause less trouble
%diffbts2=bts-bts([1 1 1:(N-2)]); 
%diffbts2(1)=mean(diffbts2); diffbts2(2)=mean(diffbts2); 

%diffbtsfwd=bts([2:N N])-bts;
%diffbtsfwd(N)=mean(diffbtsfwd);
%diffbtsfwd2=bts([3:N N N])-bts;
%diffbtsfwd2(N)=mean(diffbtsfwd2); diffbtsfwd2(N-1)=mean(diffbtsfwd2);

%G=[G ; diffbts ; prev; diffbts2; prev2; diffbtsfwd; next; diffbtsfwd2; next2]; %put all the pieces together

if pflag %add prev frames' features
    if pflag==1
        G=[G; prev];
    else if pflag==3
            G=[G; prev; prev2; prev3];
        else
            G=[G; prev; prev2];
        end
    end
end

if nflag %add next 2 frames' features
    if nflag==1
        G=[G; next];
    else if nflag==3
            G=[G; next; next2; next3];
        else
            G=[G; next; next2];
        end
    end
end

if qflag %add quadratic terms
    if qflag>1 %leave out last qflag terms. previous 9 is equiv to new 12
        last12=G(end-(qflag-1):end,:);
        first=G(1:end-qflag,:);
        G=[addquadterms(first); last12];
    else
        G=addquadterms(G); %so do all of them if qflag=1
    end
end

%G=[G; diffbtsfwd; diffbtsfwd2]; tack these on at end
        
%G=G'; %transpose for SVMstruct convention
end


end