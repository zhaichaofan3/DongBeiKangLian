> For the complete documentation index, see [llms.txt](https://book.leveldesignbook.com/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://book.leveldesignbook.com/process/combat/encounter.md).

# Encounter

Continuous sequence of open-ended challenges; usually in combat with NPCs

## What is an encounter?

An **encounter** is a *sequence* of *systemic* challenges that support a *variety* of player *tactics.*&#x20;

* ***sequence:*** there can be multiple beats / waves / challenges in a row
* ***systemic:*** using a repeated design language of game elements
* ***variety:*** ideally, not just one specific solution or best strategy
* ***tactics:*** improvised short-term play style / behavior

Many games approach challenge and conflict in a non-violent way in the form of puzzles, dialogues, or mini-games. But in level design culture, "encounter" generally means **a** **single player or PvE (player vs enemy) fight / battle in an action game, shooter, or RPG.**

&#x20;    *(TODO) For more on non-violent challenge design, see Puzzles.*

![combat front diagram for a cover-based military shooter, from "Creating Conflict: Combat Design for AAA Action Games" by Michael Barclay, Sam Howels, Pete Ellis at GDC Europe 2016 (via GdcVault.com)](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-LtX1qT9uxspZe0aRBgD%2F-LtX9S_JeZqVlz5xv8rG%2Fgdc2016_combat_fronts.png?alt=media\&token=0079286c-7ad9-4d5c-a142-fc13d2a47fb5)

## Combat story

Encounters are all about [pacing](/process/preproduction/pacing.md). What happens and when, and how does the encounter react to the player?

You can think of it like a story, but plotted through combat -- a **combat** **story** with beginning, middle, and end:

* ***Beginning, before** the fight:*
  * Are enemies already in battle, or unaware, or en route?
  * Does player choose when to enter the fight?
  * Does player know layout and enemy composition already?
* ***Middle, during** the fight:*
  * Short or long? How many waves or stages?
  * Any scripted events that affect the fight?
  * Any specific routes or strategies to highlight?
* ***Ending, after** the fight:*
  * How will the player know when the battle is over?&#x20;
  * Are there multiple possible outcomes?

Good encounter design helps player understand what's happening, enough to tell a coherent story with clear cause and effect.

{% embed url="<https://youtu.be/YX327SIoSMk>" %}

In the video clip above from documentary Jackie Chan: My Stunts (1999), Jackie Chan directs a fight scene for the film Rush Hour (1998). Chan emphasizes a logic to every actor's movements; so when both he and Chris Tucker's actions play off each other, it signifies a climax in their characters' partnership. Don't be like dumb Brett Ratner and repeatedly ask dumb questions about the gun prop *(Ratner: "But is this your gun?")* because the gun isn't the point! *(Chan: "I don't care.")* The gun is just a tool to help the audience follow the fight.

Encounter design is about using movement, posture, and action to tell a story. However, the telling is more important than the specific story itself.

&#x20;    *For more on general storytelling / rhythm in level design, see* [*Pacing*](/process/preproduction/pacing.md)*.*

### Footholds

For single player action shooters with an emphasis on cover, give the player an opportunity to survey the arena before the fight actually begins. They need time to look around where to fight from, predict where enemies will fight from, and create an escape plan in case the fight turns against them.

If you don't help the player understand the layout, then the player will just fight unimaginatively from the doorway without committing. Your arena design will go unused, and the player will blame the game for offering so little information and incentive to use the arena.&#x20;

How do we entice the player to move into the arena, understand the layout, and then engage enemies? [Andrew Yoder calls this "the door problem of combat design."](https://andrewyoderdesign.blog/2019/08/04/the-door-problem-of-combat-design/)

There are several ways to give the player a chance to find their foothold:

#### METHOD 1: Player ambushes enemies

**Begin the encounter with enemies unaware of the player's presence,** visually exposed from the arena entrance. This allows the player some time to form a plan, and attack when they are ready.

Although the player will likely eliminate the exposed unaware enemies very easily at first, you can just hide or spawn more enemies around the corner, and bring in these reinforcements when the fight begins.

This pattern is common in open world games, or any large landscape dotted with enemy outposts. It fits with the genre's aesthetic to promote freedom of movement.

#### METHOD 2: Enemies ambush player

**Begin the encounter with no enemies,** so the player will wander into the middle of the arena. Once they pass some sort of midfield threshold, trigger enemies and begin the fight. Optionally, place some items and resources in the middle as "bait."&#x20;

Experienced players will likely understand this as a clear trap, and become especially suspicious if the empty room is structured like an arena, or if the bait is offered freely with no apparent cost or danger.

Note that the surprise quickly loses its luster after the player's first attempt. Avoid making enemy ambushes very difficult, because the repeated deaths and trial-and-error gameplay, combined with the player's lack of control over the ambush, may feel grating or unfair.

This pattern is common in classical shooters and horror games. Players more readily accept the contrivance when it is in service of shocking them.

#### METHOD 3: Vista with one-way entrance

**Begin the encounter with unaware yet unattackable enemies**, **observable from a vista** (high vantage point) but separated by an unbreakable window or long distance out of attack range. The player can collect information, form a plan, and begin the fight when they wish.&#x20;

Optionally, force the player to enter the arena via one-way entrance, with a short vertical drop or airlock door closing behind them. This way there is minimal opportunity to surprise the enemy or cheese the fight. Once the player drops down into the arena, they are committed. The closest thing to a "fair fight."

If playtesters don't make use of the vista, try: (a) placing resources at the vista, (b) make smoother flow into the vista, (c) obstruct flow to the arena entrance and obfuscate the entrance at first (eg. with a U-turn typology), or (d) all of the above.

This pattern is common for boss fights or any big climactic set piece encounter. Forcing the player to stop at a purpose-built vista is a strong design gesture that warns the player: don't be thoughtless, be prepared.

## Enemy palette

&#x20;    *For more on using different enemy types, see* [*Enemy design*](/process/combat/enemy.md)*.*

The **enemy palette** is the specific selection of enemy types for an encounter.

**Most of the time, use only a few enemy types at once.** Using too many enemy types is like making a movie with too many characters, or cooking a dish with too many different flavors. It lacks focus and it won't be clear what is happening. Simpler is usually better.

Yes, big messy chaotic battles can be useful and exciting too. However, keep in mind that any experienced player will start sorting through the chaos -- solving for one enemy type in isolation, a small chunk of the battle, while ignoring the rest of the encounter.

<table><thead><tr><th width="186"># of Enemy Types</th><th width="165">Function</th><th>Effect on Player</th></tr></thead><tbody><tr><td>1</td><td>Tutorial, rest</td><td>At first, focus on a specific type in isolation. Afterwards, it's simple / comfortable, a rest.</td></tr><tr><td>2</td><td>"Regular"</td><td>2 enemy types work together in an interesting way, a relationship.</td></tr><tr><td>3</td><td>Complex</td><td>It's hard to deal with 3 relationships at once. And in video games too.</td></tr><tr><td>4</td><td>Brawl</td><td>To keep it readable, make two factions fight each other in a 2v2.</td></tr><tr><td>5+</td><td>Slaughter</td><td>Chaotic free for all. Exciting at first, but player inevitably focuses on a small subset.</td></tr></tbody></table>

<figure><img src="https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MaDzEb98ZiFVBU8oEwG%2F-MaE4n_mIT-wesVi6293%2FLDB_DoomMonsters.jpg?alt=media&amp;token=25ee7edb-9a69-42cc-8270-734008e7c54f" alt=""><figcaption><p>All the monster types in Doom 2. Imagine trying to fight all of these at once: exciting and funny for about 1 second.</p></figcaption></figure>

## Player personas

&#x20;    *For more on classifying and studying players, see* [*Player personas*](/process/blockout/playtesting/persona.md)*.*

A **player persona** is a player's overall long term behavior, motivations, and play style. It's like the player's personality, their "main", their "build", their favorite weapon. It generally doesn't change. Some examples:

* *platformers* might have runners, jumpers, gliders, swimmers
* *shooters* have snipers, shotgunners, "spray and pray", campers
* *open world games* might have explorers, fighters, drivers, collectors
* *strategy games* might have rushers, turtlers, expansionists
* all games have completionists, speedrunners, lore hunters, streamers, newbs, etc.

(TODO: image)

However, with strong prompting, you can change player behavior for the short term, and ideally that influences their overall long term persona. Some examples:

* **Encourage an under-used mechanic:** Players aren't using the gravity gun? Starve the player of ammo for all their other weapons, place physics props everywhere, and use numerous slow moving enemies. (Ravenholm in Half-Life 2)
* **Discourage an over-used mechanic:** Players are climbing too much, and see every traversal encounter as a climbing problem? Add permanent rain to discourage climbing. (Zora's Domain in Breath of the Wild)

**Every project needs to define its own personas.** Then for each encounter, decide which personas / strategies you will support and how.

*EXAMPLE: in the sci-fi RPG Cyberpunk 2077, players can specialize in hacking skills. Therefore, every encounter must support "hackers" with multiple hackable objects in every arena. Some encounters might make use of hackable robot enemies, while others may rely on hackable cameras and turrets. But there's usually always something for a hacker to use.*

## Arena design

todo: break up sock's diagrams and talk about them individually

![different floor design diagrams for encounters by Simon O'Callaghan](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-Mi_e3Q1WnafyLHCzUeL%2F-Mi_eQkf3q1zSrtyWSmo%2FLDB_EncounterDesign_GameplayBuilder_Sock.jpg?alt=media\&token=74baa244-f778-411a-a2fe-388edfcef671)

![different fps encounter elements by Simon O'Callaghan](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-Mi_ehQvISToiopktrSx%2F-Mi_f4wYweviI49FpTN7%2FLDB_EncounterDesign2_GameplayBuilder_Sock.jpg?alt=media\&token=a01121bc-a41a-4bb9-a255-99b645a0b197)

## Example: combat bosses in God of War (2018)

Throughout the third person action game God of War (2018), the player can try to defeat 9 optional bosses called "Valkyries". All the valkyries share similar character art, animations, and move sets, but use these moves in different orders under different conditions, making effective reuse of the same assets while building combat variation.&#x20;

The player unlocks a boss by progressing through the game and unlocking areas, thus implying an order but not forcing the player to fight them in order. The first three were specifically intended as loose tutorials for players to recognize tells and telegraphs, though sometimes the designers exploit this suggested order by mixing up prior patterns to force the player to relearn new timings.

Former Sony combat designer [Jason de Heras detailed the combat design on Twitter](https://twitter.com/jasondeheras/status/1376005093028335617):

> Gunnr has 2 standalone attacks whose role is to encourage parry (yellow FX); their anticipation window/attack speed are similar to allow for consistent parry timing. \[It] encourages the player to parry, but doesn’t require it. All of Gunnr’s attacks can be evaded left / right / back or parried \[except] 1 unparryable (red) attack \[...] performed after a series of initial attacks, so the player has plenty of time to prepare. The unblockable attack has almost zero tracking so the player can evade to the right with minimal precision.\
> \
> Gunnr usually evades away to initiate her standalone attacks. This gives the player an obvious visual tell but also a huge amount of layered anticipation time \~2-3s to prepare and react to the subsequent attack. \[...] Gunnr has virtually no downtime after evading and then attacking which arguably makes the fight easier. This removes one less variable the player has to strategize against. The designers’ kept the intensity high, but actually put the enemy in a vulnerable position.

![animated GIF showing Gunnr's attacks with long anticipation and yellow FX to encourage parry / evade (https://twitter.com/jasondeheras/status/1376005121830658049)](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MWv39_9hxX4YRTiVgLr%2F-MWvGiaQH-kw-MmwTCwm%2FLDB_GodOfWar_JasonDeHeras_ValkyrieTelegraph.gif?alt=media\&token=b1a2db3c-77f9-43e5-a099-f97c14249323)

> Unlike Gunnr, Kara’s has 2 attacks that strongly forces the player to evade/block. Since these attacks have similar startup poses, the player must identify the red FX to choose evade or block. \[...] Kara shares Gunnr’s Dash, but \[if] the player mistimes a parry/plays defensive, they’ll be vulnerable to nearby Draugrs, \[adding tension.] Kara’s Wing swipe is a standalone attack that gives her another mixup when evading away and resetting the fight. \[...] The range that Kara’s Wing swipe is initiated causes it to miss on purpose. This serves to lull the player to sleep and bait them into attacking if they aren’t paying attention or become greedy. The small burst of forward translation at the end makes this attack deceptive.\
> \
> Geirdriful shares some moves from both Gunnr and Kara, but adds 2 unique attacks for a formidable/well-rounded moveset \[...] Her lone closing attack is unparryable and gives her a high risk / high reward attack compared to Gunn/Kara’s dashing attack that can be parried. \[...] Geirdriful’s wing swipe combo is the same as Gunnr’s, but used as a standalone attack (as opposed to Gunnr’s counter attack), another mixup to make the fight less predictable. Geirdriful shares the Gunnr wing thrust unblockable but as a standalone attack with increased translation/speed. If the player fought Gunnr first, then the removal of the wing swipes before the wing thrust unblockable will force them to relearn the cadence of this attack.

> [-- Jason de Heras (@JasonDeHeras)](https://twitter.com/jasondeheras/status/1376005093028335617)

![spreadsheet breakdown showing the moveset matrix for valkyrie bosses in God of War (2018), by Jason de Heras (via Twitter)](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MWv39_9hxX4YRTiVgLr%2F-MWvAiVCuI_Tvzecv6YL%2FLDB_Encounter_Matrix_GodOfWarValkyries_JasonDeHeras.png?alt=media\&token=70e31f40-2846-46d2-a2ef-cc38d43e09c4)

## Example: stealth boss in Dishonored

In the stealth first person game Dishonored, mission 7 "The Flooded District", the player faces a boss NPC. They can sneak past the boss undetected or attempt to fight the boss. Arkane Studios level designer Dana Nightingale commented on her design documents for the encounter:

> Normally I hated boss fights so it was kind of excited to design one to avoid all of the stuff I didn't like about them. \[...] Designing that encounter with Daud is still one of the things I'm the most proud of. I love watching people play though it.\
> \
> Big blocks of text is nice for a "dev commentary", but it doesn't work well if you have a hundred docs to keep up to date or you're the person who has to read them. Simpler, but conveying more, is always the goal. That's really hard.
>
> [-- Dana Nightingale (@DanaENight)](https://twitter.com/DanaENight/status/1371022031886635011)

Nightingale's original design documents (below) outline clear design goals for the encounter to justify the unusually closed-off arena layout. Additionally, because Dishonored is an "immersive sim" RPG game with many different player abilities, she uses a flowchart format to imagine different player strategies and how the encounter scripting should handle edge cases gracefully. However, as she points out, it is quite a lot to read; writing too much detail into a design brief does not necessarily improve planning or design.

![design documents for boss encounter in Dishonored, by Dana Nightingale (https://twitter.com/DanaENight/status/1370643659792744449)](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MVeiD_JUQ3mH55QvMSA%2F-MVekqo2wQ315ngopCaM%2FLDB_Encounter_Daud_Dishonored_DanaNightingale.png?alt=media\&token=80c095cc-2557-4ab8-aae3-9c6abe11f06d)

{% embed url="<https://www.youtube.com/watch?v=yE3yO4zMMgg>" %}
example stealth no-alert "ghost" playthrough of the boss encounter; does it accomplish Nightingale's goals? how does it differ from the initial design pitch?
{% endembed %}

## Further reading

* [Game AI Pro](https://www.gameaipro.com/) is the main game industry publication about game AI programming and techniques -- professionally written and edited -- and **free to read.** If you're not a programmer, some of it will be difficult to understand, but try to push through it anyway. If you can understand 50% of it, it'll still help you a lot. A valuable community resource for combat designers.
* [**"Basics of Classic FPS Combat Encounter Design"**](https://www.youtube.com/watch?v=oB4JMy9OjKk) (47 min video) by Andrew Yoder
* ["Encounter Design Topics: RNG in Encounter Design" ](https://www.nathanielchapman.games/pedrothedagger/encounter-design-topics-rng-in-encounter-design)by Nathaniel Chapman is about when and how to apply randomness to combat, especially in a multiplayer or MMO context.
* ["Quake Mapping Tips: Difficulty Balance in Level Design" (8 min) video by Michael Markie](https://www.youtube.com/watch?v=s9bleQCTdTo) workshops Quake 1 combat encounters at different difficulty tiers, while offering general design commentary and advice. Markie uses different monster behavior and weapon / ammo placement to encourage different player movement within the same room layout. A great primer even if you're not mapping for Quake.
