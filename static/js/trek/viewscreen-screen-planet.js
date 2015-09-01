var atmosMaps = 3;

function newPlanet ( radius, type, surfaceColor, atmosphereColors, callback ) {

    // radius -
    // type - [ gas | rock ]
    // surfaceColor -
    // atmosphereColor -
    // callback

    var planet = new THREE.Object3D();

    var surfaceGeometry = new THREE.SphereGeometry( radius, 32, 32 );
    var sufraceMaterial = newPlanetMaterial( surfaceColor );
    var sphere = new THREE.Mesh( surfaceGeometry, sufraceMaterial );
    planet.add( sphere );

    if ( type === 'gas' ) {

        // http://stackoverflow.com/questions/17486614/three-js-png-texture-alpha-renders-as-white-instead-as-transparent
        _.each( atmosphereColors, function( color, i ) {

            var c1 = Math.round( Math.random() * atmosMaps );

            var atmosGeometry = new THREE.SphereGeometry( radius, 32, 32 );
            atmosGeometry.computeTangents();
            var atmosphereMaterial = new THREE.MeshPhongMaterial( {
                alphaMap : THREE.ImageUtils.loadTexture("/static/textures/gas" + c1 + "_" + i + ".jpg"),
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

    callback( planet );

}


function newPlanetMaterial ( surfaceColor ) {

    return new THREE.MeshLambertMaterial( { color : surfaceColor } );

}
