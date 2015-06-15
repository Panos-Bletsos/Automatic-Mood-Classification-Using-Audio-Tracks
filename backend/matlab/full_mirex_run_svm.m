% full_mirex_run_svm.m
% 2009-09-22, 2010-08-10 Dan Ellis dpwe@ee.columbia.edu

% make sure path is OK
if exist('viterbi_path') ~= 2
  addpath('KPMtools');
  addpath('KPMstats');
  addpath('KPMhmm');
end
if exist('isp_ifchromagram') ~= 2
  addpath('isptoolbox');
end

%isharte = 1;
%ruleset = 0;
model = -1;  % dummy for configureme
configureme_svm;  % sets model (maybe), ruleset, isharte

mp3dir = 'mp3s-32k/';
mp3ext = '.mp3';

if isharte
  labdir = 'chordlabs/';
else
  labdir = 'mattilabs/';
end
labext = '.lab';

results = 'results';
scratch = 'scratch';

skip = 0;
%exceptions = 'TUNING_EXCEPTIONS';
maxframes = 0;

% build file lists
listdir = 'beatles/lists/';
cut1 = addprefixsuffix(listfileread([listdir,'cut1.txt']),'beatles/');
cut2 = addprefixsuffix(listfileread([listdir,'cut2.txt']),'beatles/');
cut3 = addprefixsuffix(listfileread([listdir,'cut3.txt']),'beatles/');
cut4 = addprefixsuffix(listfileread([listdir,'cut4.txt']),'beatles/');

ncut1 = [cut2,cut3,cut4];
ncut2 = [cut1,cut3,cut4];
ncut3 = [cut1,cut2,cut4];
ncut4 = [cut1,cut2,cut3];

testset = [cut1,cut2,cut3,cut4];

for model = 15

%  for maxframes = 100:100:1000
  
      disp(['Testing model ',model,' with maxframes=',num2str(maxframes)]);

      extractFeaturesAndTrain_svm(ncut1,scratch, model, ...
                                  mp3dir, mp3ext, labdir, labext, ...
                                  skip, maxframes);
      doChordID_svm(cut1,scratch,results,model,mp3dir,mp3ext,skip);

      extractFeaturesAndTrain_svm(ncut2,scratch, model, ...
                                  mp3dir, mp3ext, labdir, labext, ...
                                  skip, maxframes);
      doChordID_svm(cut2,scratch,results,model,mp3dir,mp3ext,skip);

      extractFeaturesAndTrain_svm(ncut3,scratch, model, ...
                                  mp3dir, mp3ext, labdir, labext, ...
                                  skip, maxframes);
      doChordID_svm(cut3,scratch,results,model,mp3dir,mp3ext,skip);

      extractFeaturesAndTrain_svm(ncut4,scratch, model, ...
                                  mp3dir, mp3ext, labdir, labext, ...
                                  skip, maxframes);
      doChordID_svm(cut4,scratch,results,model,mp3dir,mp3ext,skip);

      rext = '.txt';
      [S,C] = score_mirex(testset, results, rext, labdir, labext, ...
                          isharte, ruleset);

      msg = ['Overall accuracy (4 fold train/test, model ',num2str(model),' maxframes=',num2str(maxframes),') = ',num2str(S)];
      disp(msg);

      % write out result for easy datestamping of progress
      f = fopen(['result',num2str(model),'-mf',num2str(maxframes),'.txt'],'w');
      fprintf(f,[msg,'\n']);
      fclose(f);

%    end % maxframes

end % model
