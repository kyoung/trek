var range = 0.5;
var resolution = 8;
var buckets = []

for ( var i = 0; i < 64; i ++ ) {

    buckets.push( 'selected' );

}

// High resolution scans require max resolution
if ( type.indexOf( 'High-Resolution' ) > 0 ) {

    resolution = 64;

}

// To be replaced with API status call. 3 AU is max short range scan.
var maxRange = 3;
var reading = [];

var validResolutions = [ 4, 8, 16, 32, 64 ];

var $resolutionSelectors = $( "#resolution_meter .scan-slider-selector-left" );
var $rangeBar = $( "#range_bar" );
var $rangeSelector = $( "#range_selector" );
var $scanResults = $( "#scanResults" );

var $scanTiming = $( "#scan_timing" );
var $scanDetails = $( "#scan_details" );

var resultsCenterX = 500;
var resultsCenterY = 350;
var resultsRadius = 350;

var bearing_start;
var bearing_end;

$rangeSelector.click( selectRange );
$resolutionSelectors.click( selectResolution );


function setConfiguration () {

    trek.api(
        'science/runScan',
        {
            type: type,
            resolution: resolution,
            range: range,
            grid_start: 0,
            grid_end: 63
        },
        'PUT',
        function ( c ) {

            console.log( c );

        } );

}


function loadConfiguration ( config_json ) {

    range = config_json.range;
    resolution = config_json.resolution;
    for (var i = 0; i < 64; i ++ ) {

        if ( i in config_json.grids ) {

            buckets.push( 'selected' );

        } else {

            buckets.push( 'offline' );

        }

    }

    var percentage_complete = ( 1 - config_json.ettc / config_json.time_estimate ) * 100;
    percentage_complete = Math.floor( percentage_complete );
    var time_to_completion = config_json.ettc;
    time_to_completion /= 1000;
    time_to_completion = Math.floor( time_to_completion );
    time_to_completion = trek.secondsToMinuteString( time_to_completion );
    var time_tmpl = "<p class='descriptiveText'>Next scan: {{pct_complete}} pct. complete. {{time}} remaining.</p>";
    var o = { pct_complete : percentage_complete, time : time_to_completion };
    $scanTiming.html( Mustache.render( time_tmpl, o ) );
    drawMeters();

}


function loadReading ( reading_json ) {

    reading = reading_json.results;
    drawReadings();

    var classifications = reading_json.classifications;
    $scanDetails.empty();

    var $ul = $( "<ul></ul>" );
    var li_template = "<li>{{classification}} bearing {{bearing.bearing}} mark {{bearing.mark}} distance {{distance}}</li>";

    _.each( classifications, function ( e ) {

        e.bearing.bearing = Math.round( e.bearing.bearing * 1000 )
        e.distance = trek.prettyDistanceKM( e.distance );
        var $li = $( Mustache.render( li_template, e ) );
        $ul.append( $li );

        } );

    $scanDetails.append( $ul );

}


function selectRange ( c ) {

    var offset = $( this ).offset();
    var y = c.clientY - offset.top;
    var height = $( this ).height();
    range = ( height - y ) / height;
    drawMeters();
    setConfiguration();

}


function selectResolution ( c ) {

    if ( type.indexOf( 'High-Resolution' ) > 0 ) {

        return;

    }

    resolution = parseInt( this.id );
    drawMeters();
    setConfiguration();

}


function drawMeters () {

    _.each( $resolutionSelectors, function ( selector ) {

        var value = parseInt( selector.id );

        if ( value <= resolution ) {

            $( selector ).addClass( "selected" );

        } else {

            $( selector ).removeClass( "selected" );

        }

        } );

    height_pct = range * 100
    $rangeBar.css( "height", height_pct.toString() + "%" );
    var AURange = range * maxRange;
    AURange = Math.floor( AURange * 100 ) / 100;
    $( "#range .descriptiveText" ).text( "Range " + AURange.toString() + "AU" );

}


function drawReadings () {

    // Clear existing paths
    $scanResults.empty();

    // Get the max value for normalization...
    var readingValues = _.map(
        reading,
        function ( r ) {

            return r.reading

        } );

    readingValues.sort( function ( a, b ) {

        return a - b

    } );
    var maxValue = readingValues.pop();

    // list of all the path strings we're about to build
    var pathText = "";

    _.each( reading, function ( r ) {

        var startCorner = mapArcPosition( r.start, r.reading / maxValue );
        var endCorner = mapArcPosition( r.end, r.reading / maxValue );
        var radius = resultsRadius * r.reading / maxValue;
        var str = "<path d='M" + resultsCenterX + " " + resultsCenterY;
        str += " L " + startCorner.x + " " + startCorner.y;
        str += " A " + radius + " " + radius + " 0 0 0 " + endCorner.x + " " + endCorner.y;
        str += " Z' class='scan-result-slice' />";
        pathText += str;

        } );

    // Buckets portion
    // was a seperate function... for some reason, the path drawing stuff didn't like
    // appending SVG paths
    var bucketsHTML = "";
    var outRadius = resultsRadius * 1.025;
    _.each( buckets, function ( e, i ) {

        var start_theta = i / 64;
        var end_theta = start_theta + 1 / 64;
        var startCornerIn = mapArcPosition( start_theta, 1 );
        var startCornerOut = mapArcPosition( start_theta, 1.025 );
        var endCornerIn = mapArcPosition( end_theta, 1 );
        var endCornerOut = mapArcPosition( end_theta, 1.025 );

        var str = "<path d='M" + startCornerIn.x + " " + startCornerIn.y;
        str += " L " + startCornerOut.x + " " + startCornerOut.y;
        str += " A " + outRadius + " " + outRadius + " 0 0 0 " + endCornerOut.x + " " + endCornerOut.y;
        //str += " L " + endCornerOut.x + " " + endCornerOut.y;
        str += " L " + endCornerIn.x + " " + endCornerIn.y;
        str += " A " + resultsRadius + " " + resultsRadius + " 0 0 1 " + startCornerIn.x + " " + startCornerIn.y;
        //str += " L " + startCornerIn.x + " " + startCornerIn.y;
        if ( e == 'selected' ) {

            str += " Z' class='scan-result-grid' />";

        } else {

            str += " Z' class='scan-result-grid-void' />";

        }

        bucketsHTML += str;

        } );

    $scanResults.html( pathText + bucketsHTML );

}


function setBearing ( c ) {

    if ( bearing_start ) {
        
        // is bearing end

        // ...

        bearing_start = undefined;
        bearing_end = undefined;

    }

    // else?

}


function mapArcPosition ( theta, radiusPct ) {

    // Actual radius
    var radius = resultsRadius * radiusPct;

    // Full x, y positions, without taking radius into account
    var X = radius * Math.cos( ( theta + 0.25 ) * 2 * Math.PI );
    var Y = radius * Math.sin( ( theta + 0.25 ) * 2 * Math.PI ) * -1;

    // Reduce the vector, and normalize to the center
    var x = X + resultsCenterX;
    var y = Y + resultsCenterY;

    return { x : x, y : y };

}


function scan () {

    trek.api(
        'science/scanConfiguration',
        { type : type },
        loadConfiguration );

    trek.api(
        'science/scanResults',
        { type : type },
        loadReading );

}

// Disable alert screen
trek.onAlert( function() {

    return;

    } );

$scanResults.click( setBearing );

scan();
setInterval( scan, 1000 );
