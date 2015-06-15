#!/bin/bash

cd /Applications/MAMP/htdocs/mood/backend/audio/
ffmpeg -i /Applications/MAMP/htdocs/mood/backend/audio/audio.m4a /Applications/MAMP/htdocs/mood/backend/audio/audio.wav
echo Done converting.