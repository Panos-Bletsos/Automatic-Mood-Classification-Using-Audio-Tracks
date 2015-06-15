% configureme_svm.m
%
% set configuration constants for labrosachordrecog2010 (SVMstruct system)
%
% 2010-07-13 Dan Ellis dpwe@ee.columbia.edu

pretrained = 1;  % use included model files
model = 25;      % model 15 also included 

ruleset = 0;  % how to treat dim2 etc.
isharte = 1;  % use symbolic-format label files for input & output

disp(['***CONFIG: model=',num2str(model),' pretrained=',num2str(pretrained)]);
