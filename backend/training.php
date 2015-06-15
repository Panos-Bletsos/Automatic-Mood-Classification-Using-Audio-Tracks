<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Script start
$rustart = getrusage();

// Code ...

// Script end
function rutime($ru, $rus, $index) {
    return ($ru["ru_$index.tv_sec"]*1000 + intval($ru["ru_$index.tv_usec"]/1000))
     -  ($rus["ru_$index.tv_sec"]*1000 + intval($rus["ru_$index.tv_usec"]/1000));
}



$file = file_get_contents("train2.json");
$training_data = json_decode($file, true);

// // Debug
echo '<pre>';
print_r($training_data['C1']['genre']['Rock']['songs']);
echo '</pre>';

$i = 0;

foreach ($training_data as $mood_cluster_name => $mood_cluster) {
	foreach ($mood_cluster['genre'] as $genre) {
		foreach ($genre['songs'] as $song) {
			$artist = $song['Artist'];
			$track = $song['Song'];

			train($artist, $track, $mood_cluster_name);
		}
	}
}

$ru = getrusage();
echo "This process used " . rutime($ru, $rustart, "utime") .
    " ms for its computations\n";
echo "It spent " . rutime($ru, $rustart, "stime") .
    " ms in system calls\n";

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




/***************************************************/
/******************** Training *********************/
/***************************************************/

function train($artist, $track, $mood) {

	
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



	
	/*************** Insert to Database ****************/

	mysqli_query($con, "INSERT INTO SONGS (ARTIST, SONG, BPM, MOOD) VALUES ('$artist','$track','$bpm', '$mood')");

	$song_id = mysqli_insert_id($con);
	// -1 because chord has one more cell.
	$chord_length = count($chord) - 1;
	for ($i = 0; $i < $chord_length; $i++) {
		if ($chord[$i] != 'N') {
			mysqli_query($con, "INSERT INTO CHORDS (S_ID, CHORD) VALUES ('$song_id','$chord[$i]')");
		}
	}
}
?>