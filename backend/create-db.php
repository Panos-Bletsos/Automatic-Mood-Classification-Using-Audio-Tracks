<?php
		//Open a connection to the MySQL Server
        $link = mysqli_connect("localhost","root","root");
        
        //Chech for errors
        if (mysqli_connect_errno()) {
            ?> <h3> <?php echo  mysqli_connect_error(); ?> </h3><?php
        }
        
        //Save the query to a var
        $sql = "CREATE DATABASE IF NOT EXISTS auto_mood_cat CHARACTER SET utf8 COLLATE utf8_general_ci;";
        
        //Perform the query on the dabase
        //For a successful query it returns TRUE
        //If there is any error then it return FALSE and we print the error
        if (!(mysqli_query($link,$sql))) {
            ?> <h3> <?php echo mysqli_error($link); ?> </h3><?php
        }
        
        //Connect with the database URL
        $con = mysqli_connect("localhost","root","root","auto_mood_cat");
        
        //Check for errors
        if (mysqli_connect_errno()) {
            ?> <h3> <?php echo  mysqli_connect_error(); ?> </h3><?php
        }
        
        //Save the query that creates the table 'SONGS'    
        $sql = "CREATE TABLE IF NOT EXISTS SONGS( ID int NOT NULL AUTO_INCREMENT, ARTIST VARCHAR(255) NOT NULL , SONG VARCHAR(255) NOT NULL, ALBUM VARCHAR(255), BPM int NOT NULL, MOOD int NOT NULL, PRIMARY KEY(ID) )";
        
        //Check for errors
        if (!(mysqli_query($con,$sql))) {
            ?> <h3> <?php echo mysqli_error($con); ?> </h3> </br> <?php
        } 

        //Save the query that creates the table 'CHORDS'    
        $sql = "CREATE TABLE IF NOT EXISTS CHORDS( ID int NOT NULL AUTO_INCREMENT, S_ID int NOT NULL , CHORD VARCHAR(7) NOT NULL, PRIMARY KEY(ID), FOREIGN KEY (S_ID) REFERENCES SONGS(ID) )";
        
        //Check for errors
        if (!(mysqli_query($con,$sql))) {
            ?> <h3> <?php echo mysqli_error($con); ?> </h3> </br> <?php
        }

        $sql = "CREATE TABLE `TESTING` (
                `ID` int(11) NOT NULL,
                `ARTIST` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
                `SONG` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
                `PRECOMPUTED_MOOD` int(11) NOT NULL,
                `CLASS_MOOD` int(11) NOT NULL,
                `CORRECT` bit(1) NOT NULL DEFAULT b'0'
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8;"

        //Check for errors
        if (!(mysqli_query($con,$sql))) {
            ?> <h3> <?php echo mysqli_error($con); ?> </h3> </br> <?php
        }
?>