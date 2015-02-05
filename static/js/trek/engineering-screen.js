
var sectionTmpl = $("#sectionStatusTmpl").html();
var systemTmpl = $("#systemStatusTmpl").html();


function drawStatus( data ) {

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

            var state = { section : sectionName, systemList : systemList };
            var $status = $( Mustache.render( sectionTmpl, state ) );

            $statusReport.append( $status );

            } );

        } );

    $( "#statusReport" ).html( $statusReport );

    $( ".online" ).click( function ( c ) {

        var online = "online";

        if ( this.innerHTML == "Online" ) {

            online = "offline";

        }

        var data = {
            system: this.parentElement.id,
            online: online,
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
            system: this.parentElement.id,
            active: active,
        }

        trek.api(
            "engineering/active",
            data,
            'POST',
            loadScreen )

        } );

}


function loadScreen() {

    trek.api( "engineering/status", drawStatus );

}

trek.onAlert( function( data ) {

    return;

    } );

// Make it so
loadScreen();

setInterval( loadScreen, 250 );
