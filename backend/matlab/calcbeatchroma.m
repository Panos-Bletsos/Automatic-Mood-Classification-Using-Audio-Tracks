function [opfiles,semisoffs] = calcbeatchroma(listfile,srcprepend,srcext, ...
                                  dstprepend,dstext,skip,fctr,fsd, ...
                                  tmean, tsd, ...
                                  exceptions)
% [fl,so]=calcbeatchroma(listfile,srcprepend,srcext,dstprepend,dstext,skip,fctr,fsd,tmean,tsd,exceptions,dgth,whiwin)
%   Take listfile, a list of input MP3 or WAV files and calculate 
%   beat-synchronous chroma features for each one. 
%   input file names each have srcprepend prepended and srcext appended;
%   features are written to .mat files with the same root name but
%   with dstprepend prepended and dstext appended.  First <skip>
%   items are skipped (for resumption of interrupted runs).
%   fctr and fsd specify a spectral window used to extract chroma 
%   elements with center at fctr Hz, and gaussian log-F half-width
%   of fsd octaves.
%   exceptions is key/value array of predefined mistuning results.
%   dgth is IF diff threshold for ifchromagram (default 0.5).
%   whiwin is a magnitude whitening window in octaves (default 0 = none).
%   Return a cell array of the output files written, and vector of
%   measured tuning offsets.
% 2008-08-110 dpwe@ee.columbia.edu  after coversongs/src/calclistftrs

% dgth, whiwin)

if nargin < 2; srcprepend = ''; end
if nargin < 3; srcext = ''; end
if nargin < 4; dstprepend = ''; end
if nargin < 5; dstext = ''; end
if nargin < 6; skip = 0; end
% downweight fundamentals below here
if nargin < 7; fctr = 400; end % or maybe 100 for bass
if nargin < 8; fsd = 1.0; end
if nargin < 9; tmean = 240.0; end
if nargin < 10; tsd = 1.0; end
if nargin < 11; exceptions = []; end

%if nargin < 12; dgth = 0.5; end
%if nargin < 13; whiwin = 1.0; end
dgth = 0.5;  % 0.4 is better for GMMs, 0.5 for SVMs?
whiwin = 0.02;  % Apply whitening! 0.1 better for GMMs, 0.02 for SVMs

if length(exceptions) > 1
  ename = exceptions{1};
  esemis = exceptions{2};
else
  ename = [];
  esemis = [];
end

if exist('isp_ifchromagram') ~= 2
  addpath('isptoolbox');
end
if exist('mp3read') ~= 2
  addpath('mp3readwrite');
end

if iscell(listfile)
  files = listfile;
  listfile = 'passed in cell array';
else
  files = listfileread(listfile);
end
nfiles = length(files);

semisoffs = zeros(1,nfiles);

if nfiles < 1
  error(['No sound file names read from ',listfile]);
end

% preallocate to placate mlint
opfiles{nfiles} = '';

% dstext is a cell array indicating multiple parameters for fctr, fsd
if isstr(dstext)
  dstexts{1} = dstext;
else
  dstexts = dstext;
end
ndstexts = length(dstexts);
fctrs = fctr;
fsds = fsd;

nopfiles = 0;

% Process every input file
for songn = 1:nfiles

  tline = files{songn};

  % figure out input file names
  if length(srcext) > 0
    if strcmp(tline(end-length(srcext)+1:end), srcext)
      % chop off srcext already there
      tline = tline(1:end-length(srcext));
    end
  else
    %% no srcext specified - must be part of input file name
    %% separate name and extension for input file
    [srcpath, srcname, srcext] = fileparts(tline);
    tline = fullfile(srcpath,srcname);
    % .. we will end up putting it all back together again
  end

  % So file names are:
  ifname = fullfile(srcprepend,[tline,srcext]);

  havewav = 0;
  
  % make isp_ifchromagram estimate the tuning on first pass
  semisoff = [];

  ix = strmatch(tline,ename);
  if length(ix) > 0
    semisoff = esemis(ix);
    disp(['** calcbeatchroma: exception tuning of ',num2str(semisoff),' found for ',tline]);
  end
  
  for dstver = 1:ndstexts

    ofname = fullfile(dstprepend,[tline,dstexts{dstver}]);

    fctr = fctrs(1+mod(dstver-1,length(fctrs)));
    fsd = fsds(1+mod(dstver-1,length(fsds)));
    
    if songn > skip

      if fexist(ofname)
        disp(['Output file ',ofname,' exists - skipping']);
      else

        % header info for output file
        vsn = 20091014.0;
        desc = 'Classic beat-chroma matrices with semisoff';

        if havewav == 0
        
          % wav files or mp3 files
          if strcmp(srcext,'.mp3')
            [d,sr] = mp3read(ifname,'size');
            if sr >= 32000
              ds = 2;
            else
              ds = 1;
            end
            % 0 = real all, 1 = cast to mono, ds = downsample, 0 =
            % no predelay compensation
            delay = 0;
            [d,sr] = mp3read(ifname,0,1,ds,delay); %%%%%%%%%%%%%% !!!!!!!!!!!
          else
            [d,sr]=wavread(ifname);
            if size(d,2) == 2
              % collapse stereo data to mono
              d = d(:,1) + d(:,2);
            end
          end

          %disp(['sr = ',num2str(sr)]);
          
          % Get the beats for this tempo
          bts = beat2(d,sr,[tmean tsd],400,0);

          havewav = 1;
        end
        
        %      [F,bts] = chrombeatftrs(d,sr,fctr,fsd,ctype,tmean,tsd);
        % in-line now
        fftlen = 2 ^ (round(log(sr*(2048/22050))/log(2)));
        ffthop = fftlen/4;
        ifsr = sr/ffthop;
        nbin = 12;
        %Y = chromagram_IF(d,sr,fftlen,nbin,fctr,fsd);
        % Jesper Jensen's optimized version
        %semisoff = [];  % suppress 400-to-100 offset locking
        [Y,pp,mm,SS,semisoff] = isp_ifchromagram(d,sr,fftlen,nbin,fctr,fsd,semisoff,dgth,whiwin);
%        [Y,pp,mm,SS,semisoff] = local_ifchromagram(d,sr,fftlen,nbin,fctr,fsd,semisoff,dgth);

        semisoffs(songn) = semisoff;
        %disp(['semisoff = ',num2str(semisoff)]);
        
        %%%%%% Make the chroma C-based, not A-based
        Y = chromrot(Y,3);

        % condense the chroma per beat
        F = beatavg(Y,bts*ifsr);

        % Make sure the parent directory exists
        ofdir = fileparts(ofname);
        mymkdir(ofdir);

        % Write the data out
        key = -1;  % not estimated, but put the slot in
        save(ofname,'ifname','F','bts','tmean','tsd','fctr','fsd','vsn','desc','semisoff','key');

        disp([datestr(rem(now,1),'HH:MM:SS'), ' song ',num2str(songn),' ', ...
              tline,' semisoff=',num2str(semisoff),' bpm=', sprintf('%.0f ',60/median(diff(bts))), ...
              ' fctr=',num2str(fctr)]);

        %Write bpm to file

        fileBPM = fopen('results/bpm.txt','w');
        fprintf(fileBPM,'%.0f',60/median(diff(bts)));

      end   % file does not already exist
        
    end  % song is not in skip region
        
    % only report name of first file written for each song
    if dstver == 1
      nopfiles = nopfiles + 1;
      opfiles{nopfiles} = ofname;
    end
  
  end % dstver

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function X = beatavg(Y,bts)
% X = beatavg(Y,bys)
%    Calculate average of columns of Y according to grid defined 
%    (real-valued) column indices in vector bts.
%    For folding spectrograms down into beat-sync features.
% 2006-09-26 dpwe@ee.columbia.edu

% beat-based segments
%bts = beattrack(d,sr);
%bttime = mean(diff(bts));
% map beats to specgram slices
ncols = size(Y,2);
coltimes = 0:(ncols-1);
% Ensure last value is end of array, and it only occurs once
bts = bts(bts < max(coltimes));
btse = [bts,max(coltimes)];
nbts = length(bts);
cols2beats = zeros(nbts, ncols);
for b = 1:nbts
  cols2beats(b,:) = ((coltimes >= btse(b)) & (coltimes < btse(b+1)))*1/(btse(b+1)-btse(b));
end

% The actual desired output
X = Y * cols2beats';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function E = fexist(F)
%  E = fexist(F)  returns 1 if file F exists, else 0
% 2006-08-06 dpwe@ee.columbia.edu

x = dir(F);

E = length(x);
