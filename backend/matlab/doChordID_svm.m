function fl = doChordID_svm(testFileList, scratchDir, resultsDir, model, mp3dir, mp3ext, skip)
% fl = doChordID_svm(testFileList, scratchDir, resultsDir, model, mp3dir, mp3ext, skip)
%    Perform testing for MIREX08 chord recognition.
%      testFileList is a list of test files
%      scratchDir is the temporary directory where trained models live
%      resultsDir is where to write the per-file results
% 2008-08-21 Dan Ellis dpwe@ee.columbia.edu
% 2009-09-20 modified Adrian Weller aw2506@columbia.edu

% doChordID "/path/to/testFileList.txt" "/path/to/scratchDir" "/path/to/resultsDir"

if nargin < 4; model = 10; end
if nargin < 5; mp3dir = ''; end
if nargin < 6; mp3ext = ''; end
if nargin < 7; skip = 0; end

if isstr(model); model = str2num(model); end  %in case entered as string

%isharte = 1;

configureme_svm;  % set configuration

SVMDir='./';

if isstr(testFileList)
  testFileList = listfileread(testFileList);
end

C = modelparams_svm(model,1);           %C param for SVMstruct. 100-800 probably in right range before train12fold - only used for training, not used here
use100 = modelparams_svm(model,2);      %flag, if <>0 then add in the 12 chroma features centred at 100 Hz
train12fold = 0; %modelparams_svm(model,3); %flag, if <>0 then use 12-fold rotations of training data 
nflag = modelparams_svm(model,4);       %number of fwd frames to use
pflag = modelparams_svm(model,5);       %number of prev frames to use
qflag = modelparams_svm(model,6);       %quad features

%So note here both models are handled the same way since C is irrelevant

name=['model' num2str(model)];
mname=[name '.model'];

if pretrained
  model_name = mname;   % pretrained model file is in source code directory
else
  model_name=fullfile(scratchDir,mname);
end

test=[name '_test.dat'];
test_name=fullfile(scratchDir,test);
pname=[name '.pred'];
pred_name=fullfile(scratchDir,pname);
%string to test
str_test =  [SVMDir 'svm_hmm_classify ' test_name ' ' model_name ' ' pred_name];

% Calculate features for test item
edata = {};
[tstf,semisoff] = calcbeatchroma(testFileList,mp3dir,mp3ext,scratchDir,...
                                 {'-400.mat','-100.mat'}, skip, [400 100], ...
				 [1 1], 240,1, edata);

% Make sure output dir exists
mymkdir(resultsDir);
			     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  test  %%%%%%%%%%%%

for ti = 1:length(tstf)

  % create test data
  [X_test,B] = loadftrs_mirex_svm(tstf(ti),use100,nflag,pflag,qflag,train12fold); 
  svmhmmwrite(test_name,X_test);
  clear X_test;
  
  % run model
  unix(str_test);
  
  % delete test file to save space
  delete(test_name);

  %load predictions
  pth=load(pred_name)';  %need to transpose to match convention with B
  
  % output file name
  [pathstr,name,ext] = fileparts(testFileList{ti});
  opf = fullfile(resultsDir,[name,ext,'.txt']);

  % write output file

  % fixup nochord labels
  NOCHORD = 0;
  NOCHORD_SVM = 25;
  pth(find(pth == NOCHORD_SVM)) = NOCHORD;

  disp(['about to save to ',opf]);
  write_chordlabs(B,pth,opf,isharte);

  disp([datestr(rem(now,1),'HH:MM:SS'), ' song ',num2str(ti),' wrote ', opf]);

exit;

end
