
var targetName = "";
var $menu = $( "#viewscreenMenu" );
var visualRange = $( "#visualRange" );


setInterval( getItemsInVisualRange, 1000 );
function getItemsInVisualRange () {

    trek.api( "command/targets-in-visual-range", displayTargets );

}


function displayTargets ( data ) {

    visualRange.empty();

    _.each( data, function ( d ) {

        if ( d !== "<%= ship.name %>" ) {

            var cleanName = d.replace( /_/g, " ");

            visualRange.append( "<li class='green' id='" + d + "'>" + cleanName + "</li>" );

        }

        } );

    $( "#visualRange li" ).click( function ( c ) {

        targetName = c.target.id;

        } );

}


$( "#cameras li" ).click( function ( c ) {

    // set the camera;
    targetName = c.target.id;

    } );


$( "#setMainViewer" ).click( setMainViewer );
function setMainViewer () {

    trek.api(
        "command/main-viewer",
        {
            screen: "viewscreen_screen",
            target: targetName
        },
        'POST',
        function ( d ) {

            console.log( "mainscreen set" );

        } );

}
