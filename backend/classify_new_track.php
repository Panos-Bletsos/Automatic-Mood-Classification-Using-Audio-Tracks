<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once('naive_bayes_class.php');

$artist = $_GET['artist'];
$track = $_GET['track'];

// Replace space with +.
$artist = preg_replace("/ /", "+", $artist);

$mood = classify($artist, $track);


/************************************************************/
/*                                                          */
/*                                                          */
/*                                                          */
/*          There are 6 different mood clusters.            */
/*                                                          */
/*          	• C1: Amazed - Suprised                     */
/*          	• C2: Happy - Pleased                       */
/*          	• C3: Relaxing - Calm                       */
/*          	• C4: Quite - Still                         */
/*          	• C5: Sad - Lonely                          */
/*          	• C6: Angry - Fearful                       */
/*                                                          */
/*                                                          */
/*                                                          */
/************************************************************/

$cluster = array(
	"1" => "Amazed - Suprised",
	"2" => "Happy - Pleased",
	"3" => "Relaxing - Calm",
	"4" => "Quite - Still",
	"5" => "Sad - Lonely",
	"6" => "Angry - Fearful",
	"404" => "A racoon stole the track and I can't find it... Sorry! :(",
	"-5" => "ERROR! Can't connect to database.",
	);



echo $cluster[$mood];


/************************************************/
/******************* Classify *******************/
/************************************************/

function classify($artist, $track) {

	
	/************** Connect to Database ****************/

	$con = mysqli_connect("localhost","root","root","auto_mood_cat");
	
	if (mysqli_connect_errno()) {
		//echo "Failed to connect to MySQL: " . mysqli_connect_error();
		return -5;
	}

	/*********** !END Connect to Database **************/



	// Replace space with +.
	$artist = preg_replace("/ /", "+", $artist);




	/*************** Search for the song ***************/

	$ch = curl_init();

	curl_setopt($ch, CURLOPT_URL, "https://itunes.apple.com/search?term=".$artist."&entity=musicTrack&limit=200");
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($ch, CURLOPT_USERAGENT, "auto mood cat / mailto:panos.bletsos@gmail.com");
	curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
	$data = curl_exec($ch);
	$info = curl_getinfo($ch); 
	$http_code = $info['http_code'];
	curl_close($ch);

	$json = json_decode($data);

	/*********** !END Search for the song *************/




// // Debug
// echo '<pre>';
// print_r($json);
// echo '</pre>';

	// Just to be sure... Remove old audio files.
	shell_exec('sh ./remove_files.sh');

	if (download_song($json, $track) == 0) {
		// echo 'Song downloaded.</br>';
	}
	else {
		// echo 'Song not found.</br>';
		return 404;
	}


	// Convert song to wav.
	exec('/usr/local/bin/ffmpeg -i /Applications/MAMP/htdocs/mood/backend/audio/audio.m4a /Applications/MAMP/htdocs/mood/backend/audio/audio.wav');

	// Run matlab script
	$output = shell_exec('sh ./run_matlab.sh');
	// echo $output."</br>";

	$bpm = file_get_contents('matlab/results/bpm.txt');
	$chords = file_get_contents('matlab/results/audio.wav.txt');

	// Save each chord in an array.
	$chord = explode(PHP_EOL, $chords);
	$chord_length = count($chord);

	for ($i = 0; $i < $chord_length; $i++) {
		if ($chord[$i] == 'N' || $chord[$i] == null) {
			unset($chord[$i]);
		}
	}

	$mood = naive_bayes_class($chord, $bpm);

	return $mood;
}

/***************************************************/
/****************** Download song ******************/
/***************************************************/

function download_song($data, $track) {
	foreach ($data->results as $songs) {
	
		if (strcasecmp($track, $songs->trackName) == 0) {
			file_put_contents("audio/audio.m4a", fopen($songs->previewUrl, 'r'));
			return 0;
		}

	}

	return -1;
}