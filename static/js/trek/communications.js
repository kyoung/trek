
var commlog = $( "#commlog" );
var $send_window = $( "#textinput" );
var $chat_history = $( "#chat_history" );

trek.socket.on( "hail", function ( data ) {

    commlog.append( "<li class='recieved'>" + data + "</li>" );
    scrollToBottom();

} );

window.onkeyup = function ( d ) {

    if (d.keyIdentifier == "Enter" || d.key == "Enter" ) {

        trek.api(
            "communications/comms",
            { message : $send_window[ 0 ].value },
            'POST',
            loadComms )

        $send_window[ 0 ].value = "> ";

    }

};

function scrollToBottom () {

    $chat_history.scrollTop( $chat_history[ 0 ].scrollHeight );

};

function loadComms () {

    trek.api(
        "communications/comms",
        function ( data ) {

            commlog.empty();

            _.each( data, function ( d ) {

                if ( d.type == "sent" ) {

                    commlog.append( "<li class='sent'>" + d.message + "</li>" );

                } else {

                    commlog.append( "<li class='recieved'>" + d.message + "</li>" );

                }

            } )

        } );

};

loadComms();

trek.onAlert( function( data ) {

    return;

    } );
