var atmosMaps = 3;
var rockMaps = 3;
var cloudMaps = 1;

function newPlanet ( radius, type, surfaceColors, atmosphereColors, callback ) {

    // radius -
    // type - [ gas | rock ]
    // surfaceColor -
    // atmosphereColor -
    // callback

    var planet = new THREE.Object3D();

    var surfaceGeometry = new THREE.SphereGeometry( radius, 32, 32 );
    var sufraceMaterial = newPlanetMaterial( surfaceColors[ 0 ] );
    var sphere = new THREE.Mesh( surfaceGeometry, sufraceMaterial );
    planet.add( sphere );

    if ( type === 'gas' ) {

        // http://stackoverflow.com/questions/17486614/three-js-png-texture-alpha-renders-as-white-instead-as-transparent
        _.each( atmosphereColors, function( color, i ) {

            var coin = Math.floor( Math.random() * atmosMaps );

            var atmosGeometry = new THREE.SphereGeometry( radius, 32, 32 );
            atmosGeometry.computeTangents();
            var atmosphereMaterial = new THREE.MeshPhongMaterial( {
                alphaMap : THREE.ImageUtils.loadTexture("/static/textures/gas" + coin + "_" + i + ".jpg"),
                side : THREE.DoubleSide,
                optacity : 1,
                transparent : true,
                shininess : 1,
                depthWrite : false,
                color : color
            } );
            var atmosMesh = new THREE.Mesh( atmosGeometry, atmosphereMaterial );
            var scale = 1 + 0.001 * i;
            atmosMesh.scale.set( scale, scale, scale );
            planet.add( atmosMesh );

        } );

    }

    if ( type === 'rock' ) {

        _.each( surfaceColors, function( color, i ) {

            if ( i === 0 ) return;  // already used as the base sphere color

            console.log("adding rock color");
            var coin = Math.floor( Math.random() * rockMaps );
            var rockGeometry = new THREE.SphereGeometry( radius, 32, 32 );
            rockGeometry.computeTangents();
            var rockMaterial = new THREE.MeshPhongMaterial( {
                alphaMap : THREE.ImageUtils.loadTexture("/static/textures/rock" + coin + "_" + (i-1) + ".jpg"),
                side : THREE.DoubleSide,
                optacity : 1,
                transparent : true,
                shininess : 1,
                depthWrite : false,
                color : color
            } );
            var rockMesh = new THREE.Mesh( rockGeometry, rockMaterial );
            var scale = 1 + 0.001 * i;
            rockMesh.scale.set( scale, scale, scale );
            planet.add( rockMesh );

        } );

        _.each( atmosphereColors, function( color, i ) {

            var coin = Math.floor( Math.random() * cloudMaps );
            var cloudGeometry = new THREE.SphereGeometry( radius, 32, 32 );
            cloudGeometry.computeTangents();
            var cloudMaterial = new THREE.MeshPhongMaterial( {
                alphaMap : THREE.ImageUtils.loadTexture("/static/textures/cloud" + coin + "_" + 0 + ".jpg"),
                side : THREE.DoubleSide,
                optacity : 0.5,
                transparent : true,
                shininess : 50,
                depthWrite : false,
                color : color
            } );
            var cloudMesh = new THREE.Mesh( cloudGeometry, cloudMaterial );
            var scale = 1 + 0.005 * i;
            cloudMesh.scale.set( scale, scale, scale );
            planet.add( cloudMesh );

        } );

    }

    callback( planet );

}


function newPlanetMaterial ( surfaceColor ) {

    return new THREE.MeshLambertMaterial( { color : surfaceColor } );

}
