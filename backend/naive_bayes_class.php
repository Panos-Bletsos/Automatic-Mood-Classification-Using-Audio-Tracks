<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);


/***************************************************/
/************ Naive Bayes Classification ***********/
/***************************************************/

function naive_bayes_class($chords, $bpm) {
	/*echo '<pre>';
	print_r($chords);
	echo '</pre>';*/

	// Connect to DB.
	$con = mysqli_connect("localhost", "root", "root",  "auto_mood_cat");
	
	if (mysqli_connect_errno()) {
		//echo "Failed to connect to MySQL: " . mysqli_connect_error();
		return -5;
	}

	$mood_prop_classification = array();
	$uniq_ch = unique_chords($con);
	$moods = calc_each_mood_chords_plays($con);
	$mood_prop_raw = mood_prop($con);
	$mean_bpm = mean_bpm($con);
	/*echo '<pre>';
	print_r($moods);
	echo '</pre>';*/

	$chords_to_class_count = count($chords);
	$prop_mood = array();

	foreach ($moods as $moods_key => $chords_in_mood) {
		// echo '=============== mood '.$moods_key." ===============".'</br>';
		$prop_mood[$moods_key] = 1;
		$prop_chord_mood = -1;

		$count_chords = count($chords_in_mood);

		foreach ($chords as $chords_key => $chord_to_class) {
			// echo $chord_to_class.'</br>';

			foreach ($chords_in_mood as $chord_classified_value) {
				
				if ( array_key_exists($chord_to_class, $chord_classified_value[0]) ) {
					$prop_chord_mood = ( ($chord_classified_value[0][$chord_to_class] + 1) / ($uniq_ch + $count_chords) );
					// echo $prop_chord_mood.'</br>';
				}
				else {
					$prop_chord_mood = 1;
				}
				
				$prop_mood[$moods_key] *= $prop_chord_mood;
			}
			
		}

		// echo $mood_prop_raw[$moods_key].'</br>';



		$prop_mood[$moods_key] *=  abs($bpm - $mean_bpm[$moods_key]) > 0 ? 1 / ( abs( $bpm - $mean_bpm[$moods_key] ) ) : 1 ;

		/*echo '<pre>';
		print_r($prop_mood);
		echo '</pre>';*/
	}
	
	

	// echo '<pre>';
	// print_r($prop_mood);
	// echo '</pre>';

	$max = 0;
	$mood_c = 0;

	foreach ($prop_mood as $mood => $propability) {
		if ($propability > $max) {
			$max = $propability;
			$mood_c = $mood + 1;
		}
	}

	return $mood_c;

}





/*************************************************************/
/**********  Calc how many times has each chord  *************/
/********** has been played for each mood cluster ************/
/*************************************************************/

function calc_each_mood_chords_plays($con) {

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

	$moods = array();

	for ($i = 0; $i < 6; $i++) {
		$mood_cluster = $i + 1;

		$qry = "SELECT CHORD, COUNT(CHORD) AS C_PLAYS
				FROM CHORDS
				INNER JOIN SONGS
				ON SONGS.ID = CHORDS.S_ID
				WHERE MOOD = '$mood_cluster'
				GROUP BY CHORD
				ORDER BY S_ID";

		$results = mysqli_query($con, $qry);

		if (mysqli_num_rows($results) > 0) {

			$j = 0;
			$moods[$i] = array();
			

			while($row = mysqli_fetch_assoc($results)) {
				$chords = array($row['CHORD'] => $row['C_PLAYS']);

				$moods[$i][$j] = array();
				
				array_push($moods[$i][$j], $chords);
				
				$j++;
			} // End While.

			mysqli_free_result($results);
		} // End if.

	} // End for.
	 // 
	return $moods;
}





/**********************************************/
/**********   Find the number of   ************/
/**********      unique chords     ************/
/**********************************************/

function unique_chords($con) {

	$uniq_ch = 0;

	$qry = 'SELECT COUNT(*) AS NUM_UNIQ_CH FROM (SELECT * FROM CHORDS GROUP BY CHORD) AS D_CH';

	$results = mysqli_query($con, $qry);

	if (mysqli_num_rows($results) > 0) {

		while($row = mysqli_fetch_assoc($results)) {

			// Number of unique chords.
			$uniq_ch = $row['NUM_UNIQ_CH'];
		}

		mysqli_free_result($results);
	}
	
	return $uniq_ch;
}





/*********************************************/
/**********   Find mean bpm for   ************/
/**********   each mood cluster   ************/
/*********************************************/

function mean_bpm($con) {
	$bpm = array();

	for ($i = 0; $i < 6; $i++) {

		$mood_cluster = $i + 1;

		$qry = "SELECT AVG(BPM) AS MEAN_BPM
				FROM SONGS
				WHERE MOOD = '$mood_cluster'";

		$results = mysqli_query($con, $qry);

		if (mysqli_num_rows($results) > 0) {

			while($row = mysqli_fetch_assoc($results)) {

				$bpm[$i] = round( $row['MEAN_BPM'] );
				// echo 'mood: '.$mood_cluster.' - bpm: '.$bpm[$i]."</br>";

			} // End While.

			mysqli_free_result($results);
		} // End if.

	// End for.
	}
	
	return $bpm;
}





/*********************************************/
/**********     Propability of    ************/
/**********   each mood cluster   ************/
/*********************************************/

function mood_prop($con) {
	$mood_prop = array();
	$total_songs = 0;

	// Calc how many songs have been classified.
	$qry = "SELECT COUNT(*) AS TOTAL_SONGS FROM SONGS";
	$results = mysqli_query($con, $qry);

	if (mysqli_num_rows($results) > 0) {

		while($row = mysqli_fetch_assoc($results)) {

			$total_songs = $row[ 'TOTAL_SONGS' ];

		} // End While.

		mysqli_free_result($results);
	} // End if.


	for ($i = 0; $i < 6; $i++) {
		$mood_cluster = $i + 1;

		$qry = "SELECT COUNT(MOOD) AS TOTAL_MOOD
				FROM SONGS
				WHERE MOOD = '$mood_cluster'";

		$results = mysqli_query($con, $qry);

		if (mysqli_num_rows($results) > 0) {

			while($row = mysqli_fetch_assoc($results)) {

				$mood_prop[$i] = $row[ 'TOTAL_MOOD' ] / $total_songs;

			} // End While.

			mysqli_free_result($results);
		} // End if.

	}// End for.

	return $mood_prop;
}
?>