> For the complete documentation index, see [llms.txt](https://book.leveldesignbook.com/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://book.leveldesignbook.com/process/combat.md).

# Combat

designing physical conflict between player(s) and/or NPCs

## **What is combat design?**

**Combat design** is about making game systems for physical conflict between player(s) and often AI-controlled enemies too.&#x20;

In level design, we generally assume this is combat for a first person shooter or other real-time 3D action game. This book will also make that assumption.

Note that competitive **player vs. player (PvP)** functions very differently from single player / cooperative **player vs. enemy (PvE)** combat. PvP usually implies a fair chance to win for all combatants. In contrast, PvE provides delayed but guaranteed victory. These are two very different promises to make to players, and so the level design is different too.

&#x20;    *If in fact, you do not choose violence, then skip ahead to learning about* [*Layout*](/process/layout.md)*.*

![screenshot of Doom (1993), an early first person shooter that popularized many combat design patterns today](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MaDzEb98ZiFVBU8oEwG%2F-MaE1sNLV9gjsjW2nUtm%2FLDB_Doom1993_Gameplay.jpg?alt=media\&token=ac242d30-a8ad-455a-bf99-ac506977fffe)

## Combat systems

When making a combat game, you have two options:

* Mod an existing combat game.
* Build your own combat gameplay from scratch.

You cannot make good combat levels without good combat systems. But developing this core combat toolkit requires a lot of code, art, animation, audio, and tuning.&#x20;

This is a complex topic that is outside the scope of a level design book. Asking "how do I make good combat?" is like asking "how do I make a good game?" It's a big question.

This is why we strongly suggest modding: that way, you can reuse a game's already-proven core combat systems without having to build your own.

&#x20;    *For a list of recommended combat games to mod and study, see* [*Tools*](/appendix/tools.md)*.*

<figure><img src="https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-LtVT8pJjInrrHVCovzy%2Fuploads%2FM7vrEtuIuX99gobPUa1d%2FLDB_GDC2012_Skylanders_CombatFarEnemy.png?alt=media&amp;token=852b3154-5f00-4005-8169-9dfa97c1a0c2" alt=""><figcaption><p>slide from the talk <a href="https://www.gdcvault.com/play/1015838/Reaching-Into-the-Toy-Chest">"Reaching Into the Toy-Chest: A Look into Skylanders Spyro's Adventure's Design"</a> by Mike Stout, from GDC 2012</p></figcaption></figure>

That said, even if you do mod an existing combat game, you still have to be able to theorize how it works. All single player and multiplayer combat games have some form of these core elements:

* **Combat mechanics**
* **Weapon design**
* **Economy**

In a big commercial studio with specialized development roles, **none of those core combat elements would be the level designer's responsibility**. However, a level designer cannot make levels without understanding them.

<figure><img src="https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-LtX1qT9uxspZe0aRBgD%2F-LtX9S_JeZqVlz5xv8rG%2Fgdc2016_combat_fronts.png?alt=media&amp;token=0079286c-7ad9-4d5c-a142-fc13d2a47fb5" alt=""><figcaption><p>image from <a href="https://www.gdcvault.com/play/1023791/Creating-Conflict-Combat-Design-for">"Creating Conflict: Combat Design for AAA Action Games"</a> by Michael Barclay et al, from GDC 2016</p></figcaption></figure>

### Combat mechanics

**Combat mechanics** are the player's repeated actions / skills / weapons used to fight enemies. Some common combat mechanics:

* **Move** away from danger, control **territory**
* **Aim** at specific enemy types / weak points
* **Timing** an attack for a **tell / telegraph** (opportunity)
* Chain attacks into **combos**, combine actions or weapons
* **Block** an enemy attack; **parry** / **counter** / **evade** at the right time
* Use **traps** like explosive barrels, water, lava, cliffs, etc

![animated GIF of early test map + combat prototype from 2014 for God of War (2018) by Sony Santa Monica](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MCcQT9RgVLd-yLRamEE%2F-MCcQmBwTl4MKjF33SYl%2FGodOfWar2014_CombatPrototype.gif?alt=media\&token=e4c053d2-c9b7-4bbb-92e7-ec21bee8bc54)

### Weapon design

Many games provide the player with multiple weapons to use. **Weapon design** is about conceptualizing, implementing, and balancing this arsenal. Some aspects to consider:

* **Weapon feel and fantasy** (e.g. big slow gun vs. sneaky knife vs. loud chainsaw)
* **Stats** like varied damage, range, rate of fire, ammo supply
  * For guns: varied spread, recoil, sights, penetration, magazine size, reload speed
* **Situational awareness** to pick the most appropriate / effective weapon

![Weapons from Doom (1993) that inspired many shooters after it: (1) Chainsaw, (2) Pistol, (3) Shotgun, (4) Super Shotgun, (5) Chaingun, (6) Rocket Launcher, (7) Plasma Gun, (8) BFG](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MWwF44URjg88NMz-OF3%2F-MWwJUl5WpzfUVf-IlEy%2Fdoom-2-weapons.png?alt=media\&token=9a0f58cb-87c0-483d-a81e-de1581ac70c7)

### Economy

**Economy** is a general game design term for the overall system of costs / benefits / rewards that the player must consider throughout the game. The player's access to resources affects which mechanics and weapons they use and when:

* **Weapon economy:** ammo, time (DPS), arsenal / loadout
  * *example: the player has 1 rocket left, so they save it until they fight a strong enemy that is weak to rockets*
  * *example: the player has only 15 seconds of oxygen underwater, so they need a high DPS weapon to fight an underwater enemy*
* **Player state:** *short term economy* like health, inventory, consumables
  * *example: the player has 99% health, so they will avoid a health item that adds +25% health, because that would "waste" 24% of the pickup*
* **Player progression:** *long term economy* like experience points, perks, upgrades, gear
  * *example: the player has 99% health, but they have an upgrade that gives +100% damage if they are at full health, so they decide to pickup a +25% health item anyway because the damage bonus is worth more than the wasted healing*

<figure><img src="https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-LtVT8pJjInrrHVCovzy%2Fuploads%2Fiz3dIaVNvmDNNOlmE843%2FLDB_CombatProgression_RobMeyer_GodOfWarRagnarok.png?alt=media&amp;token=8cf58f25-1f6d-4f3e-b22d-913b64ca4793" alt=""><figcaption><p>Weapon progression spreadsheet used for the action RPG God of War: Ragnarok (2022), from the talk <a href="https://youtu.be/6iTBqcBv5QA?t=1311">"Reckoning With Fate: Combat At The Scale of Ragnarok" (2023) by Rob Meyer (via YouTube)</a></p></figcaption></figure>

> *"We tried to model our expectations for gear acquisition and progression in a way we felt would be healthy on paper, and then we constantly playtested and iterated on things to try to get the reality of the playtest to match our models.* \
> \
> *\[Here's a spreadsheet (pictured above) with] planned power level progression, of different gear slots at different points in the game. Each row is a different level in the game chronologically. Each column is a different piece of gear, and these are the levels that we expected you to get that gear to at that point in the game. We would constantly cross reference what we thought should be happening with what was actually happening in playtests...*
>
> *One trick we used is to \[make upgrading existing gear more expensive than buying new gear] so you had a temporary incentive to find new gear \[...] Or similarly, reward level 5 armor during exploration content when we knew the resources to upgrade from 4 to 5 weren't available yet, so we were guaranteeing that armor would be exciting and enticing for a short time."*
>
> \-- Rob Meyer, ["Reckoning With Gate: Combat At the Scale of Ragnarok" (2023) (YouTube)](https://www.youtube.com/watch?v=6iTBqcBv5QA\&t=1311s)

## Combat examples

Here we summarize three major approaches to combat:

* **Classic combat** (Doom, Quake) focuses on **movement**
  * **Soulslikes** (Dark Souls, Bloodborne, Elden Ring) require **dodging**
  * Fights are usually close range and continuous.
* **Military realism** (Counter-Strike, Call of Duty) is about **aiming**
  * **Battle royale** (Fortnite, PUBG, Apex Legends) adds more **economy**
  * Fights are often long range and erratic.
* **Modern combat** (Halo, Team Fortress 2, Overwatch) emphasizes **damage**
  * **Cover shooters** (Gears of War, Uncharted) add **positioning**
  * Fights are usually mid range and rhythmic.

Note: no game fits neatly into a category. These are just examples / just one way to think about these games.

![screenshot of iconic level "Dead Simple" in Doom 2 by American McGee and Sandy Petersen.](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MWwF44URjg88NMz-OF3%2F-MWwIRW8W0Iwo1pox6n-%2FLDB_Doom2_DeathSimple_Mancubus.png?alt=media\&token=9932a024-5478-4db0-91db-eb1d471405dd)

### Classic combat

Combat in Doom (1993) features a strong built-in auto-aim assist. The player cannot even look up or down vertically. Doom is clearly not about aiming. Instead, Doom's high speeds enable levels with large enemy counts, encounter variation, and huge sprawling level layouts.

> *"\[The player] runs at about 50 scale miles per hour – nonsensically fast by modern standards. Most of Doom’s enemies don’t have instant-hit projectile attacks, and most of the ones that do are quite weak – the lowly trooper and sergeant. Every other enemy projectile takes time to reach its target, and would look comical in a more realistic visual presentation.*
>
> *So because the player moves so quickly in Doom, and because most enemy attacks are dodgeable, the player can avoid a significant amount of damage simply by moving. \[...] This frees up Doom’s encounters to feature huge numbers of enemies, to vary scenarios by mixing in different proportions of threats, and to have huge, sprawling, often non-linear spaces that the player can traverse easily."*&#x20;
>
> *--JP LeBreton,* [*Coelacanth: Lessons from Doom*](http://vectorpoem.com/news/?p=74)

Dark Souls-like action RPG games formalize dodging mechanics via "dodge rolls" with "invincibility frames" (I-frames) providing complete damage negation with good timing. Learning how to read enemy moves, and repositioning / dodging to avoid damage, is often more important than using the best weapon or having the best equipment.

<figure><img src="https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-MWwKuv36sIacrXzo8RS%2F-MWwMiIwfWDFwy2gYMXs%2Fquake1.jpg?alt=media&amp;token=d3172b72-6176-4e74-9225-6f7742df1516" alt=""><figcaption><p>screenshot of Quake (1996) as it would've appeared back in 1996</p></figcaption></figure>

### Military realism

The original Counter-Strike (1999) popularized competitive team-based multiplayer in a realistic military style. Weapons are highly lethal and fights end within a few seconds. Success depends on fast reaction speed and aiming in the right place at the right time, while clearing firing angles and sightlines -- but flashbangs and smoke grenades can deny visibility. Varied gun accuracy, recoil, and bullet penetration mechanics supplement this focus on looking and aiming.

The more recent battle royale genre began as a mod for a realistic military sim shooter series called ARMA, and much of its approach carried over to PUBG: Battlegrounds, the first commercially successful battle royale shooter. This persists even in less militaristic battle royales like Fortnite or Apex, where it is still very common for new players to die suddenly to an unseen sniper a hundred meters away. However, this all depends on a player's ability to accumulate supplies and guns, adding an inventory management aspect and RPG-like progression to each round.

<figure><img src="https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-LtVT8pJjInrrHVCovzy%2Fuploads%2FYzdB7hFJPYBMQGzUCZDF%2FLDB_CS16_Combat.jpg?alt=media&amp;token=c0e4a8a0-30d1-4d70-8910-707269a52260" alt=""><figcaption><p>gameplay screenshot on the iconic multiplayer map de_dust2 by Dave Johnston, for Counter-Strike 1.6</p></figcaption></figure>

### Modern combat

In Halo: Combat Evolved (2001), the player moves slowly with a very floaty jump, so there's not much dodging here. But there also isn't much aiming either; the default pistol is notoriously one of the best weapons in the game, allowing cheap frequent mid-range / long range headshots with a subtle auto-aim "magnetism" well-suited for casual console play. Instead of movement or aiming, Halo is about managing damage:

> *"In almost every modern FPS, the player moves fairly slowly and a huge proportion of enemies are equipped with instant hit attacks – pistols, machine guns, sniper rifles. This usually puts the player in the role of “damage sponge” – they’re intended to soak up a certain amount of damage from mostly unavoidable enemy attacks, then seek cover and heal up. Halo’s recharging shield makes this mechanic quite explicit – by default, you’re exposed to damage and will die, while seeking cover halts that and completes the basic cycle of any combat."*
>
> \-- JP LeBreton, [Coelacanth: Lessons From Doom](http://vectorpoem.com/news/?p=74)

Multiplayer team shooters like Team Fortress 2 strongly emphasize healing, to the extent that every team always needs a healer. Overwatch builds on Halo's regenerating shield mechanic. Cover shooters like Gears of War or Uncharted feature regenerating health, but tie this rhythm to hiding behind objects. Modern combat is about getting shot at, alternating periods of risk and rest.

<figure><img src="https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-LtVT8pJjInrrHVCovzy%2Fuploads%2FWIvFFmu1iry71ysC3g5Q%2FLDB_Halo_Combat_BloodGulch.jpg?alt=media&amp;token=6d17a004-6b7a-4830-a25a-2a437cc036af" alt=""><figcaption><p>gameplay screenshot of the beloved multiplayer map Blood Gulch, from Halo: Combat Evolved by Bungie</p></figcaption></figure>

## TODO: How to build combat

* blockout a test arena
  * open area and/or 3 lane
* place some enemies
* playtest and repeat
* how to know when combat is "good enough"?

## Key concepts for combat levels

Once you've established the core combat systems, either by playing the game you're modding or by building your own combat from scratch, then you are ready to start designing more specific combat scenarios:

* [**Enemy design**](/process/combat/enemy.md) **is about defining different hostile NPC types.**
  * Ideally, each type has distinct behaviors, strengths, and weaknesses.
  * Without a roster of varied enemies, fights will feel repetitive.
* [**Encounters**](/process/combat/encounter.md) **are structured battles against NPCs.**
  * Open-ended combat puzzles; player must usually improvise a solution
  * Implementation usually involves some [scripting](/process/scripting.md).
* [**Cover**](/process/combat/cover.md) **is about building spaces to fight from.**
  * Where is safe, and where is high risk? Where can players fight or recover?
  * Cover varies with mechanics / weapons. You need core combat design first.
* [**Map balance**](/process/combat/balance.md) **is the fairness of the player's options, usually in PvP.**
  * Where can the player go, what territory can they control? How will the player know?
  * A balanced level helps players trust the [layout](/process/layout.md) and invest in the outcome.

We recommend approaching combat in the order listed above. Each aspect depends on the previous one. To build encounters, you need enemy design first. To coordinate cover, you need an idea of how the encounter should play out. To balance a map, you need to know which cover patterns make sense.

![enemy characters from Halo (2001), an early console FPS that popularized dynamic squad battles and vehicles](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-LtVT8pJjInrrHVCovzy%2Fuploads%2FwikRGFeyppGh71QsQLHO%2FLDB_Halo1_EnemyRoster_CombatEncounter.png?alt=media\&token=002f386d-5e9b-4b60-8bc6-ead3f6f32fdd)

## To review\...

* **Combat design** is about designing systems for physical conflict.
* To make combat levels, you first need a combat game. But making an entire game is hard, and this is just a level design book. Modding a game is easier.
* Common combat systems include:
  * **Combat mechanics** like aiming, dodging, timing, etc.
  * **Weapon design**, a varied set of interesting tools to use
  * **Economy**, systems of costs / benefits for weapons, inventory, and progression
* Some combat examples:
  * **Classic combat** & **soulslikes** emphasizes speed and dodging fire
  * **Military realism** & **battle royales** make guns and aiming more important
  * **Modern combat** & **cover shooters** are about managing health / damage
* To build a combat game, (TODO)

## Now what?

* Read more about key design concepts for combat level design:
  * [Enemy design](/process/combat/enemy.md)
  * [Encounter design](/process/combat/encounter.md)
  * [Cover](/process/combat/cover.md)
  * [Map balance](/process/combat/balance.md)
* Move on to the [Layout](/process/layout.md) phase.

### Further reading on combat design

* ["Reckoning With Fate: Combat At The Scale of Ragnarok" (2023) (via YouTube)](https://www.youtube.com/watch?v=6iTBqcBv5QA) is the most comprehensive talk on modern AAA combat design from Rob Meyer, lead combat designer on God of War: Ragnarok (2022). Meyer gives specific examples from his work and details the responsibilities of a combat designer at Sony Santa Monica.
