var trek = (function($, _, Mustache, io) {
    var t = {};
    t.socket = io.connect( window.location.protocol + "//" + window.location.host );

    // Red Alert
    var alertCallbacks = [];


    // depreciated... use onAlert
    t.on_alert = function(callback) {
        console.log( "depreciated trek.on_alert call" );
        alertCallbacks.push( callback );

    };


    t.onAlert = function(callback) {

        alertCallbacks.push( callback );

    };


    function displayRedAlert() {

        var drawAlert = function ( svg ) {

            var $alert_svg = $( svg.children[0] );
            var $bg = $( "<div class='blackout'></div>" );
            var $alert_wrap = $( "<div class='alert-wrap'></div>" );

            $alert_wrap.append( $alert_svg );
            $bg.append( $alert_wrap );

            $bg.click( function( c ) {

                $bg.remove();

            });

            $("body").append( $bg );
            $bg.css( 'visibility', 'visible' );

        };

        $.get( '/static/svg/alert.svg', drawAlert );

    }

    function clearAlerts() {

        var $bgs = $( ".blackout" );
        $bgs.remove();

    }


    t.socket.on("alert", function(data) {

        // allow screens to handle alerts their own way
        if ( alertCallbacks.length > 0 ) {

            _.each( alertCallbacks, function( e ) {
                e(data);
            } );
            return;

        }

        // TODO: Handle "alert: data=yellow"
        if ( data == "red" ) {
            displayRedAlert();
        }

        if ( data == "clear" ) {
            clearAlerts();
        }

    });


    // Battle damage
    var damageHandlers = [];

    function displayBlastDamage () {

        var $overlay = $( "<div class='damageOverlay overlay'></div>" );
        var $crack = $( "<img src='static/textures/broken-glass0.png' />" );

        $overlay.append( $crack );

        $( "body" ).append( $overlay );

    }

    t.testDamage = displayBlastDamage;

    t.socket.on( "Display", function( data ) {

        if ( data == "Blast Damage!" ) {

            displayBlastDamage();

        }

    });


    // Bridge Sound
    function playBridgeSound () {

        var sound = document.createElement( "audio" );
        sound.setAttribute( "loop", "" );
        sound.setAttribute( "autoplay", "" );
        sound.src = "static/sound/bridge.mp3";

    }

    t.playBridgeSound = playBridgeSound;


    // Game Over
    function display_game_over () {

        $.get( '/static/svg/gameover.svg', function( svg ) {

            var $go_svg = $( svg.children[0] );
            var $bg = $( "<div class='blackout'></div>" );
            var $alert_wrap = $( "<div class='alert-wrap'></div>" );

            $alert_wrap.append( $go_svg );
            $bg.append( $alert_wrap );
            $( "body" ).append( $bg );
            $bg.css( 'visibility', 'visible' );

        });

    }

    t.socket.on("gameover", function( data ) {

        if ( alertCallbacks.length > 0 ) {
            return;
        }

        // check score, and see if you won
        display_game_over();

    });


    // API Wrapper
    function apiError( jqXHR, textStatus, errorThrown ) {

        console.log( jqXHR );

        var $bg = $( "<div class='blackout'></div>" );
        var $errorWrap = $( "<div class='errorWrap red'></div>" );

        // Display the error results and strip the stack
        var message = jqXHR.responseText.split( '\n' )[ 0 ];
        $errorWrap.html( message );

        $bg.append( $errorWrap );
        $bg.click( function( c ) {
            $bg.remove();
        });
        $( "body" ).append( $bg );
        $bg.css( 'visibility', 'visible' );

    }


    t.api = function( api_name, data, method, callback ) {

        // function( api, [[data, [method,]] callback] )
        switch ( arguments.length ) {
            case 1:
                callback = function() { return; };
                data = {};
                method = 'GET';
                break;
            case 2:
                callback = data;
                data = {};
                method = 'GET';
                break;
            case 3:
                callback = method;
                method = 'GET';
                break;
            case 4:
                break;
        }

        processData = true;
        if ( method != 'GET' ) {
            data = JSON.stringify( data );
            processData = false;
        }

        $.ajax({
            type: method,
            url: '/api/' + api_name,
            data: data,
            success: callback,
            processData: processData,
            contentType: 'application/json',
            error: apiError
        });


    };


    // Utility
    t.prettyDistanceKM = function( meters ) {

        var x = Math.round( parseInt( meters ) / 1000 );
        var rgx = /(\d+)(\d{3})/;
        x = x.toString();
        while ( rgx.test( x ) ) {
            x = x.replace( rgx, '$1' + ',' + '$2' );
        }
        return x + "km";

    };


    t.prettyDistanceAU = function( meters ) {

        var au = Math.round( meters / 149597870700 );
        if (au < 1) {
            return t.prettyDistanceKM( meters );
        } else {
            return au += "AU";
        }

    };


    t.prettyBearing = function( bearing ) {

        var x = Math.round( bearing * 1000 );
        return x.toString();

    };


    t.secondsToMinuteString = function( seconds ) {

        var minutes = Math.floor( seconds/60 );
        var secondRemaining = Math.round( seconds % 60 );
        minutes = minutes.toString();
        return minutes + ":" + secondRemaining;

    };


    t.parseQueryString = function() {

        var qs = window.location.search.substr(1);
        if ( qs === "" ){ return {}; }

        var a = qs.split( '&' );
        var b = {};
        for ( var i = 0; i < a.length; ++i ){
            var p=a[ i ].split( '=' );

            if ( p.length != 2 ) continue;

            b[p[0]] = decodeURIComponent( p[1].replace( /\+/g, " " ) );
        }
        return b;

    };


    return t;
}(jQuery, _, Mustache, io));