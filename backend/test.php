<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);


require_once('naive_bayes_class.php');

$file = file_get_contents("test.json");
$testing_data = json_decode($file, true);

// // Debug
// echo '<pre>';
// print_r($testing_data);
// echo '</pre>';

foreach ($testing_data as $mood_name => $songs) {
	foreach ($songs['songs'] as $song) {
		$artist = $song['Artist'];
		$song = $song['Song'];

		test($artist, $song, $mood_name);
	}
}


/************************************************/
/******************** Test **********************/
/************************************************/

function test($artist, $track, $pre_mood) {

	
	/************** Connect to Database ****************/

	$con = mysqli_connect("localhost","root","root","auto_mood_cat");
	
	if (mysqli_connect_errno()) {
		echo "Failed to connect to MySQL: " . mysqli_connect_error();
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
		echo 'Song downloaded.</br>';
	}
	else {
		echo 'Song not found.</br>';
		return;
	}


	// Convert song to wav.
	exec('/usr/local/bin/ffmpeg -i /Applications/MAMP/htdocs/mood/backend/audio/audio.m4a /Applications/MAMP/htdocs/mood/backend/audio/audio.wav');

	// Run matlab script
	$output = shell_exec('sh ./run_matlab.sh');
	echo $output."</br>";

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

	if ($pre_mood != $mood) {
		$correct = 0;
	}
	else {
		$correct = 1;
	}

	echo 'artist: '.$artist.' song: '.$track.' Pre computed: '.$pre_mood.' c_mood: '.$mood.' correct: '.$correct.'</br>';

	
	/*************** Insert to Database ****************/

	$error = mysqli_query($con, "INSERT INTO TESTING (ARTIST, SONG, PRECOMPUTED_MOOD, CLASS_MOOD, CORRECT) VALUES ('$artist','$track','$pre_mood','$mood', $correct)");

	if ($error === false) {
		echo 'ERROR!';
	}

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

?>