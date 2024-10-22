
var $crewList = $( "#crewList" );

var deckTemplate = "<div class='ops-crew-deck'><span>{{deck}}</span></div>";

var crewTemplate = "<div class='ops-crew-beacon {{class_}}'><p>{{letter}}</p></div>";

var systemTemplate = "<div class='ops-crew-system'>{{name}}</div>";
var internalScan_decks, scanResults;

var systemsLayout;
var deckLayout;
var sectionLayout;
var selectedCrew;

var freeze = false;


function getInternalScanData () {

    if ( freeze ) {

        return;

    }

    trek.api( 'operations/internalScan', displayInternals );

}


function determineCrewClass ( crew ) {

    var class_;

    // Default starting case
    class_ = crew.status;

    // Injured?
    is_injured = false;

    _.each( crew.members, function ( m ) {

        if ( m < 1 ) {

            is_injured = true;

        }

        } );

    if ( is_injured ) {

        class_ = "injured";

    }

    // Invader or Prisoner
    if ( crew.alignment != alignment ) {

        if ( crew.status != "prisoner" ) {

            class_ = "intruder";

        } else {

            class_ = "prisoner";

        }

        return class_;

    }

    // Guest?
    if ( crew.assignment != shipName ) {

        class_ += " guest";

    }

    // Enroute?
    if ( crew.status == "enroute" ) {

        class_ += " enroute";

    }

    return class_;

}


function drawDeck ( deck ) {

    var $deck = $( Mustache.render( deckTemplate, { deck : deck } ) );

    _.each( sectionLayout, function ( section ) {

        var $section = $( "<div class='ops-crew-section'></div>" );

        if ( selectedCrew ) {

            $section.addClass( 'selectable' );

        }

        // Find systems and crew in this deck/section
        crew = _.filter(
            scanResults,
            function (e) {

                return e.deck == deck && e.section == section;

            } );

        systems = _.filter(
            systemsLayout,
            function (e) {

                return e.deck == deck && e.section == section;

            } );

        _.each( crew, function ( e ) {

            e.letter = e.code;
            e.class_ = determineCrewClass( e );

            $crew = $( Mustache.render( crewTemplate, e ) );

            $crew.click( function () {

                // set the value in a second, to prevent
                // deck / section selection
                setTimeout( function () {

                    selectedCrew = {
                        id : e.id,
                        type : e.description,
                        deck : e.deck,
                        section : e.section
                    }

                    }, 10 );

                $( this ).addClass( 'selected' );
                $( '.ops-crew-section' ).addClass( 'selectable' );

            } );

            if ( selectedCrew && selectedCrew.id == e.id ) {

                $crew.addClass( 'selected' );

            }

            $section.append( $crew );

            } );

        _.each( systems, function ( e ) {

            $system = $( Mustache.render( systemTemplate, e ) );

            $section.append( $system );

            } );

        $section.click( function () {

                if ( !selectedCrew ) {

                    return;

                };

                post_data = {
                    crew_id : selectedCrew.id,
                    to_deck : deck,
                    to_section : section
                }

                console.log( post_data );

                trek.api(
                    "operations/send-team-to-deck",
                    post_data,
                    'POST',
                    function() {} );

                $( '.ops-crew-section' ).removeClass( 'selectable' );
                $( '.ops-crew-beacon' ).removeClass( 'selected' );
                selectedCrew = undefined;

            } );

        $deck.append( $section );

        } );

    $crewList.append( $deck );

}


function displayInternals ( scanData ) {

    if ( !systemsLayout || !deckLayout || !sectionLayout ) {

        return;

    }

    scanResults = scanData;
    $crewList.empty();

    // Add in section titles
    var headerTemplate = "<div class='ops-crew-deck'><span>&nbsp;</span>{{ #arr }}<div class='ops-crew-section'>{{ . }}</div>{{ /arr }}</div>";
    console.log( sectionLayout );
    var $displayHeaders = Mustache.render( headerTemplate, { arr : sectionLayout } );

    $crewList.append( $displayHeaders );

    _.each( deckLayout, drawDeck );

}

// Disable alert screen
trek.onAlert( function() {

    return;

    } );

// Load the ship's systems map
trek.api( "operations/systems-layout", function ( d ) {

    systemsLayout = d;

    } );

trek.api( "operations/decks", function ( d ) {

     deckLayout = d;

     } );

trek.api( "operations/sections", function ( d ) {

    sectionLayout = d;

    } );

getInternalScanData();
setInterval( getInternalScanData, 2000 );
