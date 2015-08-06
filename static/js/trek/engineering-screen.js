
var sectionTmpl = $( "#sectionStatusTmpl" ).html();
var systemTmpl = $( "#systemStatusTmpl" ).html();
var hullTmpl = $( "#hullStatusTmpl" ).html();

var $hullReport = $( "#hullReport" );

var cachedStatus;

function drawStatus( scanResults ) {

    if ( scanResults == cachedStatus ) {

        return;

    }

    cachedStatus = scanResults;
    data = scanResults.systems;
    var $statusReport = $( "<div></div>" );

    var systemsBySection = _.groupBy( data, function ( d ) {

        return d.section;

        } );

    _.each( systemsBySection, function ( systemsObjects, sectionName ) {

        var systemList = "";

        _.each( systemsObjects, function ( systemObj, systems ) {

            var color = "blue";
            var online = "Online";

            if ( systemObj.integrity < 1 ) {

                color = 'lightblue';

            }

            if ( systemObj.operability != 'Operable' ) {

                color = 'red';

            }

            if ( !systemObj.online ) {

                color = 'green';
                online = "Offline";

            }

            context = {
                systemName : systemObj.name.replace( "_", " " ),
                integrity : Math.floor( systemObj.integrity * 100 ),
                // charge: systemObj.charge * 100,
                systemColor : color,
                online : online
            }

            if ( systemObj.hasOwnProperty( 'active' ) ) {

                if ( systemObj.active ) {

                    context.active = "Active";

                } else {

                    context.active = "Inactive";

                }

            }

            systemList += Mustache.render( systemTmpl, context );

            } );

            var state = { section : sectionName, systemList : systemList };
            var $status = $( Mustache.render( sectionTmpl, state ) );

            $statusReport.append( $status );

        } );

    $( "#statusReport" ).html( $statusReport );

    $( ".online" ).click( function ( c ) {

        var online = "online";

        if ( this.innerHTML == "Online" ) {

            online = "offline";

        }

        var data = {
            system : this.parentElement.id,
            online : online,
        }

        trek.api(
            "engineering/online",
            data,
            'POST',
            loadScreen )

        } );

    $( ".active" ).click( function ( c ) {

        var active = "active";

        if ( this.innerHTML == "Active" ) {

            active = "inactive";

        }

        var data = {
            system : this.parentElement.id,
            active : active,
        }

        trek.api(
            "engineering/active",
            data,
            'POST',
            loadScreen )

        } );

    drawHull( scanResults.hull );

}

var cachedHullData = {};

function drawHull( hullData ) {

    if ( hullData == cachedHullData ) {

        return;

    }

    cachedHullData = hullData;

    // hullData
    //  {
    //     A: {
    //         Port: 1,
    //         Starboard: 1,
    //         Forward: 1,
    //         Aft: 1
    //     },
    //     ...

    var deckList = [];
    var color = function ( deckHealth ) {

        switch (true) {
            case ( deckHealth == 1 ):
                return 'blue';
            case ( 0.7 <= deckHealth < 1 ):
                return 'lightblue'
            case ( 0.4 <= deckHealth < 0.7 ):
                return 'green';
            case ( deckHealth < 0.4 ):
                return 'red';
        }

    }

    // convert to
    // [ { Deck : 'A', portColorClass : 'blue', starboardColorClass : 'blue', forwardColorClass : 'blue', aftColorClass : 'blue' } ]

    _.each( hullData, function( v, k ) {

        var entry = { deck : k };
        entry.portColorClass = color( v.Port );
        entry.starboardColorClass = color( v.Starboard );
        entry.forwardColorClass = color( v.Forward );
        entry.aftColorClass = color( v.Aft );
        deckList.push( entry );

    } )

    deckList = _.sortBy( deckList, function ( i ) { return i.deck; } );

    deckHtml = Mustache.render( hullTmpl, { hull : deckList } );
    $hullReport.html( deckHtml );

}

function loadScreen() {

    trek.api( "engineering/status", drawStatus );

}

trek.onAlert( function( data ) {

    return;

    } );

// Make it so
loadScreen();

setInterval( loadScreen, 1000 );
