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
var closeMeshes = {};  // space dock, etc

var station;
var ship;
var target;
var systemStar;
var systemStarMesh;
var globalLight;

var cameraTurnRate, cameraTurning;
var frameTimeStamp = Date.now();
var cameraEasing, cameraElapsed;

var navigationData;

var stelarTelem;  // holding block for debugging telemetry geometry

var shipVelocity;

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
    // #               name :
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
    // #       meshes : [
    // #           { mesh_url : "", rotation : r, bearing : b, scale : s }
    // #       ],  // things are sometimes very close by... ie starbases
    // #       stars : [
    // #           { size : [radius], distance : [distance], primary_color : #fff, bearing : [bearing] }
    // #       ],   // 50% of systems are binary
    // #       target : { mesh_url: "" , rotation : r, bearing : [bearing] } | undefined,
    // #       # direction : "forward|backward|left|right",
    // #       # at_warp : true // gets over-ridden by socket calls
    // #       bearing : bearing  // abs bearing of ship... all other bearings are relative to this
    // #   }

    // Camera params :
    // field of view, aspect ratio for render output, near and far clipping plane.
    camera = new THREE.PerspectiveCamera(
        80,
        window.innerWidth / window.innerHeight,
        0.5,
        visibleRadius );
    camera.rotation.y = Math.PI * 2 * data.bearing.bearing;
    if ( targetName == "aft" ) camera.rotation.y += Math.PI;

    scene = new THREE.Scene();
    scene.add( camera );
    renderer = new THREE.WebGLRenderer( { antialias : true, alpha : true } );
    renderer.setSize( window.innerWidth, window.innerHeight );

    // the renderer's canvas domElement is added to the body
    document.body.appendChild( renderer.domElement );

    makeParticles();
    showSuns( data.stars, data.bearing );
    showPlanets( data.planets, data.bearing );
    loadGalaxy( data.skyboxes );

    if ( data.target !== undefined ) {

        console.log( 'Target data found' );
        shipRotation = data.target.rotation;
        targetURL = data.target.mesh_url;
        showTarget( data.target, data.bearing );
        // var netBearingToLight = data.bearing_to_target.bearing + data.bearing_to_star.bearing;
        // lightAngle = netBearingToLight;
        //
        // if ( lightAngle > 1 ) {
        //
        //     lightAngle -= 1;
        //
        // }

    } else {

        // let's check for meshes!
        for ( var i=0; i < data.meshes.length; i++ ) {
            showMesh( data.meshes[i], data.bearing )
        }

    }

    globalLight = new THREE.AmbientLight( 0x111111 );

    scene.add( globalLight );
    requestAnimationFrame( update );

    // TODO: Make this go through web sockets... or rather, have it be pushed
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


function getCoordinatesFromRotation ( bearing, refBearing ) {

    // returns { x : , y : } normalized to 1
    var b = ( bearing.bearing + refBearing.bearing ) * 2 * Math.PI;
    return {
        x : - Math.sin( b ),
        z : Math.cos( b )
    }

}


function showPlanets ( planets, referenceBearing ) {

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

        if ( apparentRadius < 1 ) return;

        console.log( "name: " + p.name );
        console.log( "distance: " + p.distance );
        console.log( "apparent Radius: " + apparentRadius );
        var normPoint = getCoordinatesFromRotation( p.bearing, referenceBearing );
        var x = normPoint.x * displayRadius;
        var z = normPoint.z * displayRadius;

        newPlanet( apparentRadius, p.type, p.surface_color, p.atmosphere_color, function( planet ) {

            planet.position.set( x, 0, z );
            scene.add( planet );
            skySpheres[ p.name ] = planet;

        } );

    } );


}


function showSuns ( stars, referenceBearing ) {

    // negative because of the wonkiness of display coordinates
    var displayRadius = -900;

    _.each( stars, function ( s ) {

        var star = new THREE.Object3D();
        var normPoint = getCoordinatesFromRotation( s.bearing, referenceBearing );
        var x = normPoint.x * displayRadius;
        var z = normPoint.z * displayRadius;
        star.position.set( x, 0, z );

        var newStarLight = new THREE.PointLight( s.primary_color, 1, 0 );
        var whiteStarLight = new THREE.PointLight( "#ffffff", 1, 0 );
        star.add( newStarLight );
        star.add( whiteStarLight );

        var apparentRadius = s.size / s.distance * displayRadius * -1;
        var geometry = new THREE.SphereGeometry( apparentRadius, 32, 32 );
        var material = new THREE.MeshBasicMaterial( { color : '#ffffff' });//s.primary_color } );
        var sphere = new THREE.Mesh( geometry, material );
        // star.add( sphere );
        scene.add( star );
        skySpheres[ s.name ] = star;

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
        skySpheres[ s.name + '_flare' ] = flare;

    } );

};

function showMesh ( meshParameters, referenceBearing ) {
    var url = meshParameters.mesh_url;
    var rotation = meshParameters.rotation;
    var bearing = meshParameters.bearing;
    console.log("loading mesh " + url)

    // target : { mesh_url: "" , rotation : r, bearing : [bearing] } | undefined
    loader.load( "/static/mesh/" + url, function( geo, mat ) {

        console.log("loaded")

        target = new THREE.Mesh( geo, new THREE.MeshFaceMaterial( mat ) );
        // we have to subtract the bearing to make up for the rotation added by
        // turning our camera towards the target
        target.rotation.y = ( rotation.bearing - bearing.bearing ) * 2 * Math.PI;

        var gameCoordinate = meshParameters.relative_position;
        // translate into threejs coordinate system
        var renderCoordinate = {
            x : gameCoordinate.x,
            y : gameCoordinate.z,
            z : gameCoordinate.y
        }
        target.position.set( renderCoordinate.x, renderCoordinate.y, renderCoordinate.z );
        scene.add( target );

        closeMeshes[ meshParameters.sensor_tag ] = target;

    } );

}


function update ( stamp ) {

    _.each( torpedos, function ( e ) {

        if ( e.position.z < -200 ) {

            torpedos = _.filter(
                torpedos,
                function ( t ) { return e != t; }
            );
            scene.remove( e );

        }

        e.position.z -= ( 7 - 1.5 );

        _.each(
            e.lensFlares,
            function ( f ) { f.size /= 1.1; }
        );

    } );

    if ( !amLookingAtTarget() ) {

        var now = Date.now();
        var delta_t = frameTimeStamp - Date.now();
        frameTimeStamp = now;
        if ( cameraTurning ) camera.rotation.y += ( cameraTurnRate * delta_t );

        updateWarpSystem();

    }

    // and render the scene from the perspective of the camera
    if ( !renderLock ) renderer.render( scene, camera );
    requestAnimationFrame( update );

}


function updateSpheres ( data ) {

    stelarTelem = data;

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
    // #      bearing : [ bearing ]
    // #   }

    var refBearing;
    if ( amLookingAtTarget() ) {

        refBearing = {
            bearing : data.target.bearing.bearing + data.bearing.bearing,
            mark : data.target.bearing.mark + data.bearing.mark
        }
        refBearing = data.bearing;

    } else {

        camera.rotation.y = data.bearing.bearing * Math.PI * 2;
        refBearing = data.bearing;

    }

    var displayRadius = -800;

    _.each( data.planets, function ( p ) {

        var apparentRadius = p.size / p.distance * displayRadius * -1;

        if ( apparentRadius < 1 ) {

            if ( _.has( skySpheres, p.name ) ) scene.remove( skySpheres[ p.name ] );
            return;

        }

        var normPoint = getCoordinatesFromRotation( p.bearing, refBearing );
        var x = normPoint.x * displayRadius;
        var z = normPoint.z * displayRadius;

        if ( _.has( skySpheres, p.name ) ) {

            var s = skySpheres[ p.name ]
            // TODO: this is a hack!
            var scale = apparentRadius / s.children[0].geometry.boundingSphere.radius;

            if ( scale != 1 ) s.scale = new THREE.Vector3( scale, scale, scale );

            s.position.set( x, 0, z );
            scene.add( s );

        } else {

            newPlanet(
                apparentRadius,
                p.type,
                p.surface_color,
                p.atmosphere_color,
                function( planet ) {

                    planet.position.set( x, 0, z );
                    scene.add( planet );
                    skySpheres[ p.name ] = planet;

                } );

        }

    } );

    // TODO refactor, this is so gross and messy I'm ashamed
    displayRadius = -900;
    _.each( data.stars, function ( s ) {

        var normPoint = getCoordinatesFromRotation( s.bearing, refBearing );
        var x = normPoint.x * displayRadius;
        var z = normPoint.z * displayRadius;
        skySpheres[ s.name ].position.set( x, 0, z );
        skySpheres[ s.name + '_flare' ].position.set( x/10, 0, z/10 );

    } );

    // TODO factor this out entirely

    _.each( data.meshes, function ( m ) {

        if ( closeMeshes.hasOwnProperty(m.sensor_tag) ) {

            var x = m.relative_position.x;
            var y = m.relative_position.z;
            var z = m.relative_position.y;

            closeMeshes[ m.sensor_tag ].position.set( x, y, z );

        } else {

            showMesh( m );

        }

    } );

    // remove outdated meshes
    var tags = _.map( data.meshes, function ( m ) { return m.sensor_tag } );
    _.each( closeMeshes, function( v, k ) {

        if ( tags.indexOf( k ) < 0 ) {

            scene.remove( closeMeshes[ k ] );
            delete closeMeshes[ k ];

        }

    } )

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

        // animate off the screen
        if ( line.position.z < visibleRadius + 1000) line.position.z += 100;


    }

}


function makeParticles () {

    drawWarpTunnel();

}


function goToWarp () {

    renderLock = false;
    if ( atWarp ) return;

    _.each( warpSystem, function( line ) {

        line.position.z = visibleRadius * -3 * Math.random() - visibleRadius;

    } );

    if ( !isWarpGroupAdded ) scene.add( warpGroup );
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


function showTarget ( targetData, referenceBearing ) {

    // target : { mesh_url: "" , rotation : r, bearing : [bearing] } | undefined
    loader.load( "/static/mesh/" + targetData.mesh_url, function( geo, mat ) {

        target = new THREE.Mesh( geo, new THREE.MeshFaceMaterial( mat ) );
        // we have to subtract the bearing to make up for the rotation added by
        // turning our camera towards the target
        target.rotation.y = ( targetData.rotation.bearing - targetData.bearing.bearing ) * 2 * Math.PI;

        // calculate these, and then tell the camera to "look at" the target
        var scalarCoordinates = getCoordinatesFromRotation( targetData.bearing, referenceBearing );
        var distanceFromCamera = 10;
        var x = distanceFromCamera * scalarCoordinates.x;
        var z = distanceFromCamera * scalarCoordinates.z;
        target.position.set( x, 0, z );
        scene.add( target );

        camera.rotation.y = ( referenceBearing.bearing + targetData.bearing.bearing ) * Math.PI * 2;

        console.log("Expected position: ");
        console.log( target.position );
        console.log("Turning to look by: " + camera.rotation.y );
        console.log( targetData );

    } );

}


// In the event of a phaser being fired at what we're looking at
function showPhaserHit ( color ) {

    var beam = new THREE.Object3D();
    var beamLength = 10;
    var beamSegments = 32;

    // color beam
    var colorRadius = 0.5;
    var colorGeo = new THREE.CylinderGeometry( colorRadius/10, colorRadius,
        beamLength, beamSegments );
    var colorMat = new THREE.MeshBasicMaterial( {
        color : color,
        transparent : true,
        opacity : 0.4
    } );
    var colorBeam = new THREE.Mesh( colorGeo, colorMat );
    beam.add( colorBeam );

    // white beam
    var whiteRadius = 0.05;
    var whiteGeo = new THREE.CylinderGeometry( whiteRadius/10, whiteRadius,
        beamLength, beamSegments );
    var whiteMat = new THREE.MeshBasicMaterial( { color : '#FFFFFF' } );
    var whiteBeam = new THREE.Mesh( whiteGeo, whiteMat );
    beam.add( whiteBeam );

    // rotation to target
    // start pos = 0, -10, 0
    // end pos = target.position  // likely
    beamHorizontalOffset = -4;
    beam.position.set( target.position.x, beamHorizontalOffset, target.position.z );
    randomOffset = Math.random() * 0.3 - 0.15;
    beam.rotation.z = randomOffset;

    scene.add( beam );

    // callback for duration of shot (1s)
    setTimeout( function () { scene.remove( beam ); }, 1000 );

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
    if ( amLookingAtTarget() ) return;

    if ( navData.set_speed == "warp" ) {

        goToWarp();

    } else {

        dropOutOfWarp();

    }

}


function processTurnState ( navData ) {

    if ( amLookingAtTarget() ) return;

    // Process periodic updates to state (IE turn thrusters)

    // Translate circle rotations into radians
    var rotation = navData.rotation;
    var turnSpeed = rotation.bearing;

    if ( turnSpeed == 0 ) {

        cameraTurning = false;
        return;

    }

    cameraTurning = true;
    var fps = 40;  // how many ms pass between a frame refresh?

    // TODO: Use timing and don't just guess at fps...
    // Turn rate is 10 seconds for a full rotation
    // turn per ms
    cameraTurnRate = Math.PI * 2 / ( 10 * 1000 );
    // cameraTurnRate = turnSpeed * Math.PI * 2 * 1000; // ( / fps )

}


function processTurnDisplay ( navData ) {

    console.log( "Turning detected" );

    // Process turn events (IE course plots)
    turnDirection = navData.turn_direction;
    turnDuration = navData.turn_duration;
    turnDistance = navData.turn_distance;

    // skip if the view isn't a rotating one
    if ( amLookingAtTarget() ) return;

    cameraTurning = true;
    // how far does the camera turn each frame?
    var totalRotation = turnDistance * 2 * Math.PI;

    // TODO fix this to use frame timing as well
    var framesOfRotation = turnDuration / 1000 * 15;
    cameraTurnRate = totalRotation / framesOfRotation;
    if ( turnDirection == "CW" ) cameraTurnRate *= -1;

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
        if ( navigationData.warp > 0 && !atWarp ) goToWarp();

} );


trek.socket.on( "Display", function ( data ) {

    var message = data.split( ":" );

    if ( message[ 1 ] != targetName ) return;

    switch ( message[ 0 ] ) {

        case "Torpedo hitting":
            showTorpedoHit();
            break;

        case "Phaser hitting":
            showPhaserHit('#FF0000');
            break;

        case "Destroyed":
            showDestruction();
            break;

    };

} );


trek.socket.on( "Navigation", function ( navData ) {


    if ( _.has( navData, "turn_direction" ) ) processTurnDisplay( navData );
    if ( _.has( navData, "set_speed" ) ) processSpeedData( navData );


} );


trek.socket.on( "Thruster", function ( navData) {

    // we're moving? yay? let's assume all meshes are not and move them
    // inversely.
    shipVelocity = navData.velocity;


} );


trek.socket.on( "Turning", function ( navData ) {

    // this is intermitent, but includes the current
    // turn rate

    processTurnState( navData );

} );


trek.onAlert( function () {

    return;

} );
