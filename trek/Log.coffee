U = require './Utility'

class LogEntry

    constructor: ( @entry ) ->

        @stardate = do U.stardate

        date = new Date()
        @hour = date.getHours()
        @minute = date.getMinutes()
        @second = date.getSeconds()


    flat: () ->

        s = "#{ @stardate } - #{ @hour }:#{ @minute }:#{ @second }: #{ @entry }"


class Log

    constructor: ( @name ) ->

        @entries = []
        @_read_index = 0


    log: ( text ) ->

        @entries.push new LogEntry text


    pending_logs: () ->

        if @entries.length <= @_read_index
            return ""

        @_read_index += 1
        return @entries[ @_read_index - 1 ]



    length: () ->

        @entries.length


    dump: () ->

        r = ( e.flat() for e in @entries )


exports.Log = Log
exports.LogEntry = LogEntry