function v = modelparams_svm(model,param)
% centralized fn to set model params for extractFeatures_svm / doChord_svm
% 2010-06-07 Dan Ellis dpwe@ee.columbia.edu

%            C  use100 12fold nflag pflag qflag      time    acc      rerun w/whiten,TUNING,fixes
modelparms=[100,   0,    0,   0,    0,    0; ... %1  0:07 = 0.6860    0:08 0.7158+
            100,   0,    0,   0,    0,    1; ... %2  0:22 = 0.6916    0:21 0.7252+
            100,   0,    0,   1,    0,    1; ... %3  1:34 = 0.6977    1:11 0.7290
	    100,   0,    0,   0,    1,    1; ... %4  1:30 = 0.6991    1:07 0.7341+
	    100,   0,    0,   1,    1,    1; ... %5  4:11 = 0.7009    2:36 0.7346
            100,   0,    0,   2,    0,    1; ... %6  4:21 = 0.6972    2:52 0.7313
	    100,   0,    0,   0,    2,    1; ... %7  4:17 = 0.6988    2:41 0.7348
            100,   1,    0,   0,    0,    1; ... %8  0:26 = 0.7216    0:19 0.7543  % lowchroma isolated
            100,   1,    0,   1,    0,    1; ... %9  1:37 = 0.7276    1:05 0.7565
            100,   1,    0,   0,    1,    1; ... %10 1:32 = 0.7309    1:03 0.7584+  %10 rules 0 isharte 1 + TUNING_EXCEPTIONS
            100,   2,    0,   0,    0,    1; ... %11 0:44 = 0.7233    0:33 0.7555  % lowchroma get n,p,q
            100,   2,    0,   1,    0,    1; ... %12 3:43 = 0.7296    2:38 0.7595  % lowchroma get n,p,q
            100,   2,    0,   0,    1,    1; ... %13 3:32 = 0.7298    2:33 0.7597  % 10 with lowchroma get n,p,q
            100,   1,    0,   1,    1,    1; ... %14 4:02 = 0.7295    2:31 0.7589  % lowchroma isolated again
            100,   1,    0,   0,    1,    12;... %15 0:29 = 0.7277    0:23 0.7601-  % 10 with qflag = 12
            400,   1,    0,   0,    1,    1; ... %16 3:19 = 0.7265    2:05 0.7573  % 10 with C = 400
            100,   1,    1,   0,    1,    1; ... %17 8:35 = 0.7222    5:21 0.7744  % 10 with 12fold (crashed machine until swap increased))
            100,   1,    1,   0,    0,    1; ... %18 1:51 = 0.7114    1:34 0.7683  % 8 with 12fold
            100,   1,    0,   2,    0,    12; ... %19 1:46 = 0.7271   1:09 0.7576  % old model 1 = 0.7262
            400,   1,    0,   2,    0,    12; ... %20 4:47 = 0.7225   2:12 0.7546  % old model 2
	    400,   1,    1,   2,    0,    12; ... %21 12:27 = 0.7242  5:48 0.7757  % old model 3
	    400,   1,    1,   0,    1,    1; ... %22 10:30 = 0.7268   7:15 0.7765+  % 10 with 12fold + C=400 / 17 with C=400
	    800,   1,    1,   0,    1,    1; ... %23 14:54 = 0.7294  10:17 0.7785  % 10 with 12fold + C=800
            200,   1,    0,   0,    1,    1; ... %24 2:14 = 0.7295    1:29 0.7565  % 10 with C=200
	    400,   1,    1,   0,    1,    12; ... %25                 2:38 0.7763-  % 15 with 12fold + C=400
	    800,   1,    1,   0,    1,    12; ... %26                 3:31 0.7775  % 15 with 12fold + C=800
	   1600,   1,    1,   0,    1,    12; ... %27                 5:17 0.7780  % 15 with 12fold + C=1600
	    100,   0,    0,   0,    1,    12; ... %28                 0:21 0.7323+ % 4 with no Q terms on prv
	    400,   1,    1,   2,    0,    12];
	  %[5,1,0; 10,1,0; 5,1,1; 10,1,1]; %[100,1,0; 400,1,0]; %100,0,0; 400,1,0; 100,1,0; 400,0,1; 100,0,1; 1600,0,1; 400,1,1; 100,1,1; 1600,1,1];

v = modelparms(model,param);

%10 on mirex180 = 0.8062

% 2010-07-08 - try %10 with revised isp_ components
%  unmodified otherwise: %10                     -> 0.7357 (2:24 inc. ftr calc)
%  using new calcbeatchroma (with semisoff locking) 0.7363
%            W = 0.01:                              0.7562
%            W = 0.02:                              0.7567*(1:28 inc. ftr calc)
%            W = 0.05:                              0.7555 (1:39 inc. ftr calc)
%  whitening W = 0.1:                               0.7535
%            W = 0.2:                               0.7510
%            W = 0.5:                               0.7442
%            W = 1.0:                               0.7412
%
% with 4 TUNING_EXCEPTIONS (on W=0.02 i.e. .7567):  0.7664* 0.8208
% with dgth = 0.4 (instead of 0.5)                  0.7625

% rebuild with isharte = 1:  0.7584 (0.7505 before fixing C:7 -> N)
% .. but chordlabs are still 31 ms early rel to mattilabs
% fixing labels +33ms -> 0.7587 ... maybe just differences in scoring?
% (took out manual 33ms offset, so back to 0.7584)

% post fixes: %17 on mirex180       14:01 = 0.7831   (12fold defeats overfitting?) (a LOT of swapping, 5% CPU)
%             %10 on mirex180        0:20 = 0.8139
%             %10 on mirex180+queen       = 0.8129
%                + limit 250 frames/tk    = 0.8070
%             %22 m180+q+250fr/tk    1:17 = 0.7850
%             %10 m180+q                  = 0.8130

% 2010-07-15 Problems reproducing %10 = 0.75841
%  without TUNING_EXCEPTIONS, maybe ruleset=1 in rewrite, score: 0.75195
%  with TUNING EXCEPTIONS, rules 0, using mattilabs (isharte 0): 0.72752 (!)
%  TUNING_EXCEPTIONS + isharte=1 + rules=0                     : 0.75841 (baseline)
%    change -400 normp 2 pwr .25 to normp Inf pwr .17          : 0.75746 (and 4.4 h! - 7700 iterations)

% 2010-07-20 model %1 without TUNING_EXCEPTIONS (redo features): 0:27 0.7060
%                  %1 without TUNING or whitening (re ftrs)    : 0:20 0.6766
%                  %1 with TUNING, without whitening (just 4)  : 0:06 0.6860
%                  %1 with TUNING + whitening  (re ftrs)       : 0:21 0.7158
