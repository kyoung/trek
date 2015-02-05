
var alerts;

var camera;
var scene;
var renderer;
var blueLineMat, redLineMat;
var shipGeometry;
var meshScale;
var globalLight;
var loader;
var shipDorsal, shipStarboard;

var $dataDisplay = $( "#dataDisplay" );
var $shipDisplay = $( "#shipDisplay" );
var $loading = $( "#loading" );
var $alertText = $( "#alertText" );

var currentColor = 'blue';
var dismissed = false;
var loadAlertShowing = false;
var meshLoaded = false;


function loadInternalScan () {

    trek.api( 'science/internal-scan', displayInternalScan );

}


function displayInternalScan ( data ) {

    alerts = data.alerts;

    // display the alerts information
    displayRadiation( alerts.radiation );

    meshScale = data.meshScale;

    if ( !meshLoaded ) {

        loadShipSchematics( data.mesh );

    }

}


function loadShipSchematics ( meshName ) {

    meshLoaded = true;

    var w;
    var h;
    w = $shipDisplay.width();
    h = $shipDisplay.height();

    camera = new THREE.OrthographicCamera( -10, 10, 10, -10, 1, 100 );
    scene = new THREE.Scene();
    scene.add( camera );
    renderer = new THREE.WebGLRenderer();
    renderer.setSize( w, h );
    $shipDisplay.append( renderer.domElement );

    blueLineMat = new THREE.MeshBasicMaterial( { wireframe : true, color : "#60DDF7" } );
    redLineMat = new THREE.MeshBasicMaterial( { wireframe : true, color : "#B30900" } );

    globalLight = new THREE.AmbientLight( 0x777777 );
    scene.add( globalLight );

    loader = new THREE.JSONLoader( true );
    loader.load(
        "static/mesh/" + meshName,
        function( geo, mat ) {

            console.log( "geometry loaded" );

            shipGeometry = geo;
            $loading.remove();

            if ( currentColor == 'blue' ) {

                drawShips( blueLineMat );

            } else {

                drawShips( redLineMat );

            }

        } );

}


function drawShips ( material ) {

    if ( scene === undefined ) {

        return;

    }

    console.log( "drawing Ship..." );

    scene.remove( shipDorsal );
    scene.remove( shipStarboard );

    shipDorsal = new THREE.Mesh( shipGeometry, material );
    shipStarboard = new THREE.Mesh( shipGeometry, material );

    shipStarboard.position.set( 0, 5, -7 );
    shipDorsal.position.set( 0, -5, -7 );

    shipStarboard.scale.x = shipStarboard.scale.y = shipStarboard.scale.z = meshScale;
    shipDorsal.scale.x = shipDorsal.scale.y = shipDorsal.scale.z = meshScale;

    shipDorsal.rotateX( Math.PI / 2 );
    shipDorsal.rotateY( Math.PI / 2 );

    shipStarboard.rotateY( Math.PI / 2 );

    scene.add( shipDorsal );
    scene.add( shipStarboard );

    renderer.render( scene, camera );

}


function drawWarning (radiationReport ) {

    console.log( radiationReport );
    var radiatedSections = [];
    _.each( radiationReport, function ( v, k, l ) {

        if ( v ) {

            radiatedSections.push( k );

        }

        } );

    var decks = radiatedSections.join( ", " );

    $alertText.html( "<div class='science-internal-title'>Radiation Alert</div><div class='science-internal-detail'>" + decks + " Decks in Danger</div>" );

}


function displayRadiation ( radiationReport ) {

    var radiatedSections = [];
    var report = _.each( radiationReport, function ( v, k, l ) {

        if ( v ) {

            radiatedSections.push( k )

        }

        } );

    if ( radiatedSections.length == 0 ) {

        if ( currentColor === 'red' ) {

            drawShips( blueLineMat );
            currentColor = 'blue';
            $alertText.html( "" );

        }
        return;

    }

    if ( currentColor === 'blue' ) {

        currentColor = 'red';
        drawShips( redLineMat );
        drawWarning( radiationReport );

    }

    var message = "Radiation detected in ";
    var decks = radiatedSections.join( ", " );
    message += decks + " decks.";

    if ( !loadAlertShowing && !dismissed ) {

        trek.displayRed( message, function () {

            dismissed = true;

            } );
        loadAlertShowing = true;

    }

}


function displayAlarm ( alert ) {


}


trek.socket.on( "internal-alarm", displayAlarm );

// Disable alert screen
trek.onAlert( function() {

    return;

    } );

loadInternalScan();
setInterval( loadInternalScan, 1000 );
