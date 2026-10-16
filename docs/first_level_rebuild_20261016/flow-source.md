> For the complete documentation index, see [llms.txt](https://book.leveldesignbook.com/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://book.leveldesignbook.com/process/layout/flow.md).

# Flow

How it feels to move through the level

In level design, **flow** is how it generally feels to move along different paths / between different parts of a level.&#x20;

Is the path simple or complicated? Straight or curvy? Slow or fast? All of these factors affect the player's movement through the space. In short, designing flow is about **designing movement.**

You should start designing flow during initial [layout](/process/layout.md) planning, but you won't be able to verify how it actually feels until you [blockout](/process/blockout.md) and [playtest](/process/blockout/playtesting.md).

{% hint style="info" %}
*Do not confuse flow (level design) with* [*flow (game design)*](https://www.gamasutra.com/view/feature/166972/cognitive_flow_the_psychology_of_.php)*, the theory that players enter a highly-engaged "flow state" when skill and challenge are in equilibrium.*
{% endhint %}

![track maps with numbered turns for Spa (F1) vs. Daytona (NASCAR), by Will Pittenger (under CC-BY-SA license)](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-LzxBngZZiccy6pmtNI6%2F-LzxHF70DrNlm51YIb11%2Flayout_flow_race-tracks.png?alt=media\&token=c91e6699-8615-4e38-83bc-1c69ca154ea7)

## How to feel the flow

Compare the two real-world race tracks pictured above.

The [Circuit de Spa-Francorchamps](https://en.wikipedia.org/wiki/Circuit_de_Spa-Francorchamps) *(above, left)* is a Formula One (F1) racing circuit with a wide variety of turns, [sightlines](/process/combat/balance.md#sightlines), and slopes that requires flawless technical driving. In contrast, the [Daytona Speedway](https://en.wikipedia.org/wiki/Daytona_International_Speedway) *(above, right)* is a NASCAR race track, a flat wide oval that supports big crowds of cars pushing against each other.&#x20;

Both "levels" serve the same core mechanic of motor racing, but emphasize very different driving styles and strategies.&#x20;

<figure><img src="https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-LtVT8pJjInrrHVCovzy%2Fuploads%2FoFdpE4TrM4ewjxblgPqW%2FLDB_Flow_SpaF1Race1965_LATPhotography.jpg?alt=media&amp;token=a483c165-6104-4edb-a020-83aaad2e803a" alt=""><figcaption><p>Spa's famous "Eau Rouge" turn at the 1965 Belgian Grand Prix; photo copyright LAT Photographic</p></figcaption></figure>

Below a pro race car driver describes the flow of Eau Rouge, a famous turn at Spa:

> *"... as you come over the crest, you don't know where you will land. \[...] you have a long uphill straight afterwards where you can lose a lot of time if you make a mistake. But it is also an important corner for the driver's feeling. It makes a special impression every lap, because you also have a compression in your body as you go through the bottom of the corner. It is very strange – but good fun as well."*
>
> \-- F1 champion Fernando Alonso describing Eau Rouge ([via Formula1.com](https://web.archive.org/web/20131017080654/http://www.formula1.com/news/headlines/2004/8/2097.html))

In this way, level design is kind of like motor racing. What type of movements do we ask the player to make? Does it feel safe or dangerous, simple or complex?&#x20;

On the multiplayer map de\_dust2 by Dave Johnston, iconic "Dust doors" *(below)* funnel players into a narrow dangerous zig-zag turn. An opponent on the other side can even shoot through the thin wooden doors. Like the Eau Rouge, you never know 100% what's on the other side. This is more exciting than a straight clear open path.

<figure><img src="https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-LtVT8pJjInrrHVCovzy%2Fuploads%2FeehW9bYge6x5GYF9SQIE%2FLDB_Flow_CounterStrike16_DeDustDoors.jpg?alt=media&amp;token=281c958a-2fae-45c6-a234-e86461d3f941" alt=""><figcaption><p>some famous "Dust Doors" on the map de_dust2 in Counter-Strike 1.6; map by Dave Johnston</p></figcaption></figure>

## The best flow?

"Dust doors" could be considered "bad" flow -- the doors break the line of movement and force sharp sudden careful turns. But here, the so-called bad flow is actually good, it adds drama and strategy within the context of Counter-Strike's fast paced fights.

Sometimes fast is good, sometimes slow and complex is better. It all depends on the game systems and the level's purpose.

Fast-paced arcade-style games might favor smooth flow with wide generous turns and minimal interruptions. Meanwhile a horror walking simulator might work better with sharp narrow turns, blind intersections, S-shaped curves, and maze-like dead ends.&#x20;

In the end, **the best flow is whatever supports the intended** [**experience design goals**](/process/preproduction.md#experience-goals)**.**

* What is this level / area / encounter / experience about? Fast exciting action, calm observation and navigation? The first glimpse of a big city? A scary chase? A hangout?
* For competitive multiplayer maps, flow strongly affects overall [map balance](/process/combat/balance.md).
* To verify the flow works as intended, you must [blockout](/process/blockout.md) and [playtest](/process/blockout/playtesting.md).

## Verticality

**Verticality** is vertical flow, how it feels to move upwards and downwards.&#x20;

In a map, this usually means stairs, ramps, slopes, elevators, ladders, cliffs, raised platforms, jump pads, etc.

The conventional wisdom here is that more verticality is better, since it adds more visual interest to the map structure and breaks up a floor plane. But today, we advise against too much random verticality, and instead urge restraint. The suitability of verticality depends a lot on the core game design; many game mechanics require spaces that are just big flat floors, and sometimes that's ok. You don't need to put random steps and platforms everywhere.

&#x20;    *For more info on vertical flow, see* [*Verticality*](#verticality)*.*

![diagram of jump pad and teleporter trajectories in Q3DM17 "The Longest Yard" by Brandon James for Quake 3 Arena (1999)](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-M0LFFpYhA9pRoTbeeA_%2F-M0LYunLb3nF9nAK8RAW%2Fldb_q3dm17_verticality.png?alt=media\&token=740db590-357f-4be3-a314-50156a3d4d20)

## How to design flow

Flow is about **designing movement.** A lot of factors affect how movement feels:&#x20;

* **Speed.** Does it feel slow or fast to move along a path?
* **Direction.** Is the path smooth / continuous, or disjointed / abrupt with sharp turns?
* [**Wayfinding**](/process/blockout/wayfinding.md)**.** Is the path obvious? What info helps the player plan a route?
* [**Metrics**](/process/blockout/metrics.md)**.** What are the player's movement mechanics? How are distances tuned?

To consider these factors all at once, we offer three design techniques for designing flow:

* **Desire lines:** compare ideal paths in a single room / area
* **Critical path:** visualize single player [pacing](/process/preproduction/pacing.md) across the whole level
* **Circulation:** visualize multiplayer lanes across the entire map

### Desire lines

In urban planning, **desire lines** (or **desire paths**) are user-made paths marked by foot traffic and erosion.

In the photo below, an "unofficial" dirt path deviates from the "official" concrete path. The unofficial path is the desire path. It is what player actually want / and what feels most natural and intuitive to them.

![desire paths deviating from sidewalk / cutting across a lawn, photo by Duncan Rawlinson](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-M-QrgYN1BiS9OiCyCTk%2F-M-Qv--HoLKFSFRufa06%2Fdesire-paths_duncan-rawlinson.jpg?alt=media\&token=680da146-6d9c-4641-8e79-90a836403073)

{% hint style="info" %}
*Sometimes IRL architects* [*pave desire paths into official paths*](https://99percentinvisible.org/article/least-resistance-desire-paths-can-lead-better-design/)*. In level design we respond similarly, by observing* [*playtests*](/process/blockout/playtesting.md) *and adjusting accordingly.*
{% endhint %}

This type of thinking is useful for designing small scale flow, within a single room / area:

1. Imagine an efficient "desire line" from the player to their destination.
2. Compare the desire line against the actual path(s) the player can take.

In the example diagram below, a player must climb stairs to reach an exit...

![diagram comparing switchback stairs (left) vs. corner stairs (right) with different flows; level geometry by Andrew Yoder](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-M-Sd_o0ZMtrCIz1IXMv%2F-M-SeI34uOMR4wwofDvB%2FFlowComparison_AndrewYoder.png?alt=media\&token=95779c53-f49c-402c-9007-23cf58122b36)

The player's desire line *(yellow)* leads directly to the exit on the second floor, but the actual flow *(red)* forces the player onto the stairs.&#x20;

The switchback stairs *(left)* feel less straightforward than the single turn corner stairs *(right)*, because the switchback requires the player to make an extra turn.

While the switchback is less efficient, remember that **less efficient flow is not necessarily bad.** The switchback could be useful:

* Slow down the player, and encourage room exploration first
* Offer a parkour-style shortcut, climb directly up to the mid landing
* Place a ranged enemy on the mid landing; how easily can the player attack it?

### Critical path

The **critical path** (or "golden path") is the minimum / main path to complete a single player level.&#x20;

More generally, it represents an *idealized player flow* that highlights the most important ("critical") parts of the level and mandatory game content that you want every player to experience.

Single player [layout](/process/layout.md) drawings usually need some sort of labeled critical path. Sketch, highlight, or mark the critical path in the drawing -- or if the drawing is too complicated, at least mark the player start, exits, and labeled points of interest.

&#x20;    *For more on designing main routes for single player levels, see* [*Critical path*](/process/layout/criticalpath.md)*.*

![example level layout drawing with marked critical path and numbered gameplay beats](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-Lzym-tKNi8yXq0u-46X%2F-M-21_eOR8UaLLu3gHTW%2Fldb_layout_example.png?alt=media\&token=f74ce3a9-5602-4fd8-932a-0585e2757d19)

### Circulation

**Circulation** (or "connectivity") refers to how areas connect to each other.

Designing with circulation can help support a level's storytelling and wayfinding. A level with plausible circulation might resemble the way that real world architecture functions, thus allowing players to read and predict patterns based on their general knowledge from outside of the game.

Circulation analysis is especially helpful for multiplayer map design, which is often more non-linear and does not follow a single critical path. Instead, we organize the level layout into a system of *lanes.*

&#x20;    *For more on storytelling, wayfinding, and multiplayer lanes, see* [*Circulation*](/process/layout/flow/circulation.md)*.*

![Circulation diagram for Achievement Preparatory Academy middle school by Studio Twenty Seven Architecture](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-Lxco6Y2Q4w3rLcoR9Y4%2F-LxcoEISPL1o6m16CVlo%2Fimage.jpeg?alt=media\&token=65698965-ce64-430d-afed-6a84d2eea47b)

## To review\...

**Flow** is about how players move around a level. [Verticality](#verticality) is vertical flow.

When **designing movement**, think about speed, direction, [wayfinding](/process/blockout/wayfinding.md), and [metrics](/process/blockout/metrics.md). Yeah, it's a lot.

Three ways to think about flow:

* **Desire line:** compare ideal path vs. actual pathing within a room / area
* [**Critical path**](/process/layout/criticalpath.md)**:** the ideal player path to complete a single player level
* [**Circulation**](/process/layout/flow/circulation.md)**:** connective areas / "lanes" of the level

**Flow is a tool.** Inefficient "bad" flow is not necessarily bad, because it can serve a purpose in the right context. Similarly, overly efficient "good" flow can feel boring. It all depends on your design goals.

## Further reading

* [Matthew "Lunaran" Breit](http://lunaran.com/) wrote some of the [earliest level design theory on flow](https://web.archive.org/web/20080211132942/http://www.lunaran.com/page.php?id=189), as well as [a post on connectivity](https://web.archive.org/web/20080211132937/http://www.lunaran.com/page.php?id=188) back in 1999. Today, [Breit regrets his overly prescriptive tone](https://web.archive.org/web/20080212182719/http://lunaran.com/page.php?id=9) *("... incorrectly asserts that dead ends, forced indirect routes, or other things that slow players are essentially illegal...")* as a product of his Quake fanboyism, but we still love him anyway.
