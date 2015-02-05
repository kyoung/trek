
var $scanReadout = $("#scanReadout");
var $environmentSegments = $( ".science-environmental-segment" );
var segmentColors = [
    "#60DDF7",
    "#0F8AA6",
    "#03BD11",
    "#83E589",
    "#CCC463" ];

var segmentInterval = 1000;
var updateInterval = 1000;


function moveColors() {

    _.each( $environmentSegments, function( segment ) {

        var color = segmentColors[ Math.floor( Math.random() * segmentColors.length ) ]
        $( segment ).attr( "fill", color );

        } );

}


function updateScan( environmentalData ) {

    $scanReadout.empty();

    var scanTemplate = "<ul class='science-environmental-data'>{{#data}}<li>{{ parameter }}: {{ readout }}</li>{{/data}}</ul>";

    var html = Mustache.render( scanTemplate, { data : environmentalData } )
    console.log( html );
    var $scanData = $( html );

    $scanReadout.append( $scanData );

}


function pollScan() {

    trek.api( 'science/environmental-scan', updateScan );

}


setInterval( moveColors, segmentInterval );
setInterval( pollScan, updateInterval );

// Disable alert screen
trek.onAlert( function() {

    return;

    } );
