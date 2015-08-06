var system_template = $('#system_template').html();
var engineeringStatus;

function round (n, d) {

    return Math.floor( n * Math.pow( 10, d ) ) / Math.pow( 10, d );

};

var consolidated_cargo = {};

function loadScan ( data ) {

    engineeringStatus = data.systems;
    trek.api( 'operations/internalScan', drawSystems );

}

function drawSystems ( scan ) {

    var section = _.find(
        engineeringStatus,
        function ( s ) {

            return s.name == selected_system;

        } );

    var repair_crews = _.filter(
        scan,
        function ( s ) {

            return s.description == "Repair Team" && s.currently_repairing == selected_system;

        } );

    section.time_to_repair = round( section.time_to_repair / 1000 / 60, 2 );

    if ( section.hasOwnProperty('time_to_operability') ) {

        section.time_to_operability = round( section.time_to_operability / 1000 / 60, 2 )

    };

    section[ 'repair_crews' ] = repair_crews.length;

    _.each(
        section.repair_requirements,
        function ( e, i, l ) {

            if ( e.quantity > consolidated_cargo[ e.material ] ) {

                e[ 'availability' ] = "red";
                console.log( "unavailable:" + e.material );

            }

        } );

    $( '#system_display' ).html( Mustache.render( system_template, section ) );

}

function load_systems () {

    trek.api( 'engineering/status', loadScan );

}

// Disable alert screen
trek.onAlert( function() {

    return;

    } );

trek.api(
    'operations/cargo',
    function ( data ) {

        _.each(
            data,
            function ( bay, bay_num, cargo_set ) {

                _.each(
                    bay,
                    function ( v, k, l ) {

                        if ( consolidated_cargo.hasOwnProperty ( k ) ) {

                            consolidated_cargo[ k ] += v;

                        } else {

                            consolidated_cargo[ k ] = v;

                        }

                    } );

            } );
        load_systems();

    } );
