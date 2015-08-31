function newPlanet ( radius, type, surfaceColor, atmosphereColor, callback ) {

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

        var loader = new THREE.TextureLoader();
        loader.load(
            'static/textures/gas1.jpg',  // todo pick a random texture map
            function ( texture ) {

                var atmosphereGeometery = new THREE.SphereGeometry( radius *= 1.01, 32, 32 );
                var atmosphereMaterial = new THREE.MeshPhongMaterial( {
                    map : texture,
                    side : THREE.DoubleSide,
                    optacity : 0.8,
                    transparent : true,
                    depthWrite : false
                } );

                var atmosMesh = new THREE.Mesh( atmosphereGeometery, atmosphereMaterial );
                planet.add( atmosMesh );

                callback( planet );

            }
        )

    } else {

        callback( planet );

    }

}

function newPlanetMaterial ( surfaceColor ) {

    return new THREE.MeshLambertMaterial( { color : surfaceColor } );

}

function newCloudMaterial ( atmosphereColor ) {

    var map = THREE.ImageUtils.generateDataTexture(
        64, 64*3, new THREE.Color( 0x000000 ) );
    addScalarField( map, planetScalarField );
    map.needsUpdate = true;

    return new THREE.MeshPhongMaterial(
        { map : map,
          side : THREE.DoubleSide,
          opacity : 0.8,
          transparent : true,
          depthWrite : false
      } );

}
