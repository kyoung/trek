var $comDisplay = $("#comms");

// Top level menu selection
var $menues = $( "#submenuSelectors li" );
var $torpedoMenu = $( "#torpedoMenu" );
var $phaserMenu = $( "#phaserMenu" );
var $targetingMenu = $( "#targetingMenu" );
var $shieldMenu = $( "#shieldMenu" );
var $alertMenu = $( "#alertMenu" );

// Submenues
var $submenues = $( ".tactical-submenu" );
var $torpedoSubmenu = $( "#torpedoSubmenu" );
var $phaserSubmenu = $( "#phaserSubmenu" );
var $targetingSubmenu = $( "#targetingSubmenu" );
var $shieldSubmenu = $( "#shieldSubmenu" );
var $alertSubmenu = $( "#alertSubmenu" );

var $alerts = $( "#alertSubmenu li" );

var $shieldListing = $( "#shieldListing" );
var $torpedoBays = $( "#torpedoBays" );
var $yieldBars = $( '.yieldBar' );
var $zoomBars = $( '.zoomBar' );
var $shieldSwitch = $( "#raiseShields" );
var $targetName = $( "#targetName" );
var $alertStatus = $( "#redAlert" );
var $torpCount = $( "#torpCount" );
var $torpedoZoom = $( "#torpedoZoom" );
var $phaserZoom = $( "#phaserZoom" );
var $viewScreen = $( "#viewScreen" );
var $mainscreen = $( "#mainscreen" );
var $setTarget = $( "#setTarget" );
var $flyoutMenu = $( "#flyoutMenu" );
var $firePhasers = $( "#firePhasers" );
var $fireTorpedoes = $( "#fireTorpedo" );

var torpedoYield = 1;
var zoomLevel = 16;
var torpedoInventory = 96;
var weaponsTarget = '';
var zoom = "torpedo";


/* Menu action
----------------------------------------------------*/
$menues.click( function () {

    $menues.removeClass( 'lightblue' );
    $( this ).addClass( 'lightblue' );

    } );


$torpedoMenu.click( showTorpedoMenu );
function showTorpedoMenu () {

    setTacticalDisplay();
    $submenues.css( 'display', 'none' );
    $torpedoSubmenu.css( 'display', 'block' );
    zoom = 'torpedo';
    $viewScreen.attr(
        'src',
        'tactical_screen?zoom=' + zoom + '&zoom_level=' + zoomLevel );

}


$phaserMenu.click( showPhaserMenu );
function showPhaserMenu () {

    setTacticalDisplay();
    $submenues.css( 'display', 'none' );
    $phaserSubmenu.css( 'display', 'block' );
    zoom = 'phasers'
    $viewScreen.attr(
        'src',
        'tactical_screen?zoom=' + zoom + '&zoom_level=' + zoomLevel );

}


$alertMenu.click( showAlertMenu );
function showAlertMenu () {

    $submenues.css( 'display', 'none' );
    $alertSubmenu.css( 'display', 'block' );

    getAlertState();

}


$shieldMenu.click( showShieldMenu );
function showShieldMenu () {

    $submenues.css( 'display', 'none' );
    $shieldSubmenu.css( 'display', 'block' );
    getShieldStatus();

}


$targetingMenu.click( showTargetingMenu );
function showTargetingMenu () {

    $submenues.css( 'display', 'none' );
    $targetingSubmenu.css( 'display', 'block' );

}


/* Alert management
------------------------------------------------*/

function getAlertState () {

    updateAlertStatus = function ( alert ) {

        $alerts.removeClass( 'lightblue' );

        switch ( alert ) {

            case 'red':
                $( "#redAlert" ).addClass( 'lightblue' );
                break;

            case 'yellow':
                $( "#yellowAlert" ).addClass( 'lightblue' );
                break;

            case 'blue':
                $( "#blueAlert" ).addClass( 'lightblue' );
                break;

            case 'clear':
                $( "#clearAlert" ).addClass( 'lightblue' );
                break;

        }

    };

    trek.api( 'tactical/alert', updateAlertStatus );

}


$alerts.click( function () {

    var color = this.id.replace( /Alert/g, "" );
    trek.api( 'tactical/alert', { status : color }, 'POST', getAlertState );

    } );



/* Comms
------------------------------------------------*/

trek.socket.on( "hail", function ( data ) {

    $comDisplay.removeClass( "offline" );
    $comDisplay.addClass( "blink" );

    trek.playHail();

    } );


$comDisplay.click( displayCom );
function displayCom () {

    $viewScreen.attr( 'src', 'comm_screen' );
    $comDisplay.removeClass( "blink" );
    $comDisplay.addClass( "offline" );

}




/* Phaser management
------------------------------------------------*/

$firePhasers.click( function () {

    var onFire = function () {

        trek.playPhaser();
        getPhaserStatus();

    }

    trek.api( "tactical/phasers", {}, 'POST', onFire );

    } );


setInterval( getPhaserStatus, 1000 );
function getPhaserStatus () {

    trek.api( "tactical/phasers", displayPhaserStatus );

}


function displayPhaserStatus ( data ) {

    var tmpl = "<div><p class='descriptiveText'>{{ name }}</p><div class='tactical-phaser-charge-frame'><span class='tactical-phaser-charge' style='width: {{ width }}%;'>&nbsp;</span></div></div>";

    var $status = $( "#phaserStatus" );
    $status.empty();

    _.each( data, function ( e ) {

        e.width = e.charge * 100;

        var $e = Mustache.render( tmpl, e );
        $status.append( $e );

        } );

}


/* Torpedo management
------------------------------------------------*/

function loadTorpedoBay ( bayName ) {

    trek.api(
        "tactical/loadTorpedo",
        { tube : bayName },
        updateState );

}


function updateTorpedo () {

    $torpCount.html( torpedoInventory );

}


function displayTorpedoBayStatus ( status ) {

    $torpedoBays.empty();

    var bayTmpl = "<div class='tactical-torpedo-bay {{class_}}'>{{number}}: {{status_}}</div>";

    _.each( status, function ( e ) {

        var render = {
            class_ : 'tactical-torpedo-bay-' + e.status.toLowerCase(),
            name : e.name.replace( /Torpedo/g, "" ),
            number : e.name.replace( /Torpedo Bay /g, "" ),
            status_ : e.status.toUpperCase()

        };

        var $torpBay = $( Mustache.render( bayTmpl, render ) );

        if ( e.status == "Empty" ) {

            $torpBay.click( function () {

                loadTorpedoBay( e.name );

                } );

        }

        $torpedoBays.append( $torpBay );

        } );

}


$fireTorpedoes.click( function () {

    kapla = function () {

        trek.playTorpedo();
        updateState();

    }

    trek.api(
        "tactical/fireTorpedo",
        { yield : torpedoYield },
        kapla );

    } )


$yieldBars.mouseover( function () {

    torpedoYield = parseInt( $( this ).attr( "id" ) );

    _.each( $yieldBars, function( e ) {

        if ( parseInt( e.id ) <= torpedoYield ) {

            $( e ).addClass( "selected" );

        } else {

            $( e ).removeClass( "selected" );

        }

        } );

    } );



/* Target management
------------------------------------------------*/

function updateTarget ( deck, section ) {

    var system = arguments.length > 0 ? " (deck " + deck + " section " + section + ")" : "";

    if ( deck == 'undefined' || deck == undefined ) {

        system = "";

    } else {

        console.log( deck );

    }

    if ( typeof weaponsTarget != 'undefined' ) {

        $targetName.html( weaponsTarget.replace( /_/g, " " ) + system );

    }

}


$( "#setSubTarget" ).click( getSubsystems );
function getSubsystems () {

    if ( typeof weaponsTarget == 'undefined' ) {

        trek.displayRed( "Select a weapons target before subsystems" );
        return;

    }

    trek.api( "tactical/target", parseTargetData );

}


function parseTargetData ( targetData ) {

    console.log( targetData );
    $flyoutMenu.empty();
    var $submenu = $( "<ul class='menu x1'></ul>" );
    var subTargetTemplate = "<li class='green' id='{{ name }}'>{{ name }}: Deck {{ deck }}, Section {{ section }}</li>";

    _.each( targetData, function ( e ) {

        var $subsystem = $( Mustache.render( subTargetTemplate, e ) );
        $subsystem.click( function () {

            updateTarget( e.deck, e.section );

            trek.api(
                "tactical/target",
                { target : weaponsTarget, deck : e.deck, section : e.section },
                'POST',
                updateState );

            $flyoutMenu.empty();

            } );

        $submenu.append( $subsystem );

        } );

    $flyoutMenu.append( $submenu );

}


function buildTargetMenu ( scanData ) {

    $flyoutMenu.empty();
    var submenu = $( "<ul class='menu x1'></ul>" );
    var targetTemplate = "<li class='green' id='{{ name }}'>{{ prettyName }}</li>";

    _.each( scanData, function ( s ) {

        if ( s.name == shipName || s.name == "" || s.name == undefined ) {

            return;

        }

        s.prettyName = s.name.replace( /_/g, " " );
        var $target = $( Mustache.render( targetTemplate, s ) );

        $target.click( function () {

            weaponsTarget = this.id;
            updateTarget();

            trek.api(
                "tactical/target",
                { target : this.id },
                'POST',
                updateState );

            $flyoutMenu.empty();

            } );

        submenu.append( $target );

        } );

    $flyoutMenu.append( submenu );

}


function getTargets () {

    trek.api( "tactical/scan", buildTargetMenu );

}


$setTarget.click( getTargets );




/* Tactical display management
------------------------------------------------*/


$zoomBars.mouseover( function () {

    zoomLevel = parseInt( $( this ).attr( "id" ) );

    _.each( $zoomBars, function ( e ) {

        if ( parseInt( e.id ) <= zoomLevel ) {

            $( e ).addClass( "selected" );

        } else {

            $( e ).removeClass( "selected" );

        }

        } );

    setTacticalDisplay();

    } );


function setTacticalDisplay () {

    var q_string = "?zoom=" + zoom + "&zoom_level=" + zoomLevel;
    $viewScreen.attr( 'src', 'tactical_screen' + q_string );

}


/* Shield management
------------------------------------------------*/

function toggleShields () {

    var set_online = $shieldSwitch.hasClass( "lightgreen" ) ? false : true;

    trek.api(
        "tactical/shields",
        { online : set_online },
        "POST",
        getShieldStatus );

}


function parseShieldState ( data ) {

    shieldTemplate = "<div><p class='descriptiveText'>{{ name }}</p><div class='tactical-shield-charge-frame'><span class='tactical-shield-charge' style='width: {{ width }}%;'>&nbsp;</span></div></div>";
    $shieldListing.empty();

    var are_online = false;
    _.each( data, function ( e ) {

        are_online = are_online || ( e.online && e.active )
        e.width = e.charge * 100;
        var $shieldReading = $( Mustache.render( shieldTemplate, e ) );
        $shieldListing.append( $shieldReading );

        } );

    var text = are_online ? "Lower Shields" : "Raise Shields";

    if ( are_online ) {

        $shieldSwitch.addClass( "lightgreen" );

    } else {

        $shieldSwitch.removeClass( "lightgreen" );

    }

    $shieldSwitch.html( text );

}


function getShieldStatus () {

    trek.api( "tactical/shields", parseShieldState );

}


setInterval( getShieldStatus, 1000 );
$shieldSwitch.click( toggleShields );


/* Misc
------------------------------------------------*/

function parseTacticalState ( data ) {

    weaponsTarget = data.weapons_target;
    torpedoInventory = data.torpedo_inventory;

    displayTorpedoBayStatus( data.torpedo_bay_status );

    if ( data.shields_status ) {

        $shieldSwitch.addClass( "lightBlue" );

    } else {

        $shieldSwitch.removeClass( "lightBlue" );

    }

    if ( data.alertStatus == "red" ) {

        $alertStatus.addClass( "red" );

    } else {

        $alertStatus.removeClass("red");

    }



    updateTarget( data.weapons_target_deck, data.weapons_target_section );

    updateTorpedo();

}


function updateState() {

    trek.api(
        "tactical/status",
        parseTacticalState );

}


$mainscreen.click( function () {

    trek.api(
        "command/mainViewer",
        {
            screen: "tactical_screen",
            zoom: zoom,
            zoom_level: zoomLevel
        },
        'POST',
        updateState );

    } );


$torpedoMenu.click();

updateState();
setInterval( updateState, 1000 );

trek.registerDisplay( "Tactical" );
trek.checkBlastDamage();
trek.playBridgeSound();
