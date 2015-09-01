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

        // http://stackoverflow.com/questions/17486614/three-js-png-texture-alpha-renders-as-white-instead-as-transparent

        var atmosGeometry = new THREE.SphereGeometry( radius, 32, 32 );
        atmosGeometry.computeTangents();
        var atmosphereMaterial = new THREE.MeshPhongMaterial( {
            alphaMap : THREE.ImageUtils.loadTexture('/static/textures/gas1.jpg'),
            side : THREE.DoubleSide,
            optacity : 1,
            transparent : true,
            shininess : 1,
            depthWrite : false,
            color : "#A45625"//atmosphereColor
        } );

        var atmosMesh = new THREE.Mesh( atmosGeometry, atmosphereMaterial );
        atmosMesh.scale.set(1.001, 1.001, 1.001);
        planet.add( atmosMesh );


    }

    callback( planet );

}


function newPlanetMaterial ( surfaceColor ) {

    return new THREE.MeshLambertMaterial( { color : surfaceColor } );

}
