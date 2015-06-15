#!/bin/bash

cd /Applications/MAMP/htdocs/mood/backend/matlab/
/Applications/MATLAB_R2014b.app/bin/matlab -nodisplay -nodesktop -nosplash -nojvm -logfile thelog.log -r "doChordID_svm /Applications/MAMP/htdocs/mood/backend/matlab/testFileList.txt /Applications/MAMP/htdocs/mood/backend/matlab/results /Applications/MAMP/htdocs/mood/backend/matlab/results"
echo Done