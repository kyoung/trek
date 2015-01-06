stdin = process.openStdin()
stdin.setEncoding "utf8"

{Game} = require('./Game')
game = new Game('')

p = ( msg ) ->
    console.log msg

atoi = ( str ) ->
    parseFloat(str, 10)

p "Welcome to the Star Trek bridge simulator..."
p ""

# get command of the Enterprise
ships = game.get_startup_stats()
p ships
enterprise_code = s.prefix for s in ships when s.name == "Enterprise"
reliant_code = s.prefix for s in ships when s.name == "Reliant"
p "Enterprise Prefix Code: #{enterprise_code}"
p "Reliant Prefix Code: #{reliant_code}"

prefix_code = enterprise_code

# play Captains log
p game.get_captains_log(prefix_code)

# initiate game
inputCallback = null
stdin.on 'data', ( input ) -> inputCallback input

promptForOrders = ->
    inputCallback = ( input ) ->
        command = input.split(' ')
        command = (i.replace("\n", "") for i in command)
        order = command[0]
        result = switch order
            when "scan" then game.scan(prefix_code)
            when "position" then game.get_position(prefix_code)
            when "set"
                switch command[1]
                    when "course" then game.set_course(prefix_code, atoi(command[2]), atoi(command[3]))
                    when "speed"
                        if command[2] is "warp"
                            game.set_warp_speed(prefix_code, atoi(command[3]))
                        else
                            game.set_impulse_speed(prefix_code, atoi(command[2]))
            when "raise" then game.raise_shields(prefix_code)
            when "target" then game.target(prefix_code, command[1])
            when "fire"
                switch command[1]
                    when "phasers" then game.fire_phasers(prefix_code)
                    when "torpedoes" then game.fire_torpedo(prefix_code)
            when "plot"
                game.plot_course_and_engage(prefix_code, command[1], command[2], command[3])
            when "match"
                game.match_course_and_speed(prefix_code, command[1])
            when "stop" then game.full_stop(prefix_code)
            when "red" then game.set_alert(prefix_code, "red")
            when "command"
                switch command[1]
                    when "Reliant" then prefix_code = reliant_code
                    when "Enterprise" then prefix_code = enterprise_code
            when "damage" then game.get_damage_report(prefix_code)
            else "Command not understood"
        p result
        p "\n"
    p "What are your orders, Captain?"

promptForOrders()
