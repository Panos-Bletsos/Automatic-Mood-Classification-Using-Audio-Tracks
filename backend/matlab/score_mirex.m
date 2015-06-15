function [S,C,D] = score_mirex(testFileList, resultsDir, rsuffix, ...
                             lprefix, lsuffix, isharte, ruleset, sysoffst)
% [S,C,D] = score_mirex(testFileList, resultsDir, rsuffix, lprefix, lsuffix,
%                       isharte, ruleset, sysoffst)
%    Score across entire test set using mirex format syntax
%      testFileList is a list of test files
%      resultsDir is where the per-file results files were written
%      rsuffix is the suffix added to each result file (default '.txt');
%      lprefix, lsuffix added to IDs to get reference file name (dflt '.txt').
%      isharte to use harte-format files
%      ruleset selects the mapping of chords to reduced set (dflt 0).
%      sysoffst is constant time added to all system times.
%    S returns average accuracy, C returns confusion matrix, 
%    D is per-track accuracies.
% 2009-09-19 Dan Ellis dpwe@ee.columbia.edu

% doChordID "/path/to/testFileList.txt" "/path/to/resultsDir"

if nargin < 3; rsuffix = '.txt'; end
if nargin < 4; lprefix = ''; end
if nargin < 5; lsuffix = '.txt'; end
% isharte==1 => label files are <stime> <etime> <symbolic_chord_label>
if nargin < 6; isharte = 0; end
if nargin < 7; ruleset = 0; end
if nargin < 8; sysoffst = 0; end

% make sure path is OK
if exist('viterbi_path') ~= 2
  addpath('KPMtools');
  addpath('KPMstats');
  addpath('KPMhmm');
end

% Load list of test wav files

if iscell(testFileList)
  wfl = testFileList;
  testFileList = '[passed in cell array]';
else
  wfl = listfileread(testFileList);
end

% Build list of reference and system outputs
for i = 1:length(wfl)
  wf = wfl{i};
  ref{i} = [lprefix, wf, lsuffix];
  [wfp,wfn,wfe] = fileparts(wf);
  sys{i} = [resultsDir,'/',wfn,wfe,rsuffix];
end

% Apply scoring 
Risharte = isharte;
[S,C,D] = score_chord_id(sys,ref,isharte,Risharte,ruleset,sysoffst);



%>> extractFeaturesAndTrain beatles/lists/ncut1.txt scratch beatles/mp3s-32k/ .mp3 beatles/mattilabs/ .lab
%>> doChordID beatles/lists/cut1.txt scratch results beatles/mp3s-32k/ .mp3
%>> score_mirex beatles/lists/beatles-all-tracks.txt results beatles/mattilabs/ .lab
% Key estimation DISABLED
%    0.5557
% Key estimation ENABLED
%    0.5614
% Key estimation CHEATING (AWP ground truth)
%    0.5643


% difference of WAV and MP3
%extractFeaturesAndTrain beatles/lists/A_Hard_Day_s_Night.txt scratch beatles/mp3s-32k/ .mp3 beatles/mattilabs/ .lab
%doChordID beatles/lists/Please_Please_Me.txt scratch results beatles/mp3s-32k/ .mp3
%score_mirex beatles/lists/Please_Please_Me.txt results beatles/mattilabs/ .lab
% --> 0.6924
%
%extractFeaturesAndTrain train.txt scratch
%doChordID test.txt scratch results
%score_mirex test.txt results
% --> 0.6383
%
% - observe steady 140ms delay in beat times from WAV files
%   - uncertain delay in mp3 read?
%   - fixing the delay (advancing label sample times for wav) ->  0.6484
%     .. still huge

% Wavs, with offset removed to time-align to MP3s, 
% but with no chroma autocorrect: 0.6131
%  restore chroma autocorrect: 0.6924 (same as MP3s)
%  i.e. time skew in bass made enough difference in the features to
%  totally mess things up - just framing of STFT !?!
% Fix labels to always be PRECEDING -> 0.6987
% Advance all beat times (sampling points) by 0.3 s -> 0.7049

% 2009-09-23  - locking adaptive tuning
%   baseline (free-run tuning) on PPM: 0.6898
%   with locked tuning: 0.6878