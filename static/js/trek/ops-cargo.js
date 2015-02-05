var crewList = $( "#cargoList") ;
var internalScan_decks, scan_results;

trek.api(
    'operations/cargo',
    function ( data ) {

        var tmpl = $("#cargoTmpl").html()
        scan_results = data;
        _.each( data, function ( v, k, l ) {

            var cargo_list = [];
            _.each(v, function ( qty, inv, l2 ) {

                cargo_list.push( { sku : inv, qty : qty } );

            } );

            crewList.append( Mustache.render( tmpl, { bay : k, cargo : cargo_list } ) );

        } );

    } );

trek.onAlert( function () {

    return;

    } );
