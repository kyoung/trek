var selected_option;
var $navInfo = $( "#navInfo" );
var $inputbox = $( "#inputBox" );
var $systemSelections = $( ".system-select" );
var $viewScreen = $( "#viewScreen" );

var $pickWarp = $( "#pickWarp" );
var $pickNav = $( "#pickNav" );
var $pickHelm = $( "#pickHelm" );
var $picks = $( "#viewMenu li" );

var $helmMenu = $( "#helmMenu" );
var $navMenu = $( "#navMenu" );
var $warpMenu = $( "#warpMenu" );

var $turnLeft = $( "#turnLeft" );
var $turnRight = $( "#turnRight" );
var $thrustUp = $( "#thrustUp" );
var $thrustDown = $( "#thrustDown" );

var turningLeft = false;
var turningRight = false;
var turnRate = 0;
var turnState = 0;

var navArrow = document.getElementById( "conn-helm-pointer" );

var MENU_STATES = { NAV : "Navigation", HELM : "Helm", WARP : "Warp" };
var menuState = "";

$viewScreen.attr( 'src', 'conn_screen' );


function dummyLog ( data ) {

    console.log( data );

}


$systemSelections.click( function ( e ) {

    $systemSelections.removeClass( "lightgreen" );
    $(this).addClass( "lightgreen" );

    $viewScreen.attr( "src", "conn_screen?system=" + this.id );

} );


$pickNav.click( function ( e ) {

    $picks.removeClass( "lightblue" );
    $pickNav.addClass( "lightblue" );
    $helmMenu.hide();
    $warpMenu.hide();
    $navMenu.show();
    menuState = MENU_STATES.NAV;

} );


$pickHelm.click( function ( e ) {

    $picks.removeClass( "lightblue" );
    $pickHelm.addClass( "lightblue" );
    $helmMenu.show();
    $navMenu.hide();
    $warpMenu.hide();
    menuState = MENU_STATES.HELM;

    $viewScreen.attr( "src", "tactical_screen?zoom=phasers&zoom_level=10" );

} );


$pickWarp.click( function ( e ) {

    $picks.removeClass( "lightblue" );
    $pickWarp.addClass( "lightblue" );
    $helmMenu.hide();
    $navMenu.hide();
    $warpMenu.show();
    menuState = MENU_STATES.WARP;

    $viewScreen.attr( "src", "conn_screen?system=" + currentSystem );

} );


$( ".selector" ).click( function () {

    setWarpMenuFunction( this.id );

} );


function setWarpMenuFunction ( selection ) {

    selected_option = selection;
    $( ".selector" ).removeClass( "lightblue" );
    $( "#" + selection ).addClass( "lightblue" );
    $inputbox.html( "" );

}


function displayNavStatus ( data ) {

    var navDatTmpl = "<p class='descriptive'>{{ speed }} {{ data }}</p>";
    var html;

    if ( data.warp > 0 ) {

        html = Mustache.render( navDatTmpl, { data : data.warp, speed : 'Warp' } );

    } else {

        html = Mustache.render( navDatTmpl, { data : data.impulse, speed : 'Impulse' } );

    }

    $navInfo.html( html );

}


function getNavStats() {

    trek.api( "navigation/status", displayNavStatus );

}


setInterval( getNavStats, 1000 );


$( "#mainViewer" ).click( function () {

    var x = document.getElementById( "viewScreen" );
    var searchTerms = x.contentWindow.location.search.replace( "?", "" );

    trek.api(
        "command/main-viewer",
        { screen : "conn_screen?" + searchTerms },
        'POST',
        updateNavigationData );

} );


function addCharToInput ( new_char ) {

    var now = $inputbox.html();
    $inputbox.html( now + new_char );

}


$( ".numPad" ).click( function () {

    var x_char = $( 'span', this ).html();
    addCharToInput( x_char );

} );


function engage () {

    var e = $inputbox.html().split( "m" );

    switch ( selected_option ) {

        case "setCourse":

            trek.api(
                'navigation/course',
                { bearing : e[ 0 ], mark : e[ 1 ] },
                'PUT',
                dummyLog );
            break;

        case "setWarp":

            trek.api(
                "navigation/warp",
                { speed : e[ 0 ] },
                'POST',
                dummyLog );
            break;

        case "setImpulse":

            trek.api(
                "navigation/impulse",
                { speed : e[ 0 ] },
                'POST',
                dummyLog );
            break;

        default:
            $inputbox.html( "" );

    };

    $( ".selector" ).removeClass( "lightblue" );
    $inputbox.html( "" );

}


$( "#engage" ).click( engage );


function turnShipRight () {

    if ( turningRight ) {

        // toggle off turn
        turningRight = false;
        trek.api(
            'navigation/turn',
            { direction: 'stop' },
            'PUT',
            dummyLog );
        $turnRight.removeClass( "toggle" );

    } else {

        if ( turningLeft ) {

            turningLeft = false;
            $turnLeft.removeClass( "toggle" );

        }
        turningRight = true;
        trek.api(
            'navigation/turn',
            { direction: 'starboard' },
            'PUT',
            dummyLog );
        $turnRight.addClass( "toggle" );

    }

}


function turnShipLeft () {

    if ( turningLeft ) {

        // toggle off turn
        turningLeft = false;
        trek.api(
            'navigation/turn',
            { direction : 'stop' },
            'PUT',
            dummyLog );
        $turnLeft.removeClass( "toggle" );

    } else {

        if ( turningRight ) {

            turningRight = false;
            $turnRight.removeClass( "toggle" );

        }

        turningLeft = true;
        trek.api(
            'navigation/turn',
            { direction : 'port' },
            'PUT',
            dummyLog );
        $turnLeft.addClass( "toggle" );

    }

}


function thrustForward () {

    trek.api(
        "navigation/thrust",
        { direction : "forward" },
        "POST",
        dummyLog )

}


function thrustBack () {

    trek.api(
        "navigation/thrust",
        { direction : "reverse" },
        "POST",
        dummyLog )

}


$turnRight.click( turnShipRight );
$turnLeft.click( turnShipLeft );
$thrustUp.click( thrustForward );
$thrustDown.click( thrustDown );


window.onkeydown = function ( d ) {

    console.log( d );

    switch ( menuState ) {

        case MENU_STATES.HELM:
            processHelmKeyCommands( d );
            break;

        case MENU_STATES.WARP:
            processWarpKeyCommands( d );
            break;

    }

}


function processWarpKeyCommands ( d ) {

    switch ( d.keyCode ) {

        // 0
        case 48:
            addCharToInput( "0" );
            break;

        // 1
        case 49:
            addCharToInput( "1" );
            break;

        // 2
        case 50:
            addCharToInput( "2" );
            break;

        // 3
        case 51:
            addCharToInput( "3" );
            break;

        // 4
        case 52:
            addCharToInput( "4" );
            break;

        // 5
        case 53:
            addCharToInput( "5" );
            break;

        // 6
        case 54:
            addCharToInput( "6" );
            break;

        // 7
        case 55:
            addCharToInput( "7" );
            break;

        // 8
        case 56:
            addCharToInput( "8" );
            break;

        // 9
        case 57:
            addCharToInput( "9" );
            break;

        // m
        case 77:
            addCharToInput( "m" );
            break;

        // .
        case 190:
            addCharToInput( "." );
            break;

        // enter
        case 13:
            engage();
            break;

        // e
        case 69:
            engage();
            break;

        // w
        case 87:
            setWarpMenuFunction( "setWarp" );
            break;

        // i
        case 73:
            setWarpMenuFunction( "setImpulse" );
            break;

        // c
        case 67:
            setWarpMenuFunction( "setCourse" );
            break;

    }

}


function processHelmKeyCommands ( d ) {

    switch ( d.keyCode ) {

        // up
        case 38:
            thrustForward();
            break;

        // down
        case 40:
            thrustDown();
            break;

        // left
        case 37:
            turnShipLeft();
            break;

        // right
        case 39:
            turnShipRight();
            break;

    }

}


trek.socket.on( "Navigation", function ( navData ) {

    if ( _.has( navData, "turn_direction" ) ) {

        // best effort turn
        i = setInterval(
            updateNavigationData,
            500 );

        // update nav data after turn time
        setTimeout(
            function () {

                clearInterval( i );
                updateNavigationData();

            },
            navData.turn_duration * 1.1 );

    }

} );


trek.socket.on( "Turning", function ( navData ) {

    updateNavigationDisplay( navData );

} );


trek.socket.on( "Nav-Override", function ( message ) {

    trek.displayRed( message );

} );


function updateNavigationDisplay ( navData ) {

    console.log( navData );

    turnRate = navData.rotation.bearing;
    turnState = navData.bearing.bearing;
    var degree = ( 1 - turnState ) * 360 + 90;
    navArrow.setAttribute(
        "transform",
        "rotate(" + degree + ", 119.5, 119.5)" );

}

var turnCalcTimeStamp = 0;

function updateOrientation ( tStamp ) {

    if ( turnRate != 0 ) {

        delta = tStamp - turnCalcTimeStamp;
        var b = turnState + turnRate * delta;

        // Normalize the bearing
        if ( b > 1 ) b -= 1;
        if ( b < 0 ) b += 1;

        var degree = ( 1 - b ) * 360 + 90;

        navArrow.setAttribute(
            "transform",
            "rotate(" + degree + ", 119.5, 119.5)" );

        turnCalcTimeStamp = tStamp;

    }

    requestAnimationFrame( updateOrientation );

}


function updateNavigationData() {

    trek.api( 'navigation/status', updateNavigationDisplay );

}

// Setup animation to show orientation movement
requestAnimationFrame( updateOrientation );

// Always select the local system by default
$systemSelections[ 1 ].click();
updateNavigationData();

trek.registerDisplay( "Conn" );
trek.checkBlastDamage();
trek.playBridgeSound();
