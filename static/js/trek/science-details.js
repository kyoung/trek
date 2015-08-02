
var $renderPane = $( "#render" );
var $detailTextLeft = $( "#detail-text-left" );
var $detailTextRight = $( "#detail-text-right" );
var $detailTextBottom = $( "#detail-text-bottom" );
var $loading = $( "#loading" );

var camera;
var scene;
var renderer;
var loader;
var lineMat;
var target;
var globalLight;
var visibleRadius = 3000;
var cube;

var rotationTicker = 16;

function loadActiveScan( data ) {

    console.log( "Loading data..." );
    console.log( data );

    if ( _.has( data, "mesh" ) ) {

        renderMesh( data.mesh, data.mesh_scale );

    } else {

        displayNoImageMessage();

    }

    if ( _.has( data, "cargo" ) ) {

        listCargo( data.cargo );

    }

    if ( _.has( data, "systems" ) ) {

        listSystems( data.systems );

    }

    if ( _.has( data, "hull" ) ) {

        listHullStatus( data.hull );

    }

    if ( _.has( data, "shields" ) ) {

        listShieldStatus( data.shields );

    }

    if ( _.has( data, "lifesigns" ) ) {

        listLifesigns( data.lifesigns );

    }

    buildTitle( data );

    if ( _.has( data, "power_readings" ) ) {

        graphPowerReadings( data.power_readings );

    }

    if ( _.has( data, "radiation_output" ) ) {

        listRadiationReadings( data.radiation_output, data.radiation_safe_distance );

    }

    if ( _.has( data, "misc" ) ) {

        listMisc( data.misc );

    }

}


function graphPowerReadings ( readings ) {

    // readings are an array of series of numbers, requiring a graphs...

    // yay https://developer.mozilla.org/en/docs/Web/SVG/Tutorial/Paths
    // cubic bezier curves!

    // or better yet http://www.d3noob.org/2013/01/smoothing-out-lines-in-d3js.html

    // actually, it looks like that's just applying bezier curves, using the adjacent points as the controls...

    console.log( readings );

    // Min and Max Values
    var values = [];
    _.each( readings, function ( measurements ) {

        _.each( measurements, function ( v ) {

            values.push( v );

            } );

        } );

    var min = Math.min.apply( null, values );
    var max = Math.max.apply( null, values );

    var height = 150;
    var width = 700;
    var step = width / 10;
    var scale = function( v ) {

        if ( max == min ) {

            return height;

        }

        return height - ( ( v - min ) / ( max - min ) * height * 0.9 + height * 0.05 );

    };


    var $pane = $( "<div class='scan-detail-fright scan-detail-2o3'></div>" );

    var svg = "<svg version='1.1' xmlns='http://www.w3.org/2000/svg'>";

    _.each( readings, function ( measurements ) {

        var points = []

        _.each( measurements, function ( val, i ) {

            if ( i == 0 ) {

                return;

            }
            var relativeVal = scale( val );
            var x = i * step;
            var y = relativeVal;
            points.push( { x : x, y : y } );
            var line = "L " + x + " " + y + " ";

            } );

        var spline = getSplinePaths( points );

        svg += "<path class='scan-detail-svgline' d='" + spline + "'/>";


        } );

    var grid = "";

    _.times( readings[ 0 ].length - 1, function( i ) {

        var path = "<path class='scan-detail-svggrid' d='";
        var d = "M " + ( i + 1 ) * step + " 0 V " + height;
        path = path + d + "'/>";
        grid += path;

        } );

    svg += grid + "</svg>"

    $pane.append( $( svg ) );

    $detailTextBottom.append( $pane );

}


function getSplinePaths ( plotPoints ) {

    /* grab (x,y) coordinates of the control points */
    x = new Array();
    y = new Array();

    _.each( plotPoints, function( p, i ) {

        x[ i ] = p.x
        y[ i ] = p.y

        } );

    /*computes control points p1 and p2 for x and y direction*/
    px = computeControlPoints( x );
    py = computeControlPoints( y );

    /* Build the spline paths */
    var spline = ""
    _.times( plotPoints.length - 1, function ( i ) {

        p = createSpliePath(
            x[ i ],
            y[ i ],
            px.p1[ i ],
            py.p1[ i ],
            px.p2[ i ],
            py.p2[ i ],
            x[ i + 1 ],
            y[ i + 1 ] );
        spline += p;

        } );

    return spline;

}

/*creates formated path string for SVG cubic path element*/
function createSpliePath ( x1, y1, px1, py1, px2, py2, x2, y2 ) {

    return "M " + x1 + " " + y1 + " C " + px1 + " " + py1 + " " + px2 + " " + py2 + " " + x2 + " " + y2 + " ";

}

/*
computes control points given knots K, this is the brain of the spline operation

http://www.particleincell.com/wp-content/uploads/2012/06/bezier-spline.js
*/
function computeControlPoints ( K ) {

    var p1 = new Array();
    var p2 = new Array();
    var n = K.length - 1;

    /*rhs vector*/
    var a = new Array();
    var b = new Array();
    var c = new Array();
    var r = new Array();

    /*left most segment*/
    a[ 0 ] = 0;
    b[ 0 ] = 2;
    c[ 0 ] = 1;
    r[ 0 ] = K[ 0 ] + 2 * K[ 1 ];

    /*internal segments*/
    for ( i = 1; i < n - 1; i ++ ) {

        a[ i ] = 1;
        b[ i ] = 4;
        c[ i ] = 1;
        r[ i ] = 4 * K[ i ] + 2 * K[ i + 1 ];

    }

    /*right segment*/
    a[ n - 1 ] = 2;
    b[ n - 1 ] = 7;
    c[ n - 1 ] = 0;
    r[ n - 1 ] = 8 * K[ n - 1 ] + K[ n ];

    /*solves Ax=b with the Thomas algorithm (from Wikipedia)*/
    for ( i = 1; i < n; i ++ ) {

        m = a[ i ] / b[ i - 1 ];
        b[ i ] = b[ i ] - m * c[ i - 1 ];
        r[ i ] = r[ i ] - m * r[ i - 1 ];

    }

    p1[ n - 1 ] = r[ n - 1 ] / b[ n - 1 ];
    for ( i = n - 2; i >= 0; -- i ) {

        p1[ i ] = ( r[ i ] - c[ i ] * p1[ i + 1 ] ) / b[ i ];

    }

    /*we have p1, now compute p2*/
    for ( i = 0; i < n - 1; i ++ ) {

        p2[ i ] = 2 * K[ i + 1 ] - p1[ i + 1 ];

    }

    p2[ n - 1 ] = 0.5 * ( K[ n ] + p1[ n - 1 ] );

    return { p1 : p1, p2 : p2 };

}


function buildTitle ( data ) {

    var titleTmpl = "<div class='scan-detail-fleft scan-detail-1o3'><h1>{{ name }}</h1>{{ registry }}</div>";


    var registry = _.has( data, "registry" ) ? data.registry : "";

    if ( registry != "" ) {

        registry = "Registry: " + registry;

    }

    var renderData = {
        name : data.name.replace( /_/g, " " ),
        registry : registry
    };

    var titleHTML = Mustache.render( titleTmpl, renderData );

    var $title = $( titleHTML );

    $detailTextBottom.append( $title );

}


function listLifesigns( lifesigns ) {

    var lifeSignsTmpl = "<div><h2>Lifesigns</h2>Detected Lifesigns: {{ qty }}</div>";

    $lifesigns = $( Mustache.render( lifeSignsTmpl, { qty : lifesigns } ) );

    $detailTextLeft.append( $lifesigns );

}


function listHullStatus( hullData ) {

    var hullTemplate = "<div><h2>Hull Status</h2>Hull Integrity: {{ integrity }} pct.</div>";

    var hullInstanceCount = 0;
    var hullValueCount = 0;

    _.each( hullData, function( deckReport, deckNumber ) {

        _.each( deckReport, function( hullValue, section ) {

            hullInstanceCount += 1;
            hullValueCount += hullValue;

            } );

        } );

    var integrity = hullValueCount / hullInstanceCount * 100;

    var $hullStatus = $( Mustache.render( hullTemplate, { integrity : integrity } ) );

    $detailTextRight.append( $hullStatus );

}


function listShieldStatus ( shieldData ) {

    var shieldTemplate = "<li>{{ name }}<br>charge: {{ charge }} <br>system integrity: {{ status }}</li>";
    var $shieldStatus = $( "<div><h2>Shield Status</h2></div>" );
    var $shieldList = $( "<ul class='informational'></ul>" );

    _.each( shieldData, function ( shieldReport ) {

        shieldReport.charge = Math.floor( shieldReport.charge * 100 );

        shieldReport.status = Math.floor( shieldReport.status * 100 );

        var $shieldItem = $( Mustache.render( shieldTemplate, shieldReport ) )
        $shieldList.append( $shieldItem );

        } );

    $shieldStatus.append( $shieldList );
    $detailTextRight.append( $shieldStatus );

}


function listSystems ( systemList ) {

    var systemTemplate = "<h2>System Status</h2><ul class='scan-detail-system-status'>{{#systems}}<li class='systemStatus {{systemColor}}'>{{name}} <span class='spacer'>{{integrity}}</span>  ({{charge}})</li>{{/systems}}</ul";

    _.each( systemList, function ( system ) {

        var color = "blue";

        if ( system.integrity < 1 ) {

            color = "lightblue";

        }

        if ( !system.online ) {

            color = "green";

        }

        if ( system.operability != "Operable" ) {

            color = "red";

        }

        system.systemColor = color;

        } );

    var systemHTML = Mustache.render( systemTemplate, { systems : systemList } );

    var $systemList = $( "<div class='scan-detail-overflow'></div>" );
    $systemList.html( systemHTML );
    $detailTextRight.append( $systemList );

}


function listCargo ( cargoList ) {

    // Collapse Cargo Bays
    var cargo = {};
    _.each( cargoList, function ( manifest, bay ) {

        // Search each bay
        _.each( manifest, function ( qty, sku ) {

            if ( _.has( cargo, sku ) ) {

                cargo[ sku ] += qty;

            } else {

                cargo[ sku ] = qty;

            }

            } );

        } );

    // Return to a list
    var cargoFlatList = [];
    _.each( cargo, function ( val, key ) {

        cargoFlatList.push( { sku : key, qty : val } );

        } )
    var cargoRender = { cargo : cargoFlatList };

    var cargoListTemplate = "<div><h2>Cargo Status</h2><ul class='scan-detail-system-status'>{{#cargo}}<li class='lightblue'>{{sku}} ({{qty}})</li>{{/cargo}}</ul></div>";

    var $cargoScan = $( Mustache.render( cargoListTemplate, cargoRender ) );

    $detailTextLeft.append( $cargoScan );

}


function listRadiationReadings ( output, safeDistance ) {

    var radiationTemplate = "<div><h2>Radiation Readings</h2><p class='lightblue'>Output: {{ output }}</p><p class='lightblue'>Safe Distance: {{ distance }}</div>";
    var radiation = {
        output : output,
        distance : trek.prettyDistanceAU( safeDistance )
    }

    var $rads = $( Mustache.render( radiationTemplate, radiation ) );

    $detailTextLeft.append( $rads );

}


function listMisc ( miscData ) {

    var miscTemplate = "<div>{{ #data }}<h2>{{ name }}</h2><p class='lightblue'>{{ value }}</p>{{ /data }}</div>"
    var $misc = $( Mustache.render( miscTemplate, { data : miscData } ) );

    $detailTextRight.append( $misc );

}


function renderMesh ( meshName, meshScale ) {

    var w, h;
    w = $renderPane.width();
    h = $renderPane.height();

    // THREE.js stuff
    camera = new THREE.OrthographicCamera( -10, 10, 10, -10, 1, 100 );
    //camera = new THREE.PerspectiveCamera( 70, w/h, 0.1, 1000 );

    scene = new THREE.Scene();
    scene.add( camera );
    renderer = new THREE.WebGLRenderer();
    renderer.setSize( w, h );
    $renderPane.append( renderer.domElement );

    lineMat = new THREE.MeshBasicMaterial( { wireframe : true, color : "#60DDF7" } );
    globalLight = new THREE.AmbientLight( 0x777777 );
    scene.add( globalLight );

    loader = new THREE.JSONLoader( true );
    loader.load(
        "/static/mesh/" + meshName,
        function( geo, mat ) {

            $loading.remove();

            target = new THREE.Mesh( geo, lineMat );

            target.position.set( 0, 0, -7 );
            target.scale.x = target.scale.y = target.scale.z = meshScale;

            scene.add( target );

            // camera.lookAt( target );
            update();
            setInterval( update, 1000 / 2 );

        } );

}


function update () {

    if ( rotationTicker > 0 ) {

        target.rotateY( Math.PI * 2 / 16 );

    } else {

        target.rotateX( Math.PI * 2 / 16 );

    }
    rotationTicker -= 1

    if ( rotationTicker == -16 ) {

        rotationTicker = 16;

    }

    renderer.render( scene, camera );

}


function displayNoImageMessage () {

    $loading.remove();
    $renderPane.html( "<h2>Unable to generate structural scan</h2>" );

}


function getActiveScan () {

    if ( typeof( classification ) == undefined || classification == "undefined" ) {

        return;

    }

    trek.api(
        "science/activeScan",
        {
            classification: classification,
            bearing: bearing,
            distance: distance,
            tag: tag
        },
        loadActiveScan );

}


// Disable alert screen
trek.onAlert( function() {

    return;

    } );


// setInterval( getActiveScan, 1000 );
getActiveScan();
