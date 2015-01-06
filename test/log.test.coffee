{LogEntry, Log} = require '../trek/Log'

exports.LogTest =

    'test can log': ( test ) ->

        l = new Log 'test log'
        l.log "This is a test log"

        do test.done