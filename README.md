# Trek
Star Trek bridge simulator

                                   MM
                                  M MM
                                 M   M?
                                M     M
                               ~O     MM
                            IMMM       MMMZ
                         ~MMM M    M    M NMM$
                       :MM    D    M    MM   MMO
                      MM     M     M     M     MM
                     MM      =     MO    MM     IM:
                    MI      M      MM     M       M7
                   MO      M      NMM     =M       M
                  MM       M      MMM      M       7M
                 ,M       M    OMMMMMMMI    M       M+
                 MM       M      MMMMM      M$      MM
                 MO      M       MM MM       M      ?M
                 M,      M       Z    ,      MM     ,M
                 MN     M                     M     8M
                 MM     M                     M     MM
                 :M    M            MMM ,MI    M    M:
                  MM   M          MM      MN   M   DM
                   M= MO        MM         MM  MD ,M
                   ~M M       MM            MM  M MZ
                    +MM     +MD              MM MMZ
                     MM    MM                 M7MM
                     M   NMM                 MMMMM
                    ,M  MMMMM             MMM, MMM
                    MM~MM    MMMMMMMMMMMMM      MM
                    MMMN                         M
                    MM
                    M



# Installing
`npm install`

# Running Tests
`npm test`

# Running the Server
`npm start`

The output from the startup script will give you the Prefix codes needed for crews to loging

# Game Design
The idea behind Trek was that we wanted a bridge simulator that could work on OSx (or any modern web browser). 

Each laptop signed onto a ship can assume the role of any of the standard bridge consoles, the idea being that game play follows along with the flow of events as seen on the bridge of the Enterprise on air.

For technology, plot, cannon, and design reasons, the game is set onboard the Enterprise A, between Star Trek V and Star Trek VI.

## Mainviewer
The mainviewer is meant to be displayed on a big central screen, like a projector or a TV. The captain's computer is the best one to hook up here. Many of the other stations are capable on displaying their view "on screen", which will map the display component of their screen onto the main viewer.

### Captain's Log
The Captain's Log is displayed on the main view screen as entries occur. These log entries will offer insight into how a mission is progressing, and what remains to be done.

## Viewscreen
This is the screen that can select outboard holoimaging and send them to the main viewer. An example use of this console would be when the Captain orders "on screen" when approaching a craft.

All vesels in visual range will be displayed on the list here, as well as the standard forward and aft views.

## Ops
This terminal takes the place of the operations officer on the bridge, who is responsible for personnel and logistics. Transporter duties are also handled here.

### Crew
Move crew around the ship. This is useful for dispatching security teams in the event of an intruder alert, or for spreading repair crews around the ship in preparation for repair duties.

### Repair
Assign repair crews to damaged systems. Most systems experience damage during regular use, and so there is constantly a list of systems requiring maintenance. Each system will list it's material requirements, estimated time to repair, and estimated time to operability (if offline). Most systems will function even if they're below 100% status, though potentially in a degraded fashion.

### Cargo
Inspect the current cargo load of the ship, and see which materials are available for repairs and bartering.

### Transporter
Move cargo and personnel between ships and cargo bays, manage boarding parties and away teams.

In order to transport to another ship, the science officer will have to have completed a detailed scan of the vessel, otherwise the targetting computers won't know where to put your team.

## Conn
The Conn position covers navigational and helm duties. System maps and navigational controls are handled by this position. Set course and speed from here.

### Navigation

### Helm

### Maps

## Science
Scanners pipe their data here. Your ship is equiped with a wide array of sensors, and their output comes here. You can look into where subspace signals, tachyons, beta particles, warp signatures, and others are all coming from.

### Long and Short Range Scanning
Starships come equiped with a wide variety of sensors. Standard sensor payloads detect all sort of phenomena in a 360 degree cirlce up to a limited range. Long-range sensors use subspace to extend the range of sensors beyond the limits of light speed, (however, long-range sensors are only targetted forward of a ship in most conditions, as their primary purpose is to assist in faster-than-light travel).

Sensor grids will complete their scan at different times depending on the range and resolution selected. For instance, a scan of the surrounding 0.1AU with low resolution (by quadrant, say) will complete in a matter of seconds, while a scan out to 8AU with a 64-degree resolution will require minutes.

Part of the duties of the science officer is to configure sensors in a manner consistent with the needs of the current mission profile.

### Detailed Scanning
When passive high-resolution sensors identify an object, it becomes possible to get a more detailed scan of the object in question, using a full-suite of different sensor grids focused tightly on a target.

Detailed scanning can reveal information about a vessel, shield status, hull integrity, life signs, cargo, energy signatures, and a host of other useful information.

Additionally, a detailed scan is required before transporting or advanced weapons targetting can occur.

Aboard starships, it is common procedure to perform a detailed scan of all objects within range.

### Environmental Scanning
Starships also come equiped with a set of sensors designed to measure the local environment. These sensors measure important factors for operational safety including:

#### Ambiant Radiation
An amalgam measure of ambiant radiation levels, critical for ship operational safety. Shields may be required if radiation levels rise above an acceptable level.

#### Partical Density
There is an upper limit to how much work the navigational deflector can do while move objects out of the path of a starship travelling at high speeds, limiting the upper safe velocity of a ship depending on how densely particals are packed into the local region of space.

A ship will thus be speed limited if navigational computers determine that the local partical density is too high to safely travel through.

#### Subspace Distortion
Warp travel is made possible via subspace, is may be impossible if it is overly distorted in the local area. Additionally, subspace communication and long-distance sensors will also be affected.

#### Spatial Distortion
Any local bending of spacetime may adversely affect any number of systems.

### Internal Scanning
The science officer is also tasked with monitoring internal sensors, for radiological alarms, anomolies, and other environmental phenomena.

## Engineering
Power distribution comes from this pannel. Balancing the power requirements of all of a Ship's systems in real time is tricky work, and takes an engineer to run things.

Many system's can be finely tuned from this panel as well. (EG If you're hiding from an enemy, you may want to tell the engineer to turn off the subspace tranceiver.)

### Power
All of a ships systems are powered by electro-plasma. Typically, a ship will have a main power reactor providing the large amounts of power required to run systems like warp drive, navigational deflectors, structural integrity, and in some cases, weaponry.

In addition to the main core, starships typically contain fusion reactors to power systems such as the impulse drives. Fusion reactors typically operate an order of magnitude lower than a main reactor. Emergency power may also be supplied by battery backups in the event of complete power failure.

In order to route the power from these systems to a desired end point, starships use EPS conduits to act like breaker boxes and move the power around. Much like real fuses, each EPS relay can only pass so much power before it blows, fusing it's distribution ratios in their last configuration. The benefit of EPS conduits is that they can attached to impulse reactors of emergency power if the need should arise, to power life support and communications in the event of a ship-wide power failure. (Systems not attached to an EPS relay are offline should the main reactor go down.)

All systems on a starship have a power profile and operating range. Below a minimum threshold, a system is not able to operate, and above a certain maximum, a system will begin to incurr damage over the course of it's operation. Striking the balance required for any giving scenario is the duty of the engineering officer.

Certain systems onboard a ship accumulate charges to function, such a phasers, shields, warp coils, and structural integrity fields. Increasing the power allocated to these systems can speed up the recharge time. Additionally, the engineer is the one capable of activating these system's charging components of leaving them inactive, though online.

### System Activity
Engineers may take systems offline to disable their behaviour.

## Tactical / Combat
The weapons officer position. This view lets you select weapons targets and fire phasers and torpedoes. Shield operations are also controlled from this station.

Tactical officers also control ship's communications.

### Notes on Combat
In spite of what one might have expected, phasers are stronger than torpedoes. Torpedoes effectively have splash damage. A phaser shot is focused on one section and deck, while a torpedo blast will effect the entire section of the ship. Torpedoes also have a significantly longer range. Knowing where to target you phasers on an enemy ship can significantly shift the outcome of a battle.

It is impractical to manuver for combat at warp or even high-impulse speeds; generally, defensive and attack tactics require moving in an out of phaser range while orienting the ship to distribute damage accross the shield and face the enemy with the most offensive systems (this is generally forward facing for most ship configurations).

Ships have many levels of defenses, starting with shields, then the ship's structural integrity field, and finally the hull itself. As a hull takes direct damage, systems existing behind that section of hull will also experience damage. Damaged systems will perform less effectively than fully functional ones, and will not work at all when damaged beyond a certain point.

Battle tactics generally revolve around allowing your shield and integrity fields enough time to charge, while trying to prevent your enemy from recharging their systems while your weapons systems charge.

## Alerts
Star ships have alert levels to indicate a system of readiness depending on the circumtances.

### Red Alert
Red Alert indicates combat readiness is required. When indicated, the ship will begin charging phaser and shield systems, as well as increasing power to maximum operational levels for phasers, shields, and structural integrity fields.

### Yellow Alert
Yellow Alert indicates the potential for crisis, and automatically powers up shields and integrity fields.

### Blue Alert
A Blue Alert indicates an environmental or operational hazard. In the event of Main Power failure, docking conditions, or radiation hazards, a blue alert indicates hightened caution and operational readiness.

