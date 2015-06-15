README.txt for labrosachordrecog-20100713

Dan Ellis dpwe@ee.columbia.edu
Adrian Weller adrian@cs.columbia.edu
LabROSA, Columbia University, New York

This is the code for an Audio Chord Estimation system, submitted to MIREX 2010.

REQUIREMENTS

This system is run from within Matlab.  It uses several precompiled Linux 
binaries which are included, compiled on a x86_64 Ubuntu system.

To run on other systems, you must "make" these programs from the source 
in the svm_hmm/ directory, then copy svm_hmm_learn and svm_hmm_classify 
into the main directory.

EXECUTION

The system follows the Audio Chord Estimation conventions.  
http://www.music-ir.org/mirex/wiki/2010:Audio_Chord_Estimation

To train your own models, modify the "pretrained=1;" flag in 
configureme.m to be "pretrained=0;".  Then, 

>> extractFeaturesAndTrain_svm "/path/to/trnFileList.txt" "/path/to/scratchDir"

... will read a list of WAV files from the trnFileList and use them to 
train chord models which are stored in scratchDir.  The labels associated 
with each wav file are in a file in the same directory with .txt appended 
(e.g. foo.wav.txt).  mp3 format files are also supported.

The trained model is written into a file named something like "model15.model" 
in the scratch directory.  If "pretrained=1;" this model is found instead 
in the main (code) directory.

Then, 

>> doChordID_svm "/path/to/testFileList.txt" "/path/to/scratchDir" "/path/to/resultsDir"

will perform chord recognition on each of the audio files listed in 
testFileList.txt, using the model read from scratchDir (if pretrained=0) or 
the code directory (if pretrained=1), and writing the results into 
resultsDir/<filename.wav>.txt .

Both the training labels and the classifier output files are in the format

<start_time_in_sec> <end_time_in_sec> <label>
<start_time_in_sec> <end_time_in_sec> <label>
....

where <label> can be "C", "C#", "D", ... for 12 major chords, 
"C:min", "C#:min", "D:min", ... for 12 minor chords, or 
"N" for no chord.  This system classifies only into these 
25 categories.

The training labels are assumed in the same format, but richer 
labels in the syntax defined by Chris Harte (e.g. "C:maj", "Eb:min/b7") 
are accepted too (but mapped to the 25 classes via the rules in 
normalize_labels.m).

EXECUTION TIME & RESOURCES

Feature calculation takes around 15 s per file.  Training takes up 
to 10 h for a 200 song dataaset.  Memory usage approaches 16 GB 
during training (results on a 2.8 GHz Xeon).

VERSIONS

We are submitting both a pre-trained model and a train-test system.  
The code is the same in both cases, except for the file 
configureme.m, which switches between the two modes.  In 
pre-trained mode, extractFeaturesAndTrain does nothing.

The pre-trained model has been trained on all 180 Beatles 
tracks, using Chris Harte's labels, and on the 20 Queen 
tracks, using Matthias Mauch's labels.

EVALUATION

The script full_mirex_run_svm.m runs an entire 4-way split train/test 
run, evaluating recognition accuracy using score_mirex.m/score_chord_id.m.
I include the list files defining my train/test cuts (from the 180 track 
Beatles corpus), but not the actual data (wave or labels).

Dan Ellis dpwe@ee.columbia.edu 2010-07-22
