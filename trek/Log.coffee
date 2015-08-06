U = require './Utility'

class LogEntry

    constructor: ( @entry, @data ) ->

        @stardate = do U.stardate

        date = new Date()
        @hour = date.getHours()
        @minute = date.getMinutes()
        @second = date.getSeconds()


    flat: ->

        data_block = if @data? then " [[DATA]]" else ""
        s = "#{ @stardate } - #{ @hour }:#{ @minute }:#{ @second }: #{ @entry }" + data_block


class Log

    constructor: ( @name ) ->

        @entries = []
        @_read_index = 0
        # Make sure the log is never empty, for indexing etc
        @log "Initializing #{ @name } Log"


    log: ( text, data ) ->

        @entries.push new LogEntry text, data


    retrieve: ( i ) ->

        # Allow for negative indexing, as Guido intended
        if i < 0
            i = @entries.length + i

        @entries[ i ]


    pending_logs: ->

        if @entries.length <= @_read_index
            return ""

        @_read_index += 1
        return @entries[ @_read_index - 1 ]



    length: ->

        @entries.length


    dump: ->

        r = ( e.flat() for e in @entries )


exports.Log = Log
exports.LogEntry = LogEntry
