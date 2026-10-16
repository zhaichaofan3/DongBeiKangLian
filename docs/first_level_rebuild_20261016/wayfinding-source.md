> For the complete documentation index, see [llms.txt](https://book.leveldesignbook.com/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://book.leveldesignbook.com/process/blockout/wayfinding.md).

# Wayfinding

player navigation, how to "guide" the player through a level

## What is wayfinding?

**Wayfinding** is when a player finds where they are in the level **(orientation)** and/or finds a route toward their destination **(navigation)**.

Most level designers aim for players to wayfind their way through the game world "naturally" in an "immersive" mood with minimal disorientation or frustration, while coinciding with the designer's intended [critical path](/process/layout/flow.md#critical-path)(s). This style balances naturalism and plausibility with subtlety. But more often, the goal is the performance of false subtlety -- helpful details that seem subtle (to someone, somewhere?) but are actually very obvious to most players.

(video embed?)

## Wayfinding vs. guidance

Decades of industry level designer orthodoxy have claimed that the goal of level design is to manipulate / trick the player into "feeling smart" while "subconsciously" following the critical path... and to this, we say: *no, stop! Can we quit thinking like this?*

Deception is not a productive way to relate to players, and constitutes a false theory of mind for how players actually play:

Players often avoid the perceived [critical path ](/process/layout/flow.md#critical-path)on purpose, to explore side areas and progress through the game at their own pace. In open world and multiplayer games, players crisscross the same space repeatedly and non-linearly, without one single static unchanging goal to always guide them towards. And then sometimes players just want to ignore gameplay and relax, hangout in a virtual space, spend time with friends, or even break the game and upload silly videos of goofs.

These are all valid ways to play. Let's move away from the weird (and creepy) prescriptive designer fantasy about secretly mind-controlling players into playing the way we want.

(image)

Instead, think of it this way: **we are co-creating the game experience with players, and our goal is to provide tools and information to help them use our level.**&#x20;

Sometimes it's fun to stay on the critical path and sometimes it's fun to ignore it. Sometimes it's good to have a lot of information and sometimes it's better to have little information. Sometimes a narrow set of solutions can feel frustrating or artificial, and sometimes limiting options might result in a better experience.

We argue that player guidance is a flawed way to understand how people use levels and virtual spaces. "Guiding the player" fails to account for how players structure their own play. Meanwhile, wayfinding is standard terminology in architecture and usability design fields, and emphasizes the player's agency (way-FINDING) and active co-authoring of [flow](/process/layout/flow.md).

## Wayfinding theory

There's been a lot of research across architecture, environmental psychology, behavioral geography, and design, into how people navigate spaces. While humans obviously traverse virtual spaces differently from real world spaces, we hope / imagine the mental process is similar.

### Psychology

People form **mental maps** to conceptually represent a space.

* Paths - the roads used to move around
* Edges - roads which define the boundaries and breaks in continuity
* Districts - areas which share similar characteristics
* Nodes - strong intersection points of roads like squares or junctions
* Landmarks - easily identifiable entities which are used for point-referencing, usually physical objects

short term vs long term memory

**Dead reckoning / path integration** is a method for guessing and tracking where you are when no landmarks are available. You can estimate your current position by (1) orienting your starting position, and (2) extrapolating along your movement direction, speed, and travel time. Sailors and flight navigators heavily relied on dead reckoning calculations before radio and satellite, and even your phone regularly uses motion sensors and dead reckoning to estimate its location -- but even without math or technology, humans and animals regularly use a loose intuitive sense of dead reckoning.

Kevin Lynch's Image of the City&#x20;

### Strategies

* Track following: to rely on directional signs on the road
* Route following: to follow the rules given, such as a pre-planned route before the journey started
* Educated seeking: to use past experiences to draw logical conclusions on where to go
* Inference: to apply norms and expectations of where things are
* Screening: to systematically search the area for a helpful clue, though there may well not be any
* Aiming: to find a perceptible target and move in that specific direction
* Map reading: to use portable or stationary maps and help the user locate themselves
* Compassing: to navigate oneself with a figurative compass, such as the location of the sun or a landmark
* Social navigation: to follow the crowd and learn from other people’s actions

### Signage theory

source <https://fabrikbrands.com/the-wonders-of-wayfinding-design/>

* Informational: These provide useful information on the place where the users are, such as free wifi, opening hours, etc.
* Directional: As the name indicates, these direct users with arrows saying which way to go for whichever purpose. These most often at junctions when the user must make a decision about the route.
* Identification: To help users recognize where they currently are, identification signs can be placed at the entrances of buildings, parks, etc. They symbolize the arrival to a destination.
* Regulatory: These let people know what they can and cannot do in a given area and are most frequently phrased negatively with the aim of creating a safe environment. Examples include “no smoking” or “restricted area”.

For example, when players exit the introductory train station in Half-Life 2, they witness a dramatic city view with deep composition that highlights The Citadel tower at the center of the city. To get the player to notice this significant landmark, Valve level designers pointed the door frame outwards into the city square, accompanied by a flock of birds suddenly flying upwards.&#x20;

This example highlights three guidelines for scene composition:

1. Players don’t look upwards unless something draws their eye.
2. Players look in the direction they are moving.
3. Players focus on contrast (in color, shape, lighting, and movement.)

## Wayfinding aids

Below is a table of various methods to convey navigation information to the player, starting from very subtle methods at the top, and descending to very obvious guidance methods toward the bottom. When possible, it's considered good practice to start at the top, and gradually incorporate less subtle methods in response to [playtesting](/process/blockout/playtesting.md).

A **wayfinding aid** is anything that helps the player navigate where to go and how to understand the space.

* Positive reinforcement, attract the player to approach.
* Negative reinforcement, know *where you can't go* to understand *where you can go.*

We organized common wayfinding aids below by "% certainty" -- a non-scientific estimate of the proportion of players will likely perceive and use the aid.

### Subtle (1-20% certainty)

Subtle wayfinding aids are best when overlaid as extra detail / polish with another more reliable wayfinding aid. Or alternatively, use solely these methods to make an area feel more unique or special for a small proportion of players (e.g. a very secret room). A vague nudge.

<table data-header-hidden><thead><tr><th align="right">Method </th><th width="336.94656488549623">Example</th><th>%</th></tr></thead><tbody><tr><td align="right">Method </td><td>Example</td><td>%</td></tr><tr><td align="right"><strong>allegory</strong></td><td>recreation or homage to an existing place, game, or level <em>(e.g. the intro to The Beginner's Guide is an homage to de_dust)</em></td><td>1%</td></tr><tr><td align="right"><a href="/process/env-art/storytelling.md"><strong>worldbuilding</strong></a><strong>, architectural patterns</strong></td><td>e.g. castles have dungeons at the bottom, and rich powerful people live deep in the middle / toward the back / at top... modern houses often have bedrooms with nearby en-suite bathrooms</td><td>4%</td></tr><tr><td align="right"><strong>following NPCs</strong></td><td>destination implied by following humanoid NPCs or ambient wildlife (e.g. birds in Half-Life 2, mote particles in Proteus, foxes in Skyrim)</td><td>7%</td></tr><tr><td align="right"><strong>unusual detail</strong></td><td>subtle crack in ground or wall (Zelda), conspicuous use of game elements with unclear purpose (e.g. explosive barrel with nothing to affect)</td><td>10%</td></tr><tr><td align="right"><strong>sound design</strong></td><td>ambient sound (e.g. hearing the sound of flowing water in the distance), dynamic use of music (e.g. hearing tense music upon entering a dangerous area)</td><td>15%</td></tr><tr><td align="right"> <a href="/process/layout/typology.md"><strong>typology</strong></a></td><td>e.g. shooter levels with large rooms full of cover but no enemies yet, or when a room feels structured like a boss battle arena</td><td>20%</td></tr></tbody></table>

### Coarse (35-60% certainty)

Coarse wayfinding methods rely on the player's prior knowledge or familiarity with common level design patterns. Common in "cinematic" or "immersive" games with an exploration fantasy. Use these methods to supplement a critical path, or to mark optional resources or secondary routes. A suggestion.

<table data-header-hidden><thead><tr><th align="right">Method </th><th width="338.5688729874776">Example</th><th>%</th></tr></thead><tbody><tr><td align="right">Method </td><td>Example</td><td>%</td></tr><tr><td align="right"><a href="/process/blockout/massing/composition.md"><strong>composition</strong></a><strong>, sightlines</strong></td><td>dense clusters of details to inspect up close, sparse skybox geometry to avoid, tall landmark in distance with wide sightline, window framing a specific view</td><td>35%</td></tr><tr><td align="right"><a href="/process/lighting.md"><strong>lighting</strong></a><strong>, color</strong></td><td>path implied by light placement (Left 4 Dead), visibly lit entrances and exits, color contrasts (e.g. bright blue door in a dark orange landscape)</td><td>40%</td></tr><tr><td align="right"><strong>in-world signage</strong></td><td>in-world signs and placards; <em>easily mistaken for irrelevant set dressing</em></td><td>40%</td></tr><tr><td align="right"><strong>gamer tropes</strong></td><td>e.g. waterfalls hide treasure, or climb a tower for a reward</td><td>45%</td></tr><tr><td align="right"><a href="/process/env-art/storytelling.md"><strong>environmental storytelling</strong></a></td><td>trail of blood on floor (Doom), trail of destruction (BioShock)... clear authored path formed by a character or event</td><td>50%</td></tr><tr><td align="right"><strong>ground composition</strong></td><td>planks that extend off the ledge (Uncharted), train tracks (Team Fortress 2), scratchy ledge markers (Tomb Raider)... clear gameplay function</td><td>55%</td></tr><tr><td align="right"><strong>repetition</strong></td><td>repeated use of prior elements in a similar situation, directly evoking the player's memory and pattern recognition</td><td>60%</td></tr></tbody></table>

### Situational (70-93% certainty)

Situational wayfinding methods will feel like the level designer strongly urging the player to follow a certain path or direction, but not forcing the player to do so. These methods include temporary camera control, situational UI pop-ups, direct threats and direct benefits for player progress. A heavy push.

<table data-header-hidden><thead><tr><th align="right">Method </th><th width="347.3333333333333">Example</th><th>%</th></tr></thead><tbody><tr><td align="right">Method </td><td>Example</td><td>%</td></tr><tr><td align="right"><a href="/process/scripting.md"><strong>scripted sequence</strong></a></td><td>friendly NPC directly leading the player (Half-Life 2), voiceover audio with directions, sudden explosion, etc.</td><td>70%</td></tr><tr><td align="right"><strong>resources, items, breadcrumb trails</strong></td><td>lines of collectible items or powerups (Donkey Kong Country), collectibles or powerups visible in the distance ("weenies"), a treasure chest, etc.</td><td>80%</td></tr><tr><td align="right"><strong>cutscene</strong></td><td>scripted cutaway camera shot that shows a newly unlocked door (Zelda)... assuming player is actually watching, and not just checking their phone or skipping through the cutscene</td><td>90%</td></tr><tr><td align="right"><strong>dynamic world UI / HUD</strong></td><td>glowing GPS route (Grand Theft Auto 5), dynamic road signs (Mafia 3), pings (Apex Legends), alternate vision ("detective mode" in Batman Arkham games)</td><td>92%</td></tr><tr><td align="right"><strong>active threats</strong></td><td>enemy NPCs actively attacking the player, aggro'd NPCs with audio barks that draw dangerous attention to themselves</td><td>93%</td></tr></tbody></table>

Again, these methods cannot guarantee a specific behavior from the player.

For example, imagine a room with two exits, Exit #1 and Exit #2. There are many enemy NPCs in front of Exit #2. Will the player run toward these enemies to engage the enemies, and thus gravitate toward Exit #2 first? Or will the danger and threat of these enemies push the player away, towards Exit #1 instead? What if Exit #1 resembles a locked door, and the player has zero keys?

The intended "message" and resulting behavior will depend a lot on the player's current health and resources, prior encounters and patterns, overall level pacing, etc.&#x20;

But here's what 93% of players will likely understand: those enemy NPCs were guarding Exit #2, and Exit #2 might be part of a critical path, and at some point the player may want to inspect Exit #2 more closely.

### Direct (95-98% certainty)

As close as you can get to telling the player "you can't go here." Static, always-on, permanent game elements that the player can trust unambiguously as the voice of the game designer. A thick solid opaque unbreakable wall is a great way to urge the player "don't go through this wall", because they literally cannot... unless the player is a speedrunner, or if the player is wallhugging to try to find secrets, etc.

<table data-header-hidden><thead><tr><th align="right">Method </th><th width="338.3333333333333">Example</th><th>%</th></tr></thead><tbody><tr><td align="right">Method </td><td>Example</td><td>%</td></tr><tr><td align="right"><strong>static deep wide barriers</strong></td><td>deep pits, canyons, lava, rivers, etc. that physically block movement without blocking line of sight, cannot be destroyed or bridged</td><td>95%</td></tr><tr><td align="right"><strong>always-on global UI / HUD</strong></td><td>objective marker (Call of Duty), objective arrow (BioShock), on-screen objective text, minimap with icons... <em>sometimes it's OK to "give up"</em></td><td>97%</td></tr><tr><td align="right"><strong>static hard barriers</strong></td><td>walls, fences, fortifications that physically block movement and block line of sight, cannot be destroyed</td><td>98%</td></tr></tbody></table>

## Advice for wayfinding

Note that some of these navigation aids are impossible to avoid, and some are even a bit beyond your control. That is because **everything in the game is a wayfinding aid**, and everything plays a role in guiding the player around the space. A wall makes a player to go around it; stairs promise another space above or below. Everything is information that the player takes in, all to varying degrees based on their mood, and none of it is foolproof. Like any other piece of information, these navigation aids can all be misunderstood, ignored, or overlooked.

We discuss some of these wayfinding aids in more detail below:

### Ground composition

TODO: grab a slide from David Shaver's talk

### Signage

CS:GO ironic bomb site signs... some graffiti is very subtle and not very effective probably

### **Breadcrumbing**

highly dependent on flow?... maybe put this in the flow or encounter section imo

## To review

**Wayfinding** is the practice of providing navigation aids for understanding the level [layout](/process/layout.md). We urge level designers to reject notions of "guiding the player" -- instead, we argue that players play games in a variety of ways, and thus guide themselves. Strong wayfinding design help players construct mental maps to navigate and use a level more effectively.

Wayfinding signals a lot to players:

* Show the player "what they're supposed to do", let them follow an intended authorial [critical path](/process/layout/flow.md#critical-path) to progress
* Build trust with the player, promise the game world has been designed and remains readable with consistent navigation patterns
* Demonstrate conventional craftsmanship and production value

## Against wayfinding

But what if the player doesn't want to follow "what they're supposed to do"? Or what if you don't want to build trust with the player, or you don't care about conventional craft and best practices?

Heavy use of landmarking, signposting, and breadcrumbing, will make a level feel like [Disneyland](/studies/irl/disneyland.md). In many cases, this sense of controlled fantasy / "architecture of reassurance" can be desirable. The fake forest and fake wilderness of a theme park is common and appropriate for the typical commercial action-adventure themed game.

However, if a true sense of wilderness is desired, then the design may require a sort of anti-wayfinding. Ideally a natural and wild space shouldn't feel designed at all. If the idea of a totally unspoiled place is crucial to the project, then signposting and breadcrumbing will feel artificial and compromise the sense of place and authenticity.&#x20;

Does your personal residence or home have landmarks and signage? Of course not -- and the privacy of personal navigation and memory is what makes that home belong to you. In contrast, [Disneyland](/studies/irl/disneyland.md) is unlivable.

![no one lives in Disneyland, and if they did, they would hate it; vintage map of Disneyland in 1963 from National Geographic magazine](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MauGVrCbUVtVRC_MKWx%2F-MauHAn5iIsvLEp4sCKH%2FLDB_Disneyland1963_Map.jpg?alt=media\&token=5b210d75-120d-4383-9228-1a2513ec84da)

### Route-finding as mechanic

["\[fr0g\] clan official server 24/7 zk map (for stranger)"](https://www.glorioustrainwrecks.com/node/11388) by Marek Kapolk is a first person anti-climbing game about carefully descending downwards. The level design often feels haphazard and unreadable, with heavily fragmented [circulation](/process/layout/flow.md#circulation) and very little clear [flow](/process/layout/flow.md) anywhere. The result is that the player feels like they are actively creating their own route and path, and less of an authored critical path. [Bennett Foddy writes](https://thatsnot.fun/zk-map-for-stranger/) about its focus on route-finding and unique anti-wayfinding level design:

> You do a lot of downward climbing in *zk map,* but the core activity is route-finding. You look across a haphazard pile of shapes, and your eyes trace possible ways down, imagining the lines of sight and obstructions along each meandering path. Route-finding is one part forward planning and two parts 'dead reckoning': making a choice and then figuring out how to get yourself one step out of the mess you just made. There is something magical about route-finding in a videogame, since videogame worlds are untrammeled, immaculate spaces. Every unguided turn you take is yours and yours alone.

!["zk map" by Marek Kapolk, screenshot by Bennett Foddy (from https://thatsnot.fun/zk-map-for-stranger/)](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MksVcGNo0ENTbWe3Mkb%2F-Mksd0ZaRUGfSGkz_HRr%2FLDB_zkmap1_MarekKapolka.jpg?alt=media\&token=91137f06-6569-4279-a791-14d8069c27bd)

> The thing about making a game involving route-finding is you can't really get there by designing great routes. No matter how good your level design skills are, if the player is following a path you laid out for them, they aren't really route-finding at all. The player becomes too aware of your intentions, and their own autonomy becomes subsumed in them. As mkapolk explains:
>
> > *My process for making the levels was to scatter geometry more or less randomly and then try to traverse it. Sometimes when I was going down a map if I thought that an area shouldn't be a dead end I'd add some more stuff to it, but that's about as far as it went.*&#x20;
>
> You can construct a level that players can route-find through, but you can't design it... or to put it more precisely, you can't crack out the Good Game Design if you want players to experience route-finding. To pass through a well-designed level is a hike, not an expedition.
>
> \-- Bennett Foddy, ["that's not fun: zk map for stranger"](https://thatsnot.fun/zk-map-for-stranger/)

!["zk map" by Marek Kapolk, screenshot by Bennett Foddy (from https://thatsnot.fun/zk-map-for-stranger/)](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MksVcGNo0ENTbWe3Mkb%2F-MksfkOopzijnesBORHl%2FLDB_zkmap3_MarekKapolka.jpg?alt=media\&token=877a6141-a8fa-404a-ae67-1fca01d71f78)

## Now what?

* [**Playtesting**](/process/blockout/playtesting.md) is crucial. Like a lot of psychology and design theory, most of this is wet bullshit until you verify and validate the design in a playtest.

### Further reading

* [**Mapstalgia**](https://mapstalgia.tumblr.com) is a collection of maps and levels from video games, drawn from memory by players. The resulting drawings are often beautiful and wildly inaccurate. It's the closest thing we have to a player's mental map, and very interesting for imagining how players parse level design.
