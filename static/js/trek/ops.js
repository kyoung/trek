
var viewScreen = $( "#viewScreen" );
var viewSelections = $( "#viewMenu li" );
var subMenues = $( ".hideable" );

var repair_to_operability = $( '#repair_to_operability' );
var repair_to_complete = $( '#repair_to_complete' );
var selected_system;

var $transporters = $( '#transporters' );
var $transSubmenu = $( "#transport_menu" );
var $transOriginSubmenu = $( "#transport_origin_submenu" );
var $transDestSubmenu = $( "#transport_destination_submenu" );
var $transTypes = $( ".trans_type");
var transportFrom;
var transportType = "cargo";

var $crewLegend = $( "#crew_menu" );


viewSelections.click( function () {

    viewSelections.removeClass( 'lightblue' );
    $( this ).addClass( 'lightblue' );

    } );

// Cargo
$( '#cargo' ).click( function () {

    viewScreen.attr( 'src', 'ops_cargo_screen' );
    subMenues.addClass( 'hidden' );

    } );

// Crew
$( '#crew' ).click( function () {

    viewScreen.attr( 'src', 'ops_crew_screen' );
    subMenues.addClass( 'hidden' );
    $crewLegend.removeClass( 'hidden' );

    } );


// Transporters
$transporters.click( function () {

    subMenues.addClass( 'hidden' );

    $transSubmenu.removeClass( 'hidden' );
    $transOriginSubmenu.empty();
    $transDestSubmenu.empty();

    viewScreen.attr( 'src', 'ops_trans_screen' );

    $transTypes.click( function () {

        transportType = this.id;
        $transTypes.removeClass( "lightblue" );
        $( this ).addClass( "lightblue" );

        } );

    trek.api(
        "transporters/transporterRange",
        parseObjectInTransportRange );

    } );


function parseObjectInTransportRange( data ) {

    var $originMenu = $( '<ul class="menu x1"></ul>' );
    var $destMenu = $( '<ul class="menu x1"></ul>' );

    var originTemplate = "<li class='green trans_target' id='{{ name }}'>{{ humanName }}</li>";
    var destTemplate = "<li class='green trans_dest' id='{{ name }}'>{{ humanName }}</li>";

    _.each( data, function( e ) {

        e.humanName = e.name.replace( /_/g, " " );

        var $originTarget = $( Mustache.render( originTemplate, e ) );

        $originTarget.click( function () {

            transportFrom = this.id;
            $( "li.trans_target" ).addClass( 'green' );
            $( this ).addClass( 'lightgreen' );

            $( ".trans_dest" ).removeClass( 'offline' );

            if ( this.id != ship_name ) {

                $( "#" + this.id + ".trans_dest" ).addClass( 'offline' );

            };

            } );

        $originMenu.append( $originTarget );

        var $destTarget = $( Mustache.render( destTemplate, e ) );
        $destTarget.click( function () {

            viewScreen.attr(
                'src',
                'ops_trans_screen?origin=' + transportFrom + '&destination=' + this.id + '&type=' + transportType );

            $( 'li.trans_dest' ).addClass( 'green' );
            $( this ).addClass( 'lightgreen' );

            if (transportFrom && transportType) {

                viewScreen.attr( "src",
                    "ops_trans_screen?" +
                    "origin=" + transportFrom +
                    "&destination=" + this.id +
                    "&trans_type=" + transportType )

            }

            } );

        $destMenu.append( $destTarget );

    } );

    $transOriginSubmenu.append( $originMenu );
    $transDestSubmenu.append( $destMenu );

}


// Repair
$( '#repair' ).click( function () {

    subMenues.addClass( 'hidden' );
    var submenu = $( "#repair_menu" );
    submenu.removeClass( 'hidden' );
    var repair_menu = $( '#damaged_systems' );
    repair_menu.empty();

    trek.api(
        'engineering/status',
        function ( data ) {

            var ul = $( '<ul class="menu x1"></ul>' );

            _.each( data, function ( d ) {

                var li = $( '<li class="green damaged_system" id="' + d.name + '">' + d.name + '</li>' );
                li.click( function () {

                    $( '.damaged_system' ).removeClass( 'lightgreen' );
                    $( this ).addClass( 'lightgreen' );
                    viewScreen.attr( 'src', 'ops_repair_screen?system_name=' + this.id );
                    selected_system = this.id;

                    } );
                if ( d.integrity < 1 ) {

                    ul.append( li );

                }

                } );

            var def = ul.children().first()[ 0 ];
            $( def ).addClass( 'lightgreen' );
            selected_system = def.id;
            viewScreen.attr( 'src', 'ops_repair_screen?system_name=' + def.id );
            repair_menu.append( ul );

        } );

    } );


repair_to_complete.click( function () {

    trek.api(
        'operations/repairTeam',
        {
            to: 'completion',
            system_name: selected_system,
            teams: 1
        },
        function ( d ) {

            viewScreen.attr(
                'src',
                'ops_repair_screen?system_name=' + selected_system );

        } );

    } );


repair_to_operability.click( function () {

    trek.api(
        'operations/repairTeam',
        {
            to: 'operability',
            system_name: selected_system,
            teams: 1
        },
        function (d) {

            viewScreen.attr(
                'src',
                'ops_repair_screen?system_name=' + selected_system );

        } );

    } );

trek.registerDisplay( "Ops" );
trek.checkBlastDamage();
trek.playBridgeSound();

$( '#crew' ).click();
