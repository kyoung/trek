
var originList = $( "#origin-list" );
var destList = $( "#dest-list" );

var inTransporterRange;

var transportArgs = {
    source_name : fromTarget,
    target_name : toTarget
};

var $transportLi;


function loadPage () {

    trek.api(
        'transporters/transporterRange',
        function ( data ) {

            inTransporterRange = data;

            transScan = _.find( data, function ( i ) {

                return i.name == fromTarget;

                } );

            destScan = _.find( data, function ( i ) {

                return i.name == toTarget;

                } );

            if ( transType == 'cargo' ) {

                buildCargoMenu( transScan );
                buildBayMenu( destScan );

            } else {

                buildCrewMenu( transScan );
                buildDeckMenu( destScan );

            }

        } );

}


function buildBayMenu ( destScan ) {

    destList.empty();
    _.each( destScan.cargo, function ( v, k, l ) {

        var c = $("<li class='blue trans_dest'>Cargo Bay " + k + "</li>");
        c.click( function() {

            transportArgs[ 'destination_bay' ] = k;
            $( ".trans_dest" ).removeClass( 'lightblue' );
            $( this ).addClass( 'lightblue' );

            } );

        destList.append( c );

        } );

}


function buildDeckMenu ( destScan ) {

    destList.empty();

    if ( toTarget == shipName ) {

        // Go straight to transporter room
        var d = $( "<li class='lightblue'>Transporter Room</li>" );
        destList.append( d );
        return

    }

    _.each( destScan.decks, function ( v, k, l ) {

        var $d = $( "<li class='blue trans_dest'>Deck " + v + "</li>" );

        $d.click( function () {

            transportArgs[ 'target_deck' ] = v;
            buildSectionMenu( destScan );

            } );

        destList.append( $d );

        } );

}


function buildSectionMenu ( destScan ) {

    destList.empty();

    _.each( destScan.sections, function ( v, k, l ) {

        var s;
        if ( parseInt( v ) ) {

            s = "Section " + v;

        } else {

            s = v + " Section";

        }

        var $d = $( "<li class='blue trans_dest'>" + s + "</li>" );

        $d.click( function () {

            $( ".trans_dest" ).removeClass( 'lightblue' );
            $( this ).addClass( 'lightblue' );
            transportArgs[ 'target_section' ] = v;

            } );

        destList.append( $d );

        } );

}


function buildInternalCrewMenu ( r ) {

    console.log( r );

    if ( r.length == 0 ) {

        $( "#origin_error" ).html( "No parties in transporter room" );

    };

    _.each( r, function ( e, i, l ) {

        var c = $( "<li class='blue trans_selection'>" + e.description + "</li>" );

        c.click( function () {

            $( ".trans_selection" ).removeClass( 'lightblue' );
            $( this ).addClass( 'lightblue' );
            transportArgs[ 'team_type' ] = e.description;
            $transportLi = $( this );

            } );

        originList.append( c );

        } );

}


function buildCrewMenu ( transScan ) {

    originList.empty();

    // Special case internal menu
    if ( shipName == fromTarget ) {

        trek.api(
            'transporters/crewReadyToTransport',
            function ( d ) {

                buildInternalCrewMenu( d );

            } );

        return;

    }

    // Lifeform scan
    _.each( transScan.crew, function ( e, i, l ) {

        // green for away teams
        var color = 'blue';

        if ( e.away_team ) {

            color = 'green';

        }

        var c = $( "<li class='" + color + " trans_selection'>" + e.size + " humanoids. Deck " + e.deck + ", Section " + e.section + "</li>" );

        c.click( function () {

            $( ".trans_selection" ).removeClass( 'lightblue' );
            $( this ).addClass( 'lightblue' );

            transportArgs[ 'is_boarding_party' ] = e.away_team;
            transportArgs[ 'crew_id' ] = e.id;
            transportArgs[ 'deck' ] = e.deck;
            transportArgs[ 'section' ] = e.section;

            console.log( transportArgs );

            $transportLi = $( this );

            } );

        originList.append( c );

        } );

}


function buildCargoFromMenu ( transScan, cargo ) {

    originList.empty();

    _.each( transScan.cargo, function ( v, k, l ) {

        _.each(v, function ( v2, k2, l2 ) {

            if ( k2 != cargo || v2 == 0 ) {

                return;

            }

            var s = k2 + ", Bay " + k + ": " + v2;
            var c = $( "<li class='blue' trans_selection'>" + s + "</li>" );

            c.click( function () {

                transportArgs[ 'origin_bay' ] = k;
                transportArgs[ 'qty' ] = v2;
                $( ".trans_selection" ).removeClass( 'lightblue' );
                $( this ).addClass( 'lightblue' );
                $transportLi = $( this );

                } );

            originList.append( c );

            } );

        } );

}


function buildCargoMenu ( transScan ) {

    originList.empty();
    var available_cargo = {};

    _.each( transScan.cargo, function ( v, k, l ) {

        _.each( v, function ( v2, k2, l2 ) {

            if ( v2 == 0 ) {

                return;

            }

            if ( available_cargo.hasOwnProperty( k2 ) ) {

                available_cargo[ k2 ] += v2;

            } else {

                available_cargo[ k2 ] = v2;

            }

            } );

        } );

    _.each( available_cargo, function ( v, k, l ) {

        var c = $( "<li class='blue trans_selection'>" + k + " " + v + "</li>" );

        c.click( function () {

            $( ".trans_selection" ).removeClass( 'lightblue' );
            $( this ).addClass( 'lightblue' );
            transportArgs[ 'cargo' ] = k;
            buildCargoFromMenu( transScan, k );

            } );

        originList.append( c );

        } );

}


function beamCargo () {

    transportArgs[ 'origin' ] = fromTarget;
    transportArgs[ 'destination' ] = toTarget;

    trek.api(
        'transporters/transportCargo',
        transportArgs,
        'POST',
        function ( r ) {

            $transportLi.remove();

        } );

}


function beamCrew () {

    trek.api(
        'transporters/transportCrew',
        {
            crew_id : transportArgs.crew_id,
            origin : fromTarget,
            origin_deck : transportArgs.deck,
            origin_section : transportArgs.section,
            target : toTarget,
            target_deck : transportArgs.target_deck,
            target_section : transportArgs.target_section
        },
        'POST',
        function ( r ) {

            $transportLi.remove();

        } );

}


function beam () {


    // Refactor
    if ( transType == 'cargo' ) {

        beamCargo();

    } else {

        beamCrew();

    }

}


function beamBarClicked () {

    trek.playTransporter();

    $( "#beam_progress" ).animate(
        { bottom : window.innerHeight - 20 },
        5000,
        function () {

            $( "#beam_progress" ).animate(
                { bottom : 20 },
                5000,
                function() {

                    $transportLi.removeClass( 'blink' );

                } )
                
            beam();

        } );

    $( ".ops-trans-beam_bar" ).animate(
        { backgroundColor : "#03BD11" },
        5000,
        function () {

            $( ".ops-trans-beam_bar" ).animate(
                { backgroundColor : "#0F8AA6" }, 5000 );

        } );

}


$( ".ops-trans-beam_bar" ).click( function ( e ) {

    var y = e.clientY;
    if ( y < 200 ) {

        // good enough, begin animation
        beamBarClicked();

    }

    $transportLi.removeClass( 'lightblue' ).addClass( 'blink' );

    } );


if ( fromTarget != 'undefined' ) {

    loadPage();

}

trek.onAlert( function( data ) {

    return;

    } );
