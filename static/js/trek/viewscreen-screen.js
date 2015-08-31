var targetURL = "";
var shipRotation = 0;
var lightAngle = 0.75;

var renderLock = false;  // attempt at a perf improvement

var torpedos = [];

// the main three.js components
var camera, scene, renderer;

var visibleRadius = 4000;

var loader = new THREE.JSONLoader( true );

// stars!
var particle_system;
var warpSystem = [];
var warpGroup = new THREE.Object3D();
var isWarpGroupAdded = false;
var atWarp = false;

var skyGeometry = new THREE.SphereGeometry( 3000, 400, 400 );
var skyBox;

var skySpheres = {};  // suns and planets... etc

var station;
var ship;
var target;
var systemStar;
var systemStarMesh;
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
    init );

window.requestAnimFrame = ( function () {

    return window.requestAnimationFrame       ||
           window.webkitRequestAnimationFrame ||
           window.mozRequestAnimationFrame    ||
           function ( callback ) {

               window.setTimeout( callback, 1000 / 60 );

           };

    } )();


function init ( data ) {

    console.log( data );

    // # Proposed refactor:
    // #
    // #   {
    // #       skyboxes : [
    // #           { url : "", alpha_url : "", rotation : 0 }, // allows for super imposed nebula, and the possibility of movement
    // #       ],
    // #       planets : [
    // #           {
    // #               size : [ radius],
    // #               distance : [distance],
    // #               surface_color : #3e8,
    // #               atmosphere_color : #3f9,
    // #               type : "gas|rock"  // can we make bands?,
    // #               bearing : [bearing],
    // #               rings : [
    // #                   { radius : NNN, color : #3e8 },
    // #               ]
    // #           }
    // #       ],  // includes planets and moons
    // #       stars : [
    // #           { size : [radius], distance : [distance], primary_color : #fff, bearing : [bearing] }
    // #       ],   // 50% of systems are binary
    // #       target : { mesh_url: "" , rotation : r, bearing : [bearing] } | undefined,
    // #       # direction : "forward|backward|left|right",
    // #       # at_warp : true // gets over-ridden by socket calls
    // #   }

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
    showSuns( data.stars );
    showPlanets( data.planets );
    loadGalaxy( data.skyboxes );

    if ( data.target !== undefined ) {

        console.log( 'Target data found' );
        shipRotation = data.target.rotation;
        targetURL = data.target.mesh_url;
        showTarget( data.target );
        // var netBearingToLight = data.bearing_to_target.bearing + data.bearing_to_star.bearing;
        // lightAngle = netBearingToLight;
        //
        // if ( lightAngle > 1 ) {
        //
        //     lightAngle -= 1;
        //
        // }

    }

    globalLight = new THREE.AmbientLight( 0x111111 );

    scene.add( globalLight );
    requestAnimationFrame( update );

    setInterval( function () {

        trek.api(
            "navigation/stelar-telemetry",
            { target : targetName },
            updateSpheres );

    }, 250 );

}


function loadGalaxy ( skyboxes ) {

    // TODO just use the first one for now
    var skyboxImage = skyboxes[ 0 ].url;

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


function showPlanets ( planets ) {

    // #     planets = [
    // #           {
    // #               size : [ radius],
    // #               distance : [distance],
    // #               surface_color : #3e8,
    // #               atmosphere_color : #3f9,
    // #               type : "gas|rock"  // can we make bands?,
    // #               bearing : [bearing],
    // #               rings : [
    // #                   { radius : NNN, color : #3e8 },
    // #               ]
    // #           } ]

    var displayRadius = -800;

    _.each( planets, function ( p ) {

        var apparentRadius = p.size / p.distance * displayRadius * -1;

        if ( apparentRadius < 1 ) {

            return;

        }

        console.log( "name: " + p.name );
        console.log( "distance: " + p.distance );
        console.log( "apparent Radius: " + apparentRadius );

        var radianRotation = p.bearing.bearing * 2 * Math.PI;
        var x = Math.sin( radianRotation ) * displayRadius;
        var z = Math.cos( radianRotation ) * displayRadius;

        newPlanet( apparentRadius, p.type, p.surface_color, p.atmosphere_color, function( planet ) {

            planet.position.set( x, 0, z );
            scene.add( planet );
            skySpheres[ p.name ] = planet;

        } );

    } );


}

function showSuns ( stars ) {

    // negative because of the wonkiness of display coordinates
    var displayRadius = -900;

    _.each( stars, function ( s ) {

        var newStarLight = new THREE.PointLight( s.primary_color, 1, 0 );
        var whiteStarLight = new THREE.PointLight( "#ffffff", 1, 0 );

        var radianRotation = s.bearing.bearing * 2 * Math.PI;
        var x = Math.sin( radianRotation ) * displayRadius;
        var z = Math.cos( radianRotation ) * displayRadius;

        newStarLight.position.set( x, 0, z );
        whiteStarLight.position.set(x, 0, z);

        var apparentRadius = s.size / s.distance * displayRadius * -1;
        var geometry = new THREE.SphereGeometry( apparentRadius, 32, 32 );
        var material = new THREE.MeshBasicMaterial( { color : '#ffffff' });//s.primary_color } );
        var sphere = new THREE.Mesh( geometry, material );
        sphere.position.set( x, 0, z );

        // lens flare
        var textureFlare0 = THREE.ImageUtils.loadTexture( "static/textures/lensflare0.png" );
        var textureFlare2 = THREE.ImageUtils.loadTexture( "static/textures/lensflare1.png" );
        var textureFlare3 = THREE.ImageUtils.loadTexture( "static/textures/lensflare2.png" );
        var flareColor = new THREE.Color( s.primary_color );
        console.log("stellar apparent Radius: " + apparentRadius);
        var flare = new THREE.LensFlare( textureFlare0, apparentRadius * 75, 0.0, THREE.AdditiveBlending, flareColor );
        flare.add( textureFlare2, 251, 0.0, THREE.AdditiveBlending, flareColor );
        flare.add( textureFlare2, 251, 0.0, THREE.AdditiveBlending, flareColor );
        flare.add( textureFlare2, 251, 0.0, THREE.AdditiveBlending, flareColor );
        flare.add( textureFlare3, 30, 0.6, THREE.AdditiveBlending, flareColor );
        flare.add( textureFlare3, 35, 0.7, THREE.AdditiveBlending, flareColor );
        flare.add( textureFlare3, 60, 0.9, THREE.AdditiveBlending, flareColor );
        flare.add( textureFlare3, 35, 1.0, THREE.AdditiveBlending, flareColor );
        var shortRatio = 10;
        flare.position.set( x/shortRatio, 0, z/shortRatio );

        scene.add( flare );
        //scene.add( sphere );
        scene.add( newStarLight );
        scene.add( whiteStarLight );

    } );

};


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

        camera.rotation.y += cameraTurnRate;

    }

    updateWarpSystem();

    if ( !renderLock ) {

        // and render the scene from the perspective of the camera
        renderer.render( scene, camera );

    }

    requestAnimationFrame( update );

}

function updateSpheres ( data ) {

    // # Proposed refactor:
    // #
    // #   {
    // #       ...
    // #       planets : [
    // #           {
    // #               name : ,
    // #               size : [ radius],
    // #               distance : [distance],
    // #               surface_color : #3e8,
    // #               atmosphere_color : #3f9,
    // #               type : "gas|rock"  // can we make bands?,
    // #               bearing : [bearing],
    // #               rings : [
    // #                   { radius : NNN, color : #3e8 },
    // #               ]
    // #           }
    // #       ],  // includes planets and moons
    // #       stars : [
    // #           { size : [radius], distance : [distance], primary_color : #fff, bearing : [bearing] }
    // #       ],   // 50% of systems are binary
    // #      ...
    // #   }

    var displayRadius = -800;

    _.each( data.planets, function ( p ) {

        var apparentRadius = p.size / p.distance * displayRadius * -1;

        if ( apparentRadius < 1 ) {

            if ( _.has( skySpheres, p.name ) ) {

                scene.remove( skySpheres[ p.name ] );

            }

            return;

        }

        var radianRotation = p.bearing.bearing * 2 * Math.PI;
        var x = Math.sin( radianRotation ) * displayRadius;
        var z = Math.cos( radianRotation ) * displayRadius;

        if ( _.has( skySpheres, p.name ) ) {

            var s = skySpheres[ p.name ]
            var scale = apparentRadius / s.geometry.boundingSphere.radius;

            if ( scale != 1 ) {

                s.scale = new THREE.Vector3( scale, scale, scale );

            }

            s.position.set( x, 0, z );
            scene.add( s );

        } else {

            var geometry = new THREE.SphereGeometry( apparentRadius, 32, 32 );
            var material = newPlanetMaterial( p.surface_color, p.atmosphere_color );
            var sphere = new THREE.Mesh( geometry, material );
            sphere.position.set( x, 0, z );

            scene.add( sphere );

            skySpheres[ p.name ] = sphere;

        }

    } );

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

        }

    }

}


function makeParticles () {

    drawWarpTunnel();

}


function goToWarp () {

    renderLock = false;

    if ( atWarp ) {

        return;

    }

    _.each( warpSystem, function( line ) {

        line.position.z = visibleRadius * -3 * Math.random() - visibleRadius;

    } );

    if ( !isWarpGroupAdded ) {

        scene.add( warpGroup );

    }

    warpGroup.rotation.y = camera.rotation.y;
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

        warpGroup.add( line );
        warpSystem.push( line );

    }

}


function showTarget ( targetData ) {

    // target : { mesh_url: "" , rotation : r, bearing : [bearing] } | undefined
    loader.load( "/static/mesh/" + targetData.mesh_url, function( geo, mat ) {

        target = new THREE.Mesh( geo, new THREE.MeshFaceMaterial( mat ) );
        // we have to subtract the bearing to make up for the rotation added by
        // turning our camera towards the target
        target.rotation.y = ( targetData.rotation.bearing - targetData.bearing.bearing ) * 2 * Math.PI;

        // calculate these, and then tell the camera to "look at" the target
        var theta = targetData.bearing.bearing * Math.PI * 2;
        var distanceFromCamera = 10;
        var x = distanceFromCamera * Math.sin( theta );
        var z = -distanceFromCamera * Math.cos( theta );
        target.position.set( x, 0, z );
        scene.add( target );

        camera.rotation.y = targetData.bearing.bearing * Math.PI * 2;

        console.log("Expected position: ");
        console.log( target.position );
        console.log("Turning to look by: " + camera.rotation.y );
        console.log( targetData );

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
