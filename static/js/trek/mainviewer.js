
var $viewscreen = $( "#viewscreen" );
var displayingCaptainsLog = false;


function pollForCaptainsLogs () {

    if ( displayingCaptainsLog ) {

        // too busy reading, don't download the new one
        return;

    }

    var parseCaptainsLog = function ( data ) {

        if ( data == "" ) {

            return;

        }

        displayCaptainsLog( data );

    };

    trek.api( "command/captains-log", parseCaptainsLog );

}


function displayCaptainsLog ( log ) {

    logWithBreaks = log.entry.replace( /\n/g, '<br>' );
    var $blackout = $( "<div class='blackout'></div>" );
    var $log = $( "<div class='captains-log'>" + logWithBreaks + "</div>" );

    $blackout.append( $log );

    var removeLog = function () {

        displayCaptainsLog = false;
        $blackout.remove();

    }

    $blackout.click( removeLog );

    $( "body" ).append( $blackout );
    $blackout.css( 'visibility', 'visible' );
    displayCaptainsLog = true;

}


trek.socket.on(
    "setScreen",
    function ( data ) {

        console.log( data );
        $viewscreen.attr( 'src', data.screen );

    } );


$viewscreen.attr(
    'src',
    "viewscreen_screen?direction=forward" );

pollForCaptainsLogs();

// In the event of a red alert, play sound...
trek.onAlert( function( data ) {

    trek.playKlaxon();

    } );

setInterval( pollForCaptainsLogs, 3000 );


trek.playTheme();
trek.registerDisplay( "Viewscreen" );
trek.checkBlastDamage();
