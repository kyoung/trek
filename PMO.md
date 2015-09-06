# Trek PMO
Trek Project Management, because sometimes a checklist is all you need.

# Coordinate System
## Headings
Counterclockwise, 0 - 1, the x axis marks 0, for simplicity of trig. The bearing system is [LONGITUDE] mark [LATITUDE]. Latitudinal movement is not yet implemented.

# Tech debt and refactoring: TODO Before v.1.0 can be declared
- [ ] Consolidated CSS
  - [ ] Also, refactor to use stylus
- [ ] Class-selector CSS
  - [ ] find and kill all id-based css rules
- [ ] All HTML must use base templating
- [ ] Fix the API
  - [x] Get the API turned into a RESTful API
  - [ ] Consolidate the endpoints so that it"s not just one method per url
- [x] Reduce the use of Constants
  - Rely more on class variables for these things
- [ ] Speed up the test; rely less on timeouts by forcing the elapse of time through the delta_t ability
  - [ ] crew test
  - [ ] ship test
      - [ ] ship.test.coffee -t "test alert settings"
  - [ ] game test
- [ ] Get the authors of the Mesh"s names in a credits file, ideally the main README.md, and as a menu item off of the main screen


# Current Sprint
## AI
- AI
  - [x] We need to be able to create hostile players to fight
  - We need to be able to create cooperative players to help, and to communicate with
  - [x] Create a klingon enemy ship
  - [x] Create a new level where we have to fight a hostile
    - [x] Create the level such that there is a spy
    aboard the enemy ship, and we must beam them off
    - [x] Have the level require the use of sensors to solve
        - [x] Have things detected with passive hi-res scans show up for nav and tactical displays
  - [x] Write an AI client that can act and respond with the API
  - [x] Wire up the AI to respond to either level events or with it's messaging
- Sector maps and other systems
    - Setup LY-based coordinates for objects not in systems
    - Compound coordinates? LY coordinates, offset by metrics is you"re in a system
    - In system sets your LY coordinates to that of the system, and calculates your offset as your position
    - Enter and leave systems when your delta to a system closes within 80AU
- Patch Long-Range Sensors and SR Sensors
    - Simplify the models
    - [x] Have LR sensors detect ships and allow configuration

## Hotfix
- Bugs
    - [ ] Detail scans are broken
        - unable to confirm
    - [ ] ChinTok seems to have it's shields up after the sabotage in TinkerTailor
    - [ ] "Mainviewer" command doesn't work in the "warp" system menu
    - [ ] ChoRe completely flies past the ships
    - [ ] Transporting cargo destination menu is *really* slow between refreshes, for no apparent reason
        - It also seems that the DOM is there, just not displaying... turning any property on and off in the dev tools causes the menu to display?!
- UX Fail
    - [ ] Can't dismiss target selection list
    - [ ] Can't go back or forth in the academy mode (should make it optional to just disiss or skim these)

- [ ] Torpedoes are way overpowered...
- [ ] Spy shows up as a (green) Intruder on the crew display
- [ ] AI doesn't know how to handle ship operations/emergencies etc...
- [ ] Engineering overload is still busted
- [ ] Use input sliders for engineering:
  - https://css-tricks.com/styling-cross-browser-compatible-range-inputs-css/
- [ ] Pushing power to the bridge seems to blow it... causing massive disruption to all consoles
- [ ] use data-crew_id attributes for crew movement... there have been a few instances where prisoners seem to be becoming intruders somehow. Suspect this is due to improper crew selection.
- [ ] The internal alert indicator never sets back to blue when there is no longer an internal alert
- [ ] Transporter doesn't stop you from trying to transport without having selected a destination
- [ ] Science Scanner circles don't show up on FF
  - http://roadtolarissa.com/blog/2015/02/22/svg-path-strings/


# Backlog
## Next Sprint


## Backlog For Breakout
- Engineering systems should be grouped / filterable by functional requirements (IE goto warp requires nacels, nav, dampeners, integrity fields, etc)
- [ ] get a new mesh for the outposts... they're not Stations, they're power collectors. Design appropriately.
    - [ ] build new mesh
    - [ ] instantiate the new stations as a new Ship Class, not as a "Station" objects
    - [ ] get rid of the station object. Merge into Ship
- Cargo run: we should be able to transmit to Starfleet that we need a given supply and have a supply ship bring it from the nearest starbase.
- Configuration of scanners
  - Let the arc of the scanner be selected
  - Let LR sensors be selected
  - Do something more with sensors
  - Objects get tracked once we"ve done a detailed scan... so how do we untrack them? At some point, we should be able to loose them (ie clocked, moved out of range, etc)
- Lifesupport loss should mean the crew dies in N minutes
- Show phaser fire, as we do torpedoes
- Pretty Renders
  - http://devlog-martinsh.blogspot.ca/2011/12/glsl-depth-of-field-with-bokeh-v24.html
  - Just putting a minor blur on the material might be enough
  - Also, making the stations rotate a bit could help
- Tractor Beam
- Shuttles
  - If transporters and related systems are down, you"ll need to be able to ferry cargo
- The ability for engineering to salvage parts from non-essential systems during an emergency
- All the render delay is in the loader... if we"re going to cache anything in the display, it should be in the parent frame, and then into local storage...
- Use this for animating transporters:
  - http://julian.com/research/velocity/
- Explosions disrupt warp fields (seems needed for realism, but if not, makes for good ability to run away); perhaps?
  - Might not be needed; you"ll want to drop out of warp to turn and fight
- Additional Screens
  + "Scotty" nback iframe
    + Minigame for engineering to allow miracle fixes
  + Library / Logs
  + Working sector nav
- Some kind of computer interface for querying and library functions
- [ ] Academy storage, .gitignored
  - Player ID maps to email, score, and completed training
  - Rank is determined by number of successfully completed missions at each station
    - 0: Cadet
    - 1: Ensign
    - 2: Lieutenant
    - 3: Lieutenant Commander
    - 4: Commander
    - 5: Captain

# Alpha Test Issues
Feedback taken from real user testing
- [ ] Justin/Tactical still just wants to shoot things... we might need more responsibilities, or to keep them busy with chatter traffic.
  - Comms-based minigame?
- [-] There was a strange error where going to warp was prevented by the Inertial Dampeners being offline... Engineering showed that they were completely online... What's up with that?


# Bug log


# Completed Sprints

## v0.1 [COMPLETE]
### Basic Combat, pt III
- [x] Start a game and get given a prefix code, and captain"s log
- [x] Scan for ships
- [x] Get bearings to enemy ship
- [x] Set course
  - [x] Fix the ship so that changes to heading will alter the velocity
- [x] Set impulse to get closer to ship
- [x] Raise shields
- [x] Target ship
- [x] Fire at ship until a shield fails
- [x] Warp out to escape

## v0.2 [COMPLETE]
### Basic Combat, pt II
- [x] set warps greater than 1 accurately
- [x] scan for a moving target
- [x] plot a course (intercept)
  + [x] match base velocity and heading
- [x] have the computer match speed and heading when we approach a nav target (destination)
- [x] fire torpedos
  + [x] arm torpedos
  + [x] Vmax = Vi - [x](0.75\*(Vi/c))
  + [x] have torpedoes plot intercept coordinates
  + [x] torpedoes set to steer in warp, and tuned the honing parameters (otherwise no chance)
- [x] get shot (MVP = no AI: used `command` instead)
- [x] phasers shouldn"t work at warp
- [x] destroy a target
- [x] set alerts

## v0.2b
### Console MVP [COMPLETE]
- [x] Have a welcome screen severed in a web console
- [x] Select a ship: Enter a prefix number, get validated
- [x] Get presented with a lists of screens
  + [x] Conn (Helm & Navigation)
    * [x] Display a map of the system with scan objects
    * [x] *for whatever reason this only works once, and not on refresh*
    * [x] Set course
    * [x] Set speed
    * [x] Plot intercept with object
    * [x] x(this was an ugly ugly hack: NEEDS REFACTOR)
    * [x] might be nice to return estimated intercept time so the client can start a countdown
    * [x] Improved workflow: plot intercept target, then set speed per usual and engage handles the "if intercept\_target" business
  + [x] Tactical
    * [x] Select targets
    * [x] Fire weapons
    * [x] Set alert

## v0.2c
### Console MVP [COMPLETE]
- [x] Main viewer
  + [x] Ability to assign URLs to the mainviewer
- [x] Tactical
  + Notes:
    * Phaser range = 1,000km
    * Torp range = 300,000km
    * 16 yield levels (let"s make this exponential)
    * Phasers can fire at warp if you"re *very* close together (5km)
    * http://www.ex-astris-scientia.org/inconsistencies/treknology-weapons.htm
  + [x] Select yield options
  + [x] Weapons range viewer / zoom ability
  + [x] Phaser / Torp zoom
  + [x] Draw a circle around the ship to show range
  + [x] Torpedo inventory (96 from a manual count in ST:VI)
  + [x] *BUG* Range seems wrong: closing to within < 1000km still shows target outside the circle
  + [x] Initial state settings / update state
- [x] Proper damage calculations for the world
- [x] Pull out torpedo logic, and replace with a probability of impact, or something more controlled than JS trying to impact some integers w/ clock calcs
- [x] Engineering
  + [x] Damage report

## v0.3 [COMPLETE]
### Cargo / Transporters / Repair Teams (OPS Theme)
- [x] visit space stations
  + [x] cargo scans
  + [x] cargo transporters
- [x] beam personelle to other stations
  + [x] beam security teams aboard
  + [x] beam teams back
- [x] get cargo from stations
- [x] I want to be able to assign repair crews
- [x] send hails
- [x] View stations on screen
  + [x] Get initial starfield
  + [x] Display three.js asset
  + [x] Have a star
  + [x] Create Viewscreen page with camera options
    * [x] Foreward
    * [x] Selected target
  - [x] Define a visual range
- [x] Web Interface:
  + [x] Ops
    * [x] Transporters / Away Missions
      - [x] View places within transporter ranger
      - [x] Transport away teams away
      - [x] Transport away teams to
      - [x] Transport crew from
        - [x] Need to rebuild crew and internal_personnel whenever sublists change
      - [x] Transport cargo to
      - [x] Transport cargo away
    * [x] Repairs
      - [x] View damaged system details
      - [x] Send repair crews to different systems
    * [x] Crew
      - [x] View crew on different decks
      - [x] Send crew to different decks
    * [x] Cargo/inventory mgmt

## v 0.4 [COMPLETE]
- [x] Hull Damage
  + [x] When phaser fire is incurred, the hull should be damaged
  + [x] When torpedo / explosions occur, the hull should be damaged
- [x] Damage distribution
  + [x] Systems should be damaged according to the deck they hit
  + [x] Shields should only offer a dampening of damage, and that should decrease as they weaken
- [ ] Levels
  + [x] Load level objects
  + [x] Have ships, stations, and celestial objects be defined in the level
  + [x] Have a victory condition specified in the level that can be tested
  + [x] Have some means of displaying a "Game Over" message to all the teams
    * [x] EJS alows for imports; use these to build up templates and trek.js
    * [x] http://css-tricks.com/animating-svg-css/

## v 0.5 [COMPLETE]
- [x] Power Systems
  - [x] Systems must have a greyout, operational, and maxrated power level
  - [x] Systems are tied together via EPS grids
  - [x] System power status should be checked as part of it"s health check
  - [x] Systems above operational rating should experience damage
  - [x] Systems above max rated should have a probability of blowing
  - [x] EPS Grids must distribute all their power to all sub systems
  - [x] EPS Grids can themselves overload if too much power is passed through them
  - [x] Warp core and impulse reactors can have their energy output scaled up and down
- [x] Ship Power Systems
  - [x] Power systems should be able to calculate the draw required of their attached systems
  - [x] Have ability for ship to calculate and plot complex power routes (IE Warp power to forward shields) for as not to blow up all the power relays
  - [x] Systems performance should now be taken into account (system.performance()) when using the systems (IE Transporter range, shield regeneration, sensor range, phaser strength, etc)
  - [x] Have charge systems recharge over time, provided they have power (the recharge rate is x1 at operational power, <1 in the greyout band, and >1 in the operational to max band)
  - [x] Reactors should be able to be turned down, causing power drains to systems
  - [x] EPS junctions should be able to be switched to impulse or emergency power
- [x] Allocated Power
  - [x] Engineering should be able to dial up individual system power
  - [x] Engineering should be able to reroute EPS sources
  - [x] Engineer should be able to turn systems on and off
  - [x] Engineer should be able to dial down reactors

## v 0.6 [COMPLETE]
- [x] Working Science Screen
  - For reference: http://www.startrekfreedom.com/wiki/index.php/Sensors
  - [x] Scans by volume/time/type
    - [x] Ship scan
    - [x] Game object scan setup
    - [x] Long Range scanners
    - [x] Short Range scanners
      - [x] Quadrant limiting
  - [x] Long Range scanners
    - [x] See scans and display them
    - [x] Need to be able to set configuration...
  - [x] Detailed scans of targeted objects
    - See discussion below on Highres scanning
  - [-] Spatial objects
    - [-] asteroids
    - [x] dust disks
    - [x] stars
    - [-] anomalies
    - [-] protoplanetary clusters
  - [x] Skewed circle of blocks with a data overlay in the bottom right corner: http://jsfiddle.net/4j8pn/6/
- [-] Debt
  - [x] Store results in scanner in absolute values; translate to relative only when reporting
  - [x] Scanner have multiple subarrays... refactor so that scanners can run multiple scan types simultaneously, and store those results
  - [x] Passive HighRes is the scan that detects ships, and should get special treatment...
  - [x] Active HighRes, (as well as navigation and weapons targeting) should be available once Passive HighRes has successfully isolated a target
  - [-] While it"s nice that plasma clouds block scans, they should also be able to simply limit/attenuate scans
  - [x] Expose a "scanStatus" api, and include a time-to-complete/progress property on the scanner system
- [x] Hotfix: Plot intercept course appears to be 0.5 off of the actual required bearing (WTF?)
- [-] Hotfix: Gravimetric scans should always detect the local star, why doesn"t it? *Totally not a problem... the LR scan only displays a quarter of the ring (fwd sweep) We should just make sure the ring in the browser only shows those grids.*
- [x] Hotfix: The grid numbers on the display are arranged backwards...
- [x] Hotfix: When "setcourse" gets called, we end up seeing it mulptile times on the server?
- [-] Hotfix: Changing scan resolution settings seems to now clear the device..
- [x] Hotfix: The sensor_sub screens don"t handle red alerts correctly
- [x] Hotfix: Wire the transporter scans to use what the sensors see

## v 0.7 [COMPLETE]
- [x] Comm Refactor
  - [x] Clearing out underscores from names
  - [-] Plotting course to stationary objects is broken
  - [-] Velocity doesn"t work at warp
  - [x] Setting speed above warp 6 is broken in the interface
  - [x] Ability to zoom around
  - [x] Fix the "Plot intercept" menu as a fly out that display over the screen to select a target
  - [x] Fix "Plot Intercept" to kill negative number results, and display an error if the plotted intercept was impossible.
- Error Handling
  - [x] When express.js throws a 500 error, I want the client to be passed the message, so they can take action if desired.

## v 0.8 [COMPLETE]
- [x] Tactical
  - [x] Torpedo loading needs to be limited
    - [x] Torpedo tube launch status EMPTY... LOADING... LOADED
    - [x] on Red Alert, begin loading tubes
  - [x] The location of the ship seems to disapear when the subspace transponder is offline... we should probably fix that so that the ship is filtered out of the scan, but automatically inserted back in the display
  - [x] The target selection flyout menu should be a flyout, like the intercept menu
  - [x] Fix underscores in names
- [-] Balanced Weapons
  - [-] Tactical situation tests: Two constitution classes should be able to go toe-to-toe for more than one volley
- Torpedo logistics
  - [x] Have torpedo tubes
  - [x] Require tubes to be loaded, with a timeout
  - [x] Ensure inventory is managed
  - [x] Firing a torpedo without a target needs to be addressed/disabled
- [x] Ensure that jumping to warp would allow you to evade a torpedo
- [x] Have torpedoes send out notices to anyone looking at a target that they"re about to hit
- [x] On torpedo hit, have every screen show damage
- [x] When you destroy a target, have it blow up in displays
  - [x] There"s a bug with stations getting hit where they seem to all disapear
  - [x] How do stations process damage?

## v 0.9 [COMPLETE]
- [x] Ops Love
  - [x] Transporters don"t seem to be working
  - [x] Crews en-route to destinations should be displayed as such
  - [-] ... make more awesome?

## v 0.10 [COMPLETE]
- [-] Engineering
  - [-] We need a feedback screen when something blows up, power wise
  - [-] EPS relay destruction needs to be more apparent
- [x] Bug:
  - [x] Trying to set the power of the Aft EPS circuit down to 99% causes the output to rise?!

## v 0.11 [COMPLETE]
- [x] Science
  - [x] The active scan needs to display a progress bar of some kind
    - [x] Scanning... Complete... Compiling composite scan...
    - [x] The active scan array should be able to work even when the ship has turned. This could be accomplished by giving every object a base GUID that we could then use to track back on, like an object hash.
    - [x] We need to display the text outputs
  - [x] We need to display power readouts

## v 0.12 [Sidetracked and reprioritized]
- [x] Battle Ratios
  - [x] Balance the torpedo hits, sheild balances and hull strengths required for accurate combat simulation
  - [x] Check to see if it"s possible to get phasers working correctly here
  - [x] Torpedoes need to clear post-detonation
  - [x] White flash for explosions...
- [ ] Navigation
  - [x] Time to turn and make course corrections
    - [x] The viewscreen should indicate turns
  - [x] Warp animations
  - [ ] Thruster manuvering
    - We should have the ability to steer around other ships with thrusters
    - Especially true if we want to turn the ship in combat
    - [x] ability to rotate the ship around
      - [ ] Use callback result to highlight button
    - [x] put in delay when turning
    - [-] put in delay when jumping to warp
    - [-] put in acceleration delay
  - [-] Charge time on warp
  - [-] Warp powers require more power
    - [-] Handles the routing of extra power to manage the warp drive systems
  - [ ] Have the current operation and speed be displayed on the nav screen
- [ ] Need the ability to see the current sheild levels

## v 0.13 [COMPLETE]
- [x] Fix Transporters
- [x] Fix Operations / Internal crew movement
  - [x] Where are the rest of the crews?
- [x] Fix the Impulse direction indicator
  - [x] Also note, the direction indicator on the tactical screen is a flipped representation from the conn screen.
- [x] Fix combat
  - [x] torpedo strikes don"t seem to be working well
  - close range maneuvering is required for phasers
- [x] Captains log
  - [x] Get a captain"s log displaying when the main viewer initiates
- [x] Cooperative Mission Profile
  - [x] We need environmental and internal science screens
    - [x] Environmental
    - [x] Internal
  - [-] We"ll need subsystem targeting for weapons
    - Move this to the tactical refactor
  - [-] We"ll need engineering and tactical to have a better shield status display
    - It"s kind of nice that they have to check with engineering, and that engineering has to click around
  - [x] Create a scenario where two teams must cooperate
    - [x] Make it possible to win solo
  - [x] Create game level events to trigger actions
- [-] Engineer minigame miracle fixes
  - This may still be needed later on, but shouldn"t strictly be neccessary
- [x] Engineering power allocation fixes
- [x] Music/sound (Theme music, and red alerts. Phasers and torpedo hits.)
  - [x] https://www.youtube.com/watch?v=7J-y2rFfny8 (red alert)
  - [x] Enterprise-B bridge sounds from Generations
  - [x] Theme from Original Motion picture
  - [-] Explosions
    - Save this for developing the bridge system and handling broken screens etc.
  - [x] Transporters
  - [x] Alerts
  - [x] Torpedo firing
  - [x] Phaser firing

## v 0.14 [Engineering/COMPLETE]
- [x] Engineering warning on dangerous power level bumps
  - [x] Refresh the side screen when power levels are no longer critical
  - [x] Risks to systems should be made clear
    - [x] Include EPS percentage
    - [x] Force a confirmation popup when above safety line
  - [x] Systems should be damaged more than they currently are from over use
  - [x] EPS blowout status needs much better visual representation
    - [x] include sound effect and cracked screen as well

## v 0.15 Tactical Upgrade [COMPLETE]
- [x] Tactical
  - [x] Breakout the phaser, torpedo, targeting, alert, and comms screens
  - [x] Phaser screen should indicate charge buildup of each bank
    - [x] *Bug* Phasers won"t fire
  - [x] Targeting will need to have subsection targeting
  - [x] Shield screen should indicate the strength, charge, and status of each shield

## v 0.16 Crew Magic [COMPLETE]
- [x] Crew interactions
  - [x] Healing from medics
  - [x] Heal crews in sickbay
  - [x] Repair teams should be able to fix bridge damage
    - [x] The bridge has to be a system
    - [x] Damage to consoles gets dolled out from here
  - [x] Engineering teams should limit/prevent overdrive damage
  - [-] Science teams should ...
    - [-] Figure out what science teams should be able to actually do
      - Should be required for the mission profile: this is in keeping with cannon
  - [x] Game over if crew is dead

## v 0.17 Navigation [COMPLETE]
- [x] Navigation
  - [x] Thruster maneuvering
    - required for phaser combat
  - [x] Navigation status display

## v 0.18 Prettier display [COMPLETE]
 - [x] Viewscreen selection needs something other than the separate "viewscreen" page... either a mobile-friendly selector, or a flyout menu off of the main viewer
     - [x] Remove the iframe
     - [x] Make mobile friendly
 - [x] Background nebula art
     - [x] Build out a star map background
     - [x] Create a basic star and nebula bit of art
         - http://www.webdesign.org/photoshop/special-effects/space-nebula.13396.html
         - http://design.tutsplus.com/tutorials/ringed-planet-supernova-photoshop--psd-12301
         - http://glennclovis.deviantart.com/art/Helio-Nebula-Tutorial-115604344?q=1&qo=1
     - [x] It would be nice to be able to scan the star: We"d need a basic mesh for it, but that seems pretty simple

## v 0.19 The third dimention! [COMPLETE-ISH]
- [x] z-axis implementation
    - [x] Allow ships to set course using "m": 0-250, 750-1000 are both valid sets... anything else, just turn the ship around
    - [x] display -/+ z values on system map displays
    - [x] have the stations start at positions other than z : 0
    - [x] figure out if/how to patch the rotation of the ship
        - turning left/right while pitched up does different things depending on the angle of attack... we could get all fancy with quaternions, but at the end of the day, this is meant to be a ship, not a fighter. It would make sense for safety reasons to limit the accumulation of angular momentum, and if we decide we"re okay with this, we don"t have to do anything.
- [x] have radiation levels increase the closer you get to the star
    - [x] safety zone > 20AU should allow a safe muster point
    - [x] science scans of the star should indicate this information
- [-] begin using the accretion disk
    - [x] have radiation be dampened by the accretion disks / dust cloud objects
    - [x] have the dust inform the particle density environmental value
    - [x] have the particle density figures corelate to max-possible warp speed
        - this gets super annoying... let"s balance this a bit more
        - [x] when the nav drops out of warp, display a message to the conn screen (socket it)
        - [x] when the computer detects a lower required speed, drop to that speed, not zero
        - [-] play with lowering the particle density some more
        - [-] the visible gas clouds don"t seem to line up with the observed particle density
    - [x] display the distribution of gas clouds on the sector screen
    - [x] have clouds appear more radially, and at harmonics
- [x] have warp drive be a charge-depleting action on the nacelles

## v0.20 Academy Courses [COMPLETE]
- Academy!
  - [x] Training missions
    - [x] Build an SVG/HTML training mission plugin
    - [x] Hash SVGs to know which training is complete, use local storage
    - http://maxwellito.github.io/vivus/
    - [x] Comm
      - [x] How ship turning works
      - [x] How to read distance, bearing, and z-axis
      - [x] How warp works
      - [x] Warp vs impulse
      - [x] Thrusters and newtonian bits
    - [x] Ops
      - [x] Transporting cargo
      - [x] Moving crew
      - [x] Conducting repairs
      - [x] Checking cargo
    - [x] Tactical
      - [x] Operating the communications systems
      - [x] Alerts
      - [x] Torpedoes
      - [x] Phasers
      - [x] Shields
      - [x] Tarteging
    - [x] Science
      - [x] Readings a scanner
      - [x] LR vs SR scanners
      - [x] Detailed scans
      - [x] Internal Sensors
    - [x] Engineering
      - [x] Systems: Active / Online
      - [x] How power works on a star ship
      - [x] Regular systems
      - [x] Charged systems
      - [x] Relays
- [x] Zoom out for the navigation screen
