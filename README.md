# Plant

A 2D strategy game built in Godot 4.5: plant crops and defenders, then keep at least one alive for five minutes while weather events hit the map.

![Gameplay with a plant info panel during a tornado event](docs/images/gameplay.png)

## Why it is useful

- A finished, playable Godot project with a full loop: menu, play, win or lose.
- The Web build runs in a browser from a static host with no install.

## Features

- 10 plants: six producers (sunflower, tomato, potato, carrot, corn, bamboo) and four defenders (white pine, cactus, tropical tree, sakura).
- Plants grow in stages only with enough water tiles nearby and shrink without it.
- Five random events: volcano, flooding, tornado, meteorite, storm. They get more frequent over time.
- A harvest every 5 seconds gives a random seed and score.
- Hover over a plant or seed to see its stats and water level.
- Placement hint shows the water level of a tile before you plant.

## How to play

- Press **PLAY!**. The game starts when you place your first seed.
- Click a seed slot, then hold the left mouse button on a grass tile to plant. Esc cancels.
- Producers raise your score. Defenders protect your other plants.
- Survive the 5-minute timer with a living plant to win. You lose when all plants die.

## How it works

- `scenes/game_state.gd`: inventory, placement, hover info, end screen.
- `scenes/game_loop.gd`: timer, harvests and random events.
- `plants/`: a `Plant` base class, with `ProducerPlant` and `DefenderPlant` subclasses that set the stats per plant.
- `entities/`: weather objects such as the tornado and wind gust.

## Tech stack

- Engine: Godot 4.5, GDScript, Compatibility renderer
- Export: Godot Web template, single-threaded
- Tooling: GitHub Actions builds the Web export and deploys it to GitHub Pages

## Run locally

Open the folder in Godot 4.5 and press Play. For the Web build (needs the 4.5 export templates):

```
mkdir -p build/web && godot --headless --export-release "Web" build/web/index.html
cd build/web && python3 -m http.server 8000
```

## Tests

No automated tests. CI checks that the project imports and the Web export succeeds.

## Team and my role

Built at the GUTS hackathon (October 2025). Original team repository: [Aunarky/hackathon-2025](https://github.com/Aunarky/hackathon-2025).

- Aunarky: main scene, inventory and placement.
- kailo9: plant classes, difficulty, timers, tutorial.
- 3kate90 (Kate Mykytenko): art, effects, main menu.
- yehorm14 (Yehor Mykhailov, me): plant balancing and plant descriptions.

## Licence

No licence chosen. All rights reserved by the authors.
