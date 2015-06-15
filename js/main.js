$("#loading").hide();
$("#loading-text").hide();
$("#results").hide();

$.ajaxSetup({
    beforeSend:function(){
        // show gif here, eg:
        $("#results").hide();
        $("#loading").show();
        $("#loading-text").show();
    },
    complete:function(){
        // hide gif here, eg:
        $("#loading").hide();
        $("#loading-text").hide();
    }
});

$(".button").on('click',function(){
    var artist = $('#artist').val();
	var track = $('#track').val();

    $.get("backend/classify_new_track.php", {artist:artist, track:track}, function(data, status){
    $("#cluster").text(data);
    $("#results").show();
    })
  	.fail(function() {
    	alert( "error" );
  	})
    
	
});