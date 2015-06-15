function extractFeaturesAndTrain_svm(trainFileList, scratchDir, model, mp3dir, mp3ext, labdir, labext, skip, maxframes)
% extractFeaturesAndTrain_svm(trainFileList, scratchDir, model, mp3dir, mp3ext, labdir, labext, skip, maxframes)
%      First part of MIREX10 StructSVM chord recognition.
% 2008-08-21 Dan Ellis dpwe@ee.columbia.edu  based on recog_chords_1fold.m
% 2009-09-20 Revised by Adrian Weller aw2506@columbia.edu to incorporate
% SVMstruct instead of HMM for sequence labeling

%Defaults
if nargin < 3; model = 10; end
if nargin < 4; mp3dir = ''; end
if nargin < 5; mp3ext = ''; end
if nargin < 6; labdir = ''; end
if nargin < 7; labext = '.txt'; end
if nargin < 8; skip = 0; end
if nargin < 9; maxframes = 0; end


if isstr(model); model = str2num(model); end  %in case entered as string

%isharte = 1;
%ruleset = 1;  % set in configureme

configureme_svm;  % set configuration - overrides model, sets pretrained, etc.

if pretrained
  disp(['**** Pretrained model configuration - skipping extractFeaturesAndTrained']);
  return
end

exceptions = 'TUNING_EXCEPTIONS';
if exist(exceptions,'file') > 0
  [esemis, ename] = textread(exceptions,'%f %s');
  disp(['** tuning exceptions read from ',exceptions]);
  edata = {ename,esemis};
else
  edata = [];
end

SVMDir='./';

C      = modelparams_svm(model,1);           %C param for SVMstruct. 100-800 probably in right range before train12fold
use100 = modelparams_svm(model,2);      %flag, if <>0 then add in the 12 chroma features centred at 100 Hz
train12fold = modelparams_svm(model,3); %flag, if <>0 then use 12-fold rotations of training data 
nflag  = modelparams_svm(model,4);       %number of fwd frames to use
pflag  = modelparams_svm(model,5);       %number of prev frames to use
qflag  = modelparams_svm(model,6);       %quad features
epsilon = 0.1;   %used for error bound for termination of training phase, smaller->more accurate but longer training time

% Generate base feature and beat-matched label files
[trnf,semisoff] = calcbeatchroma(trainFileList,mp3dir,mp3ext,scratchDir, ...
				 {'-400.mat','-100.mat'}, skip, [400 100], ...
				 [1 1], 240,1, edata);

labf = rewrite_chordlabs_mirex(trainFileList,labdir,labext,scratchDir,'lab.mat',scratchDir,'-400.mat',skip,isharte,ruleset);

% output list of written files
fl = [trnf,labf];

% load training data
clear X_train Y_train; % X_train will contain the training points to feed to svmhmmwrite for svmhmm, Y_train will have the labels

X_train = loadftrs_mirex_svm(trnf,use100,nflag,pflag,qflag,train12fold,maxframes);
Y_train = loadlabs_mirex_svm(labf,train12fold,maxframes);

%disp([trainFileList,': ',num2str(length(F)),' frames']);

%Create svm train data
name=['model' num2str(model)];
train=[name '_train.dat'];
train_name=fullfile(scratchDir,train);

% fixup nochord labels
NOCHORD = 0;
NOCHORD_SVM = 25;
for i = 1:length(Y_train)
  Y_train{i}(find(Y_train{i} == NOCHORD)) = NOCHORD_SVM;
end

svmhmmwrite(train_name,X_train,Y_train);

clear X_train Y_train; %free up memory
mname=[name '.model'];
model_name=fullfile(scratchDir,mname);

%string for learning model
str_learn = [SVMDir 'svm_hmm_learn -c ' num2str(C) ' -e ' num2str(epsilon) ' ' train_name ' ' model_name];
str_learn  %so we can see if it looks ok
%learn model
unix(str_learn);

%delete the large train_name file
delete(train_name);

end

