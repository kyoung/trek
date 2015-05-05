stdin = process.openStdin()
stdin.setEncoding "utf8"

ai = require './AI'
{BattleState} = require './ai/State'
{Game} = require './Game'
game = new Game 'TinkerTailor', 1

p = ( msg ) -> console.log msg

atoi = ( str ) -> parseFloat str, 10

p "Welcome to the Star Trek bridge simulator..."
p ""

# get command of the Enterprise
startup_stats = do game.get_startup_stats
p startup_stats

enterprise_code = s.prefix for s in startup_stats.player_ships when s.name == "Enterprise"
p "Enterprise Prefix Code: #{ enterprise_code }"

ai_prefixes = ( s.prefix for s in startup_stats.ai_ships )
ai.play game, ai_prefixes, [ new BattleState(), ]

p "Klingon Prefix Code: #{ ai_prefixes[ 0 ] }"

prefix_code = enterprise_code

# play Captains log
p game.get_captains_log( prefix_code )

# initiate game
inputCallback = null
stdin.on 'data', ( input ) -> inputCallback input

promptForOrders = ->

    inputCallback = ( input ) ->

        command = input.replace( "\n", "" )
        p command
        p eval( command )
        p "\n"

    p "What are your orders, Captain?"

promptForOrders()
