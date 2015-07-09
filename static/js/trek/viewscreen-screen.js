var targetURL = "";
var shipRotation = 0;
var lightAngle = 0.75;

var torpedos = [];


// default skybox
var skyboxImage = 'static/images/Milky_way.jpg';

// the main three.js components
var camera, scene, renderer;

var visibleRadius = 4000;

var loader = new THREE.JSONLoader( true );

// stars!
var particle_system;
var warpSystem = [];
var atWarp = false;

var skyGeometry = new THREE.SphereGeometry( 3000, 400, 400 );
var skyBox;

var station;
var ship;
var target;
var systemStar;
var globalLight;

var cameraTurnRate, cameraTurning;
var cameraEasing, cameraElapsed;

var navigationData;


var starViews = [
    "undefined",
    "forward",
    "aft"
];

trek.api(
    "navigation/stelar-telemetry",
    { target : targetName },
    parseTelemetry );
    

function parseTelemetry ( data ) {

    if ( amLookingAtTarget() ) {

        var netBearingToLight = data.bearing_to_target.bearing + data.bearing_to_star.bearing;

        shipRotation = data.bearing_to_viewer.bearing;
        lightAngle = netBearingToLight;

        if ( lightAngle > 1 ) {

            lightAngle -= 1;

        }

        targetURL = data.target_model;

    }

    skyboxImage = data.skybox;

    init();

}


window.requestAnimFrame = ( function () {

    return window.requestAnimationFrame       ||
           window.webkitRequestAnimationFrame ||
           window.mozRequestAnimationFrame    ||
           function ( callback ) {

               window.setTimeout( callback, 1000 / 60 );

           };

    } )();


function init () {

    // Camera params :
    // field of view, aspect ratio for render output, near and far clipping plane.
    camera = new THREE.PerspectiveCamera(
        80,
        window.innerWidth / window.innerHeight,
        0.5,
        visibleRadius );

    if ( targetName == "aft" ) {

        camera.rotation.y = Math.PI;

    }

    scene = new THREE.Scene();
    scene.add( camera );
    renderer = new THREE.WebGLRenderer( { antialias : true, alpha : true } );
    renderer.setSize( window.innerWidth, window.innerHeight );

    // the renderer's canvas domElement is added to the body
    document.body.appendChild( renderer.domElement );

    makeParticles();
    showSun();
    loadGalaxy();

    if ( targetURL != "" ) {

        showTarget();

    }

    globalLight = new THREE.AmbientLight( 0x333333 );

    scene.add( globalLight );

    requestAnimationFrame( update );

}


function loadGalaxy () {

    var uniforms;
    var material;

    THREE.ImageUtils.loadTexture(
        skyboxImage,
        THREE.SphericalReflectionMapping,
        function ( texture ) {

            uniforms = {
              texture: { type : 't', value :  texture }
            };

            material = new THREE.ShaderMaterial( {
              uniforms : uniforms,
              vertexShader : document.getElementById( 'sky-vertex' ).textContent,
              fragmentShader : document.getElementById( 'sky-fragment' ).textContent
            } );

            skyBox = new THREE.Mesh( skyGeometry, material );
            skyBox.scale.set( -1, 1, 1 );
            skyBox.rotation.order = 'XZY';
            skyBox.renderDepth = 1000.0;
            skyBox.position.set( 0, 0, 0 );
            scene.add( skyBox );

        } );

}


function update ( stamp ) {

    _.each( torpedos, function ( e ) {

        if ( e.position.z < -200 ) {

            torpedos = _.filter( torpedos, function ( t ) {

                return e != t;

                } );
            scene.remove( e );

        }

        e.position.z -= ( 7 - 1.5 );

        _.each( e.lensFlares, function ( f ) {

            f.size /= 1.1;

            } );

    } );


    if ( cameraTurning ) {

        // Rotate the stars, not the camera
        // rotations are in Radians
        // particle_system.rotation.y -= cameraTurnRate;

        if ( skyBox != undefined ) {

            skyBox.rotation.y -= cameraTurnRate;

        }

    }

    updateWarpSystem();

    // and render the scene from the perspective of the camera
    renderer.render( scene, camera );
    requestAnimationFrame( update );

}


function updateWarpSystem () {

    _.each( warpSystem, calculateNewWarpLinePosition )

}


function calculateNewWarpLinePosition ( line ) {

    if ( atWarp ) {

        line.position.z += 100;

        if ( line.position.z > visibleRadius + 1000 ) {

            // cycle back
            line.position.z = visibleRadius * -3 * Math.random();

        }

    } else {

        if ( line.position.z < visibleRadius + 1000) {

            // animate off the screen
            line.position.z += 100;

        } else {

            scene.remove( line );

        }

    }

}


function showSun () {

    // TODO fix this hack, and orient the backgroud sphere (which
    // contains a drawing of the star) to the light source

    systemStar = new THREE.PointLight( 0xffddff, 1, 0 );
    // position hack until we come up with the real trig:
    var best_eighth = Math.round( lightAngle * 8 ) / 8;

    switch ( best_eighth ) {

        case 0:
            systemStar.position.set( 0, 0, -3000 );
            break;

        case 0.125:
            systemStar.position.set( -2121, 0, -2121 );
            break;

        case 0.25:
            systemStar.position.set( -3000, 0, 0 );
            break;

        case 0.375:
            systemStar.position.set( -2121, 0, 2121 );
            break;

        case 0.5:
            systemStar.position.set( 0, 0, 3000 );
            break;

        case 0.625:
            systemStar.position.set( 2121, 0, 2121 );
            break;

        case 0.75:
            systemStar.position.set( 3000, 0, 0 );
            break;

        case 0.875:
            systemStar.position.set( 2121, 0, -2121 );
            break;

        case 1:
            systemStar.position.set( 0, 0, -3000 );
            break;

    }

    scene.add( systemStar );

};


function makeParticles () {

    drawWarpTunnel();
    // drawStars(); // disabled while we test the new skybox background

}


function goToWarp () {

    if ( atWarp ) {

        return;

    }

    _.each( warpSystem, function( line ) {

        line.position.z = visibleRadius * -3 * Math.random() - visibleRadius;
        scene.add( line );

    } );

    atWarp = true;

}


function dropOutOfWarp () {

    atWarp = false;

}


function drawWarpTunnel () {

    // Assumes the camera rotation is zero

    var lineCount = 1000;

    var material = new THREE.MeshBasicMaterial( { wireframe : true, color : "#FFFFFF" } );

    for ( var i = 0; i < lineCount; i ++ ) {

        lineGeometry = new THREE.Geometry();
        x = Math.random() * visibleRadius * 2 - visibleRadius;
        y = Math.random() * visibleRadius * 2 - visibleRadius;
        // push back into z plane
        z = Math.random() * visibleRadius * -3 - visibleRadius;

        lineGeometry.vertices.push( new THREE.Vector3( 0, 0, 0 ) );
        lineGeometry.vertices.push( new THREE.Vector3( 0, 0, -1000 ) );

        var line = new THREE.Line( lineGeometry, material );

        line.position.x = x;
        line.position.y = y;
        line.position.z = z;

        warpSystem.push( line );

    }

}


function drawStars () {

    // TODO: generate the stars in the server on game startup, and show them here via a JSON call

    var particle, material;
    var starcount = 10000;

    // we're gonna move from z position -1000 (far away)
    // to 1000 (where the camera is) and add a random particle at every pos.
    var particle_geo = new THREE.Geometry();
    // we make a particle material and pass through the
    // colour and custom particle render function we defined.
    material = new THREE.ParticleSystemMaterial( { vertexColors : true } );

    for ( var i = 0; i < starcount; i ++ ) {

        // make the particle
        particle = new THREE.Vector3();

        var phi = Math.random() * 2 * Math.PI;
        var z = Math.random() * visibleRadius * 2 - visibleRadius;
        var theta = Math.asin( z / visibleRadius );
        particle.x = visibleRadius * Math.cos( theta ) * Math.cos( phi );
        particle.y = visibleRadius * Math.cos( theta ) * Math.sin( phi );
        particle.z = z;

        // scale it up a bit
        // particle.scale.x = particle.scale.y = Math.random() * 3;

        // add it to the scene
        //scene.add( particle );

        // and to the array of particles.
        particle_geo.vertices.push( particle );

    }

    var colours = []
    for ( var i = 0; i < particle_geo.vertices.length; i ++ ) {

        colours[ i ] = new THREE.Color();
        colours[ i ].setHSL(
            Math.random(),
            Math.random(),
            Math.random() );

    }
    particle_geo.colors = colours;

    particle_system = new THREE.ParticleSystem( particle_geo, material );
    particle_system.scale.x = particle_system.scale.y = particle_system.scale.z = 0.1;

    scene.add( particle_system );

}


function showTarget () {

    loader.load( "/static/mesh/" + targetURL, function( geo, mat ) {

        target = new THREE.Mesh( geo, new THREE.MeshFaceMaterial( mat ) );
        target.rotation.y = shipRotation * 2 * Math.PI;
        target.position.set( 0, 0, -7 );
        scene.add( target );

    } );

}


// In the event of a Torpedo being fired at what we're looking at
function showTorpedoHit () {

    // Assume we fired the torpedo for now
    // Starting position is the bottom of the screen
    var x = Math.random() * 20 - 10;
    var y = -10;
    var z = 0;

    var textureFlare0 = THREE.ImageUtils.loadTexture( "static/textures/lensflare0.png" );
    var textureFlare2 = THREE.ImageUtils.loadTexture( "static/textures/lensflare1.png" );
    var textureFlare3 = THREE.ImageUtils.loadTexture( "static/textures/lensflare2.png" );

    var flareColor = new THREE.Color( 0xff0000 );

    var torpedo = new THREE.LensFlare( textureFlare0, 350, 0.0, THREE.AdditiveBlending, flareColor );

    torpedo.add( textureFlare2, 251, 0.0, THREE.AdditiveBlending );
    torpedo.add( textureFlare2, 251, 0.0, THREE.AdditiveBlending );
    torpedo.add( textureFlare2, 251, 0.0, THREE.AdditiveBlending );

    torpedo.add( textureFlare3, 30, 0.6, THREE.AdditiveBlending );
    torpedo.add( textureFlare3, 35, 0.7, THREE.AdditiveBlending );
    torpedo.add( textureFlare3, 60, 0.9, THREE.AdditiveBlending );
    torpedo.add( textureFlare3, 35, 1.0, THREE.AdditiveBlending );

    torpedo.customUpdateCallback = torpedoUpdateCallback;
    torpedo.position.set( x, y, z );

    console.log( torpedo );
    scene.add( torpedo );
    torpedos.push ( torpedo );

    setTimeout( whiteFlash, 2000 );

}


// An explosion has occured; white flash!
function whiteFlash () {

    var $white = $( "<div class='whiteout'></div>" );
    $( "body" ).append( $white );
    $white.fadeOut( 2000 );

}


function torpedoUpdateCallback ( object ) {

    var f, fl = object.lensFlares.length;
    var flare;
    var vecX = -object.positionScreen.x * 2;
    var vecY = -object.positionScreen.y * 2;


    for ( f = 0; f < fl; f ++ ) {

           flare = object.lensFlares[ f ];

           flare.x = object.positionScreen.x + vecX * flare.distance;
           flare.y = object.positionScreen.y + vecY * flare.distance;

           flare.rotation = 0;

    }

    object.lensFlares[ 2 ].y += 0.025;
    object.lensFlares[ 3 ].rotation = object.positionScreen.x * 0.5 + THREE.Math.degToRad( 45 );

}


function showDestruction () {

    // The targetName is apparently destroyed.
    // For now, just remove it.
    // TODO: Show debris and secondary explosions

    scene.remove( target );

}


function processSpeedData ( navData ) {

    // If we're not just looking at stars, don't bother
    if ( amLookingAtTarget() ) {

        return;

    }

    if ( navData.set_speed == "warp" ) {

        goToWarp();

    } else {

        dropOutOfWarp();

    }

}


function processTurnState ( navData ) {

    if ( amLookingAtTarget() ) {

        return;

    }

    // Process periodic updates to state (IE turn thrusters)

    // Translate circle rotations into radians
    var rotation = navData.rotation;
    var turnSpeed = rotation.bearing;

    if ( turnSpeed == 0 ) {

        cameraTurning = false;
        return;

    }

    cameraTurning = true;
    cameraTurnRate = turnSpeed * Math.PI / 15 * 1000;

}


function processTurnDisplay ( navData ) {

    console.log( "Turning detected" );

    // Process turn events (IE course plots)

    turnDirection = navData.turn_direction;
    turnDuration = navData.turn_duration;
    turnDistance = navData.turn_distance;

    // skip if the view isn't a rotating one
    if ( amLookingAtTarget() ) {

        return;

    }

    cameraTurning = true;
    // how far does the camera turn each frame?
    var totalRotation = turnDistance * 2 * Math.PI;
    var framesOfRotation = turnDuration / 1000 * 15;
    cameraTurnRate = totalRotation / framesOfRotation;
    if ( turnDirection == "CW" ) {

        cameraTurnRate *= -1;

    }

    setTimeout(
        function () {

            cameraTurning = false;

        },
        turnDuration );

}


function amLookingAtTarget () {

    return _.indexOf( starViews, targetName ) == -1;

}


trek.api(
    "navigation/status",
    function ( data ) {

        navigationData = data;
        if ( navigationData.warp > 0 && !atWarp ) {

            goToWarp();

        }

    } );


trek.socket.on( "Display", function ( data ) {

    var message = data.split( ":" );

    if ( message[ 1 ] != targetName ) {

        return;

    }

    switch ( message[ 0 ] ) {

        case "Torpedo hitting":
            showTorpedoHit();
            break;

        case "Destroyed":
            showDestruction();
            break;

    };

    } );


trek.socket.on( "Navigation", function ( navData ) {


    if ( _.has( navData, "turn_direction" ) ) {

        processTurnDisplay( navData );

    }

    if ( _.has( navData, "set_speed" ) ) {

        processSpeedData( navData );

    }

    } );


trek.socket.on( "Turning", function ( navData ) {

    // this is intermitent, but includes the current
    // turn rate

    processTurnState( navData );

    } );


trek.onAlert( function () {

    return;

    } );
