# Automatic Mood Classification Of Audio Tracks

### Abstract
This project was created for the course "Speech and Audio Processing" at the Ionian University, Department of Informatics. The goal is to classify audio tracks based on mood using information from the chords and BPM (beats per minutes) of each song. To do so system was trained with 170 audio tracks from four major genres (Rock, Hip-Hop, Jazz, Blues) and then using a Naive Bayes Classifier each song is classified to one of these moods:
#
| Mood Cluster       | Description |
| ------------- |:-------------:|
| C1      | amazed-suprised |
| C2      | happy-pleased |
| C3 | relaxing-calm      |
| C4 | quite-still |
| C5 | sad-lonely |
| C6 | angry-fearful |
All tracks were downloaded from Apple’s iTunes database and for that reason they are classified based on the 30 seconds preview that Apple provides for each song.

### Naive Bayes Classifier
![alt tag](https://cloud.githubusercontent.com/assets/5760599/10560326/d5795b70-7510-11e5-8838-a4d555fc03fb.gif)
#
![alt tag](https://cloud.githubusercontent.com/assets/5760599/10560502/54198668-7515-11e5-8f5a-75b7deeff57a.gif)

### Methodology
##### Download song
Each song (for training and the new songs) are being downloaded from Apple's iTunes database using the 30 seconds preview.
#
[More info](https://www.apple.com/itunes/affiliates/resources/documentation/itunes-store-web-service-search-api.html)
##### Extraction of chords and BPM
For the extraction of the chords and the BPM of each song is being used a Matlab subroutine.
#
[More info](http://labrosa.ee.columbia.edu/projects/chords/)
#### Save to Database
A MySQL database is being used to save every song with info about its chords and bpm.
#### Training
For the training used 170 audio tracks. You can find these tracks under ```/backend/training/```.

### TODO
* Allow users to provide feedback about every song that they search.
* Save new songs to database.
* Train the system with more songs using [Echo Nest](http://the.echonest.com).







