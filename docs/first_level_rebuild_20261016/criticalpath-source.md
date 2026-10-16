> For the complete documentation index, see [llms.txt](https://book.leveldesignbook.com/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://book.leveldesignbook.com/process/layout/criticalpath.md).

# Critical path

the minimum / main player path to complete a single player level

The **critical path** (or **golden path**) is the main intended player path / procedure to complete the level and progress.&#x20;

* usually for single player levels with scripted progressions, not multiplayer
* highlights the most important ("critical") parts of the level.
* represents an *ideal player flow* that ignores optional side areas

That last point is important. A critical path represents your *ideal* design goals and requirements, but it is not the reality. Most players will wander, explore, linger, or even just get confused.

## How to plan a critical path

In a layout drawing, the critical path markup helps other designers and collaborators understand the level's [pacing](/process/preproduction/pacing.md). What happens and where?

1. Draw an initial [layout](/process/layout.md).
2. Mark and label where the player starts and exits.
3. Mark, label, and number any major [beats](/process/preproduction/pacing.md#beats-and-variation).
4. If it won't look too confusing, then draw the player's route with arrows.

&#x20;    *For more on drawing floor plans, see* [*Layout*](/process/layout.md)*.*

![example level layout with marked critical path and numbered gameplay beats](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-Lzym-tKNi8yXq0u-46X%2F-M-21_eOR8UaLLu3gHTW%2Fldb_layout_example.png?alt=media\&token=f74ce3a9-5602-4fd8-932a-0585e2757d19)

## Critical path as scoping tool

In engineering, project managers use [critical path method (CPM)](https://en.wikipedia.org/wiki/Critical_path_method) to figure out which tasks must happen first and why. Charting the critical path helps them understand the logic and flow for the project.

We can use critical paths for level design in a similar way, to help manage project [scope](/process/preproduction/scope.md).

* How important is each part of the level?&#x20;
* If something isn't on the critical path, then only some players will see it. Is it worth making?

![the yellow hatched area could be removed without affecting the critical path ](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-Lzym-tKNi8yXq0u-46X%2F-M-23nLAYXxdB2RkcTid%2Fldb_layout_criticalpath_scope.png?alt=media\&token=6ef8702f-7657-48c2-bbd1-8102d2358753)

The critical path helps us imagine what a "minimal viable" layout looks like.&#x20;

For example, in the layout drawing above, the yellow hatched area is not on the critical path. So is it still worth making? If we cut this area, then we will have less work to do.

Maybe the level is still too big and too much work. Maybe we need to delete more.&#x20;

What if we deleted all the side areas? Does it still fulfill our experience design goals? Maybe we need to redesign the critical path entirely...

![what if we cut ALL "unnecessary" areas? now it's less work to build but does it still fulfill our experience goals?](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-Lzym-tKNi8yXq0u-46X%2F-M-25rDXmTkGBWwuVS-O%2Fldb_layout_criticalpath_scope_cut.png?alt=media\&token=d96d97c2-5999-4ebe-a114-423b5aa29c23)

## Against critical paths?

Designing around a critical path is potentially a reductive way for thinking about a space.&#x20;

Critical paths instrumentalize the world in terms of resources, gates, and objectives, a checklist of activities imposed on the player by a level designer. Can games and levels be more than just "content" for users to consume? What if your project requires a high degree of realism, plausibility, or sense of place? Building around a critical path usually results in a "video game-y" feeling space.&#x20;

Instead, some designers prefer to assemble a critical path *after* an already-complete [layout](/process/layout.md) and [blockout](/process/blockout.md), to flow around existing level geometry. Martin Hollis, producer of Goldeneye 007 (1997) for Nintendo 64 explains their level design process:

> *"The level creators, or architects were working without much level design, by which I mean often they had no player start points or exits in mind. Certainly they didn’t think about enemy positions or object positions. Their job was simply to produce an interesting space. After the levels were made, Dave or sometimes Duncan would be faced with filling them with objectives, enemies, and stuff. The benefit of this sloppy unplanned approach was that many of the levels in the game have a realistic and non-linear feel. There are rooms with no direct relevance to the level. There are multiple routes across the level. This is an anti-game design approach, frankly. It is inefficient because much of the level is unnecessary to the gameplay. But it contributes to a greater sense of freedom, and also realism. And in turn this sense of freedom and realism contributed enormously to the success of the game.”*\
> \
> \-- Martin Hollis, producer of Goldeneye 007 (N64) as quoted in ["Anti-Design / Backwards Game Design in Goldeneye 007" by Chris DeLeon](http://www.hobbygamedev.com/int/anti-design-in-ge007/)

![level geometry for "Surface" in Goldeneye 007 (1997) captured by Chris DeLeon https://imgur.com/a/MY59R](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LtVT8pJjInrrHVCovzy%2F-M-pU2WbIwJYUhInjEjr%2F-M-pWiCryMn_6vmSeAKF%2FGoldeneye007_Surface_Geometry_ChrisDeLeon.png?alt=media\&token=0671a8d1-d31c-4ef9-b3c9-1b4f18ea8e09)

## Critical path example: Deathloop (2021)

In the diagram below of the "Complex" level from the first person RPG Deathloop (2021), level designer Sylvain Menguy highlights critical paths for a non linear single player map. They document an afternoon configuration and an evening configuration, along with the player's probable paths to the area boss.

> *The game has 4 main maps, playable on 4 time periods through the day (morning, noon, afternoon, and evening), where the player can freely explore the level, engage combats, discover puzzles, or even solve the “murder puzzle” which structures the main adventure of the game...*

This approximate layout diagram omits needless details in favor of a big picture, and that's useful for communicating [pacing](/process/preproduction/pacing.md). Notice how the white arrows shown below don't match the map terrain exactly, but still convey a lot of information about the intended routes. Even though the player begins with 3 lanes, these lanes always converge to two entrances to the boss arena on the other side of the map.

![layout flow diagram of map "Complex" in Deathloop (2021) by Sylvain Menguy, via SylvainMenguy.com](https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-LtVT8pJjInrrHVCovzy%2Fuploads%2FQHC9gOvGNYfBc12JQ70n%2FLDB_Deathloop_ComplexLayout_SylvainMenguy.jpg?alt=media\&token=faa621bc-b515-47f9-bcb9-0a205ebc6810)

> *The map was made from the start to allow for multiplayer gameplay, with another player invading in the afternoon or evening. The reading of the layout is thus different between these 2 periods, and the encounters with the antagonist Julianna, who comes to chase Colt and make his life harder, are also different.*
>
> *This shared layout between time periods always gives several navigation options, dead ends and long corridors from which you cannot extricate yourself are prohibited, to make a smoother experience and allow you to quickly rotate between areas..."*
>
> &#x20;[- Sylvain Menguy](https://sylvainmenguy.com/en/project/deathloop)

"Rotating" is when player(s) must change focus ("rotate") to another map area, usually in team-based multiplayer shooters like Counter-Strike: Global Offensive. It's interesting that Menguy adopts multiplayer level design thinking for a single player level.

&#x20;    *For more on rotating in multiplayer design, see* [*Map balance*](/process/combat/balance.md)*.*

## To review\...

The **critical path** is the ideal player route to progress through a single player level.

It is mainly a planning and scoping tool. It helps communicate [pacing](/process/preproduction/pacing.md) within a [layout](/process/layout.md) drawing. And if you need to scope down the project, it can help you decide what parts of a level to cut.

However, prioritizing the critical path can result in more artificial feeling spaces. Some level designers design a space first, and then figure out a critical path later.

## Now what?

* Read more about [layouts](/process/layout.md) and [flow](/process/layout/flow.md).
* [Circulation](/process/layout/flow/circulation.md) is helpful to think about too.
