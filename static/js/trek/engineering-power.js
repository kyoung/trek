
// Do nothing on red alert... the parent page will get the notification
trek.onAlert( function () {} );

var power_report;

var $system_display = $( "#system_display" );

var reactorTemplate = $( "#reactorTemplate" ).html();
var relayTemplate = $( "#relayTemplate" ).html();
var rerouteTemplate = $( "#rerouteTemplate" ).html();

function loadScreen() {

    if ( component == "undefined" ) {

        return

    }

    $system_display.empty();
    $system_display.append(
        $( "<p class='descriptiveText lightblue top'>" + component + "</p>" )
    );

    trek.api( "engineering/power", loadPowerReport );

}


function updateScreen() {

    trek.api( "engineering/power", updatePowerReport );

}


function loadPowerReport( powerJSON ) {

    var component_json = _.find(
        powerJSON[ power_type ],
        function (e) {

            return e.name == component;

        } );

    power_report = component_json;

    var system_html;

    if ( power_type == 'reactors' ) {

        component_json[ 'level_color' ] = 'lightblue';

        if ( component_json.output_level > 1 ) {

            component_json[ 'level_color' ] = 'red';

        }

        component_json.output_percent = Math.round(
            component_json.output_level * 100 );

        component_json[ 'op_percent' ] = ( 1 / component_json.max_level ) * 100;

        component_json[ 'max_percent' ] = ( component_json.max_level - 1 ) / component_json.max_level * 100;

        component_json[ 'power_percent' ] = component_json.output_level / component_json.max_level * 100;

        system_html = Mustache.render( reactorTemplate, component_json )

        $system_display.append( system_html );

        $( ".eng-sys-bar-frame" ).click( function( e ) {

            var $this = $( this );
            var offset = $this.offset();
            var x = e.clientX - offset.left;
            var width = $this.width();
            var clicked_id = this.id;

            var system = _.find(
                power_report.subsystems,
                function ( e ) {

                    return e.name == clicked_id;

                } );

            var max = power_report.max_level;
            var level = x / ( width / max );

            // If you're increasing the energy level of a reactor, you're likely going to blow
            // things up... force an override

            moveOutput = function () {

                trek.api(
                    "engineering/reactor",
                    { reactor: clicked_id, level: level },
                    'POST',
                    loadScreen );

            }

            if ( level > component_json.output_level ) {

                trek.confirm( "Increasing the power to a reactor will cause a cascade of damage to all attached systems. CONFIRM BEFORE PROCEEDING.", moveOutput );

            } else {

                moveOutput();

            }

        } );
        
    }

    else {

        console.log( component_json );

        _.each( component_json.subsystems, function( e ) {

            e[ 'power_percent' ] = e.current_power_level / e.max_power_level * 100;

            e[ 'min_percent' ] = e.min_power_level / e.max_power_level * 100;

            e[ 'op_percent' ] = ( 1 - e.min_power_level ) / e.max_power_level * 100;

            e[ 'max_percent' ] = ( e.max_power_level - 1 ) / e.max_power_level * 100;

            e[ 'power' ] = parseInt( e[ 'power' ] );

            e[ 'charge_percent' ] = e.charge * 100;

            e[ 'id' ] = e.name.replace( " ", "-" ) + '-charge';

        } );

        power_color = component_json.current_power_level > 1 ? 'red' : 'lightblue';
        component_json[ 'power_color' ] = power_color;
        component_json.power = parseInt( component_json.power );
        component_json[ 'power_percent' ] = Math.floor( component_json.current_power_level * 100 );

        system_html = Mustache.render( relayTemplate, component_json );
        $system_display.append( system_html );

        $( ".eng-sys-bar-frame" ).click( function ( e ) {

            var $this = $( this );
            var offset = $this.offset();
            var x = e.clientX - offset.left;
            var width = $this.width();
            var clicked_id = this.id;

            var system = _.find(
                power_report.subsystems,
                function ( e ) {

                    return e.name == clicked_id;

                } );

            var max = system.max_power_level;
            var level = x / ( width / max );

            var action = function () {

                trek.api(
                    "engineering/power",
                    { system_name : clicked_id, level : level },
                    'POST',
                    loadScreen );

            };

            if ( level > 1 ) {

                trek.confirm( "WARNING: Setting power to " + clicked_id + " above recommended levels.", action );

            } else {

                action();

            }

        });

    }

    if ( power_type == 'eps_relays' ) {

        var primary_relays = _.map(
            powerJSON.primary_relays,
            function ( e ) {

                return e.name;

            } );

        var current_relay = _.find(
            powerJSON.primary_relays,
            function ( e ) {

                sys = _.find(
                    e.subsystems,
                    function ( f ) {

                        return f.name == component;

                    } );

                return sys ? true : false;

            } );

        reroute_json = {

            primary_relays: _.map(
                primary_relays,
                function ( i ) {

                    class_color = i == current_relay.name ? "lightgreen" : "green";
                    return { name : i, class : class_color };

                } )

        }

        reroute_html = Mustache.render( rerouteTemplate, reroute_json );

        $system_display.append( reroute_html );

        $( ".reroute_id" ).click( function ( c ) {

            data = {
                eps_relay : component,
                primary_power_relay : this.id
            };

            trek.api(
                "engineering/eps-route",
                data,
                'POST',
                loadScreen );

        } );

    };

}


function updatePowerReport ( powerJSON ) {

    var component_json = _.find(
        powerJSON[ power_type ],
        function ( e ) {

            return e.name == component;

        } );

    if ( power_type == 'reactors' ) {

        return;

    }

    _.each( component_json.subsystems, function ( e ) {

        if ( !e.hasOwnProperty( 'charge' ) ) {

            return;

        }

        var width = e.charge * 100;
        width = width + '%';
        var id = e.name.replace( " ", "-" ) + '-charge';

        $( '#' + id ).css( 'width', width );

    } );

}

loadScreen();

setInterval( updateScreen, 1000 );
