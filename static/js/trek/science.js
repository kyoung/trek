
var $SRScan = $( "#sr_scan" );
var $LRScan = $( "#lr_scan" );
var $detailScan = $( "#detail_scan" );
var $internalScan = $( "#internal" );
var $environmentalScan = $( "#environmental" );

var $viewMenu = $( "#viewMenu li" );
var $scienceSubMenues = $( ".science-sub_menu" );
var $SRScanMenu = $( "#sr_scan_menu" );
var $SRScanMenuLi = $( "#sr_scan_menu li" );
var $LRScanMenu = $( "#lr_scan_menu" );
var $LRScanMenuLi = $( "#lr_scan_menu li" );
var $detailedScanMenu = $( "#detailed_scan_menu" );

var $mainViewer = $( "#mainViewer" );

var selectedSubmenu;

var $viewScreen = $( "#viewScreen" );


$SRScan.click( function ( c ) {

    $viewScreen.attr( 'src', 'science_scans' );
    $scienceSubMenues.addClass( 'hidden' );
    $SRScanMenu.removeClass( 'hidden' );

} );


$LRScan.click( function ( c ) {

    $viewScreen.attr( 'src', 'science_scans_lr' );
    $scienceSubMenues.addClass( 'hidden' );
    $LRScanMenu.removeClass( 'hidden' );

    } );


$detailScan.click( function ( c ) {

    $viewScreen.attr( 'src', 'science_details' );
    $scienceSubMenues.addClass( 'hidden' );
    $detailedScanMenu.removeClass( 'hidden' );
    refreshHighresMenu();

    } );


$internalScan.click( function ( c ) {

    $viewScreen.attr( 'src', 'science_internal' );
    $scienceSubMenues.addClass( 'hidden' );

    } );


$environmentalScan.click( function ( c ) {

    $viewScreen.attr( 'src', 'science_environmental' );
    $scienceSubMenues.addClass( 'hidden' );

    } );


$viewMenu.click( function ( c ) {

    $viewMenu.removeClass( 'lightblue' );
    $( this ).addClass( 'lightblue' );

    } );


$SRScanMenuLi.click( function ( c ) {

    args = { type : this.id };
    $viewScreen.attr( 'src', 'science_scans?type=' + this.id )
    selectedSubmenu = this.id;

    } );


$LRScanMenuLi.click( function ( c ) {

    args = { type : this.id };
    $viewScreen.attr( 'src', 'science_scans_lr?type=' + this.id );
    selectedSubmenu = this.id;

    } );


function loadHighresReading ( results ) {

    console.log( results );
    $detailedScanMenu.empty();

    var $ul = $( "<ul class='menu x1'></ul>" );
    var liTempl = "<li class='green'>{{ classification }}</li>";

    _.each( results.classifications, function ( e ) {

        // TODO: this is a hack... really, these should all be collapsed or grouped
        if ( e.classification == "Plasma Cloud" ) {

            return;

        }

        var $li = $( Mustache.render( liTempl, e ) );
        $li.click( function ( c ) {

            $viewScreen.attr(
                'src',
                'science_details?classification=' + e.classification + "&distance=" + e.distance + "&bearing=" + e.bearing.bearing + "&tag=" + e.tag );

            } );

        $ul.append( $li );

        } );

    $detailedScanMenu.append( $ul );

}


function refreshHighresMenu () {

    trek.api(
        "science/scanResults",
        { type : "Passive High-Resolution Scan" },
        loadHighresReading )

}


function screenToMainViewer () {

    trek.api(
        "command/main-viewer",
        { 'screen' : $viewScreen.attr( 'src' ) },
        "POST",
        function () {

            return;

        } )

}

$mainViewer.click( screenToMainViewer );


function displayInternalAlarm ( data ) {

    trek.playAlarm();
    $internalScan.addClass( 'red' );

}


trek.socket.on( 'internal-alarm', displayInternalAlarm );


$SRScan.click();

trek.registerDisplay( "Science" );
trek.checkBlastDamage();
trek.playBridgeSound();
