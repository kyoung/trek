var $screenSelections = $("#viewMenu li");
var $subMenu = $("#subMenu");
var $subSubMenues = $(".subsubmenu");
var $power = $("#engineering_power");
var $status = $("#engineering_screen");
var $displayScreen = $("#displayScreen");
var powerTemplate = $("#powerSubmenuTemplate").html();


$screenSelections.click( function ( c ) {

    $screenSelections.removeClass( 'lightblue' );
    $(this).addClass( 'lightblue' );
    $displayScreen.attr( 'src', this.id );

} );

$status.click( function (c) {

    $subMenu.empty();

    } );

$power.click( function(c) {

    trek.api( 'engineering/power', drawPowerSubmenu );

    } );

function checkPowerUpdates () {

    trek.api( 'engineering/power', updatePowerColors );

}

setInterval( checkPowerUpdates, 1000 );


function choosePowerColor ( e ) {

    return e.output_level > 1 || e.current_power_level > 1 ? 'red' : 'blue';

}


function setPowerIndicatorColor ( e ) {

    e[ 'color' ] = choosePowerColor( e );

}

function updateElementColor ( e ) {

    // We're very naughty and use illegal spaces in our IDs
    var $element = $( "[id='" + e.name + "']");
    var c = choosePowerColor( e );

    if ( c == 'red' && !$element.hasClass( c ) ) {

        console.log( "Changing " + e.name + " to red" );
        $element.addClass( c );

    }

    if ( c == 'blue' && $element.hasClass( 'red' ) ) {

        console.log( "Changing " + e.name + " to blue" );
        $element.removeClass( 'red' );

    }

}


function updatePowerColors ( powerJSON ) {

    _.each( powerJSON.reactors, updateElementColor )
    _.each( powerJSON.primary_relays, updateElementColor )
    _.each( powerJSON.eps_relays, updateElementColor )

}


function drawPowerSubmenu ( powerJSON ) {

    _.each( powerJSON.reactors, setPowerIndicatorColor )
    _.each( powerJSON.primary_relays, setPowerIndicatorColor )
    _.each( powerJSON.eps_relays, setPowerIndicatorColor )

    $subMenu.html( Mustache.render( powerTemplate, powerJSON ) )
    $subSubMenues = $( ".subsubmenu" );
    $( ".subsubmenu li" ).click( selectPowerComponent );
    $subSubMenues.hide();

    var $subsubmenu_list = $( "#subsubmenu_selector ul" );
    var $reactors_li = $( "<li class='green'>Reactors</li>" );
    var $relays_li = $( "<li class='green'>Primary Relays</li>" );
    var $eps_relays_li = $( "<li class='green'>EPS Relays</li>" );

    $subsubmenu_list.append( $reactors_li ).append( $relays_li ).append( $eps_relays_li )

    var flush_subsubmenues = function () {

        $subSubMenues.hide();
        $( "#subsubmenu_selector li" ).removeClass( 'lightgreen' );

    };

    $reactors_li.click( function ( c ) {

        flush_subsubmenues();
        $( "#reactors" ).show();
        $reactors_li.addClass( 'lightgreen' );

     });

    $relays_li.click( function ( c ) {

        flush_subsubmenues();
        $( "#primary_relays" ).show();
        $relays_li.addClass( 'lightgreen' );

    } );

    $eps_relays_li.click( function ( c ) {

        flush_subsubmenues();
        $( "#eps_relays" ).show();
        $eps_relays_li.addClass( 'lightgreen' );

    } );

};


function selectPowerComponent ( c ) {

    $power_type = $( this ).parent().parent();
    $displayScreen.attr( 'src', 'engineering_power?component=' + this.id + "&power_type=" + $power_type[ 0 ].id );
    $( ".subsubmenu li" ).removeClass( 'lightblue' );
    $( this ).addClass( 'lightblue' );

}


trek.socket.on( "power-blowout", function ( msg ) {

    console.log( "Power blowout!" );
    console.log( msg );

    trek.playConsoleBlast();
    trek.displayBlastDamage();

} );


$status.click();


trek.playBridgeSound();
trek.registerDisplay( "Engineering" );
trek.checkBlastDamage();
