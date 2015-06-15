%% ISP_EVALUATEDEMO2  Demonstration of how to use the evaluation framework
% In the following, we set up and run an evaluatoin of some music
% distance measures from the toolbox and a simple, custom one.

% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License version 2 as published
% by the Free Software Foundation.


% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License version 2 as published
% by the Free Software Foundation.


dstMsr = isp_tichroma;
datapath = './evaluatedata';

%%
% This takes approx. 6 minutes on my laptop.
tic
res = isp_evaluate(dstMsr, ...
             'distribute', 0, ...
             'experiment', {'instrumentmelody', 'duration'}, ...
             'dataPath', datapath, ...
             'nInstruments', 4, ...
             'nMidifiles', 3);
toc

isp_plotresults(res);
