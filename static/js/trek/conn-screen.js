
var tmpl = $( "#scannerObjectTmpl" ).html();
var sensorObjects = {};
var map;
var scanInterval;
var $displayGrid = $( "#displayScreen" );
var selfScanObject;

var $zoomBar = $( "#zoomSlider" );

var system;

// Parse the zoom values from the URL query string
var qs_values = trek.parseQueryString();
var zoomLevel = _.has( qs_values, "zoomLevel" ) ?
    parseInt( qs_values.zoomLevel ) : 1;
var zoomCoordinateX = _.has( qs_values, "zoomCoordinateX" ) ?
    parseFloat( qs_values.zoomCoordinateX ) : 0;
var zoomCoordinateY = _.has( qs_values, "zoomCoordinateY" ) ?
    parseFloat( qs_values.zoomCoordinateY ) : 0;

$zoomBar.val( zoomLevel );

var minX, minY, maxX, maxY;


function relativeCoordinates ( x, y, z ) {

    if ( !system ) {

        return

    }

    var w = $displayGrid.width();
    var h = $displayGrid.height();

    var xRel = ( w * ( x - minX ) ) / ( maxX - minX );
    // y coordinates are inverted on canvas elements
    var yRel = ( h * ( maxY - y ) ) / ( maxY - minY );
    var zRel = 0;

    return { x : xRel, y : yRel, z : zRel };

}


function relativeRadius ( r ) {

    return r * $displayGrid.width() / ( maxX - minX );

}


function absoluteCoordinates ( x, y, z ) {

    var w = $displayGrid.width();
    var h = $displayGrid.height();

    console.log( "w: " + w );
    console.log( "h: " + h );
    console.log( "minX: " + minX + " minY: " + minY );
    console.log( "maxX: " + maxX + " maxY: " + maxY );

    var xAbs = ( x / w * ( maxX - minX ) + minX );
    var yAbs = ( y / h * ( maxY - minY ) + minY );
    var zAbs = 0;

    console.log( xAbs );
    console.log( yAbs );

    return { x : xAbs, y : yAbs, z : zAbs };

}


function paintMap ( data ) {

    console.log( data );

    // Paint the clouds, but the star will still have to be handled by the scan
    _.each( data.clouds, function ( cloud ) {

        cloudTemplate = "<div class='conn-gas-circle' style='width:{{ relative_radius }}px; height:{{ relative_radius }}px;'></div>"

        var coordinates = relativeCoordinates( cloud.position.x, cloud.position.y, cloud.position.z );
        var radius = relativeRadius( cloud.radius );
        var cloud = { relative_radius : Math.round( radius * 10) / 10 };

        // TODO: the radius shouldn't need to be over two here... why is that?
        var x = coordinates.x - radius / 2;
        var y = coordinates.y - radius / 2;

        var $obj = $( Mustache.render( cloudTemplate, cloud ) );
        $obj.css( "top", y ).css( "left", x );
        $displayGrid.append( $obj );

    } );

}


function paintScan ( data ) {

    _.each( data, function ( e ) {

        var coordinates = relativeCoordinates(
            e.position.x,
            e.position.y,
            e.position.z
        );

        var x = coordinates.x;
        var y = coordinates.y;
        var dist = trek.prettyDistanceAU( e.distance );
        var name = e.name;
        var bearing = trek.prettyBearing( e.bearing.bearing ) + " mark " + trek.prettyMark( e.bearing.mark );
        var distAndBearing = dist + ", " + bearing;

        // Don't inlucde distance and bearing for yourself
        if ( e.name == shipName ) {

            distAndBearing = "";
            selfScanObject = e;

        }

        var speed = "";
        if ( e.warp == "0" ) {

            speed = e.impulse + " impulse";

        } else {

            speed = "warp " + e.warp;

        }

        if ( e.warp === undefined ) {

            speed = "";

        }

        var reading = {

            name : name.replace( /_/g, " " ),
            distAndBearing : distAndBearing,
            speed : speed,
            is_z_axis : e.position.z,
            z_axis : trek.prettyDistanceAU( e.position.z )

        };

        if ( _.has( sensorObjects, e.name ) ) {

            sensorObjects[ name ].css( "top", y ).css( "left", x );
            sensorObjects[ name ].html( Mustache.render( tmpl, reading ) );

        } else {

            var obj = $( Mustache.render( tmpl, reading ) );
            obj.css( "top", y ).css( "left", x );
            sensorObjects[ e.name ] = obj;
            $displayGrid.append( obj );

        }

    } );

}


function scan () {

    trek.api(
        "navigation/charts",
        { system: systemName },
        paintScan );

}


function setMinMaxVals () {

    var shownWidth = system.width / Math.pow( 2, zoomLevel );
    var shownHeight = system.width / Math.pow( 2, zoomLevel );

    minX = zoomCoordinateX - shownWidth / 2;
    maxX = zoomCoordinateX + shownWidth / 2;
    minY = zoomCoordinateY - shownHeight / 2;
    maxY = zoomCoordinateY + shownHeight / 2;

}


function zoom ( click ) {

    var y = $displayGrid.height() - click.clientY;
    var x = click.clientX;

    var absPoint = absoluteCoordinates( x, y, 0 );

    zoomCoordinateX = absPoint.x;
    zoomCoordinateY = absPoint.y;

    // Assume a click is a "zoom in " request
    zoomLevel += 1;

    setMinMaxVals();

    // Set the window location appropriately so the parent can query it
    window.location.search = "system=" + systemName + "&zoomLevel=" + zoomLevel + "&zoomCoordinateY=" + zoomCoordinateY + "&zoomCoordinateX=" + zoomCoordinateX;

}


function zoomWithBar () {

    zoomLevel = $zoomBar.val();

    // We center on the current zoomCoordinate
    window.location.search = "system=" + systemName + "&zoomLevel=" + zoomLevel + "&zoomCoordinateY=" + zoomCoordinateY + "&zoomCoordinateX=" + zoomCoordinateX;

}


$displayGrid.click( zoom );
$zoomBar.change( zoomWithBar );


trek.onAlert( function( data ) {

    return;

    } );


trek.api(
    'navigation/system',
    { system : systemName },
    function( data ) {

        system = data;
        setMinMaxVals();
        scan();
        scanInterval = setInterval( scan, 500 );

        paintMap( data );

    } );
