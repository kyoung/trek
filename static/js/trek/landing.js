
var selected_ship = "";

var $bg = $( ".blackout" );
var $prefixInvite = $( "#prefixInvite" );

function showPrefixEntry ( e ) {

    $bg.css( "visibility", "visible" );
    $prefixInvite.html( "Enter prefix code for " + e.id );
    selected_ship = e.id;

}

function hidePrefixEntry ( e ) {

    $bg.css( "visibility", "hidden" );
    document.getElementById( "prefix" ).value = "";
    setLoginColor( "blue" );

}

function submitPrefix () {

    var code = document.getElementById( "prefix" ).value;
    $.get(
        "/postfix",
        { prefix : code,
          ship : selected_ship
        },
        function (data) {

            if ( data.status == "OK" ) {

                window.location.replace( "/ship" )

            } else {

                $prefixInvite.html( "Invalid prefix for " + selected_ship );
                setLoginColor( "red" );

            }

        } );
        
}

function setLoginColor ( color ) {

    $( "#prefix" ).attr( "class", color );
    $( "#prefixEntry" ).attr( "class", color );
    $( "#prefixEntry li" ).attr( "class", color );

}
