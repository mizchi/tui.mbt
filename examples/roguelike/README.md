# Roguelike (tui.mbt example)

Small terminal roguelike prototype built on `mizchi/tui` + `mizchi/signals`.

## Implemented

- Procedural map (walls + floors) with border and noise
- Player + enemy movement and turn-based loop
- Enemy random walk + melee hit on contact
- Shadow-casting FOV (walls block sight) with persistent exploration
- Colored tiles per cell
  - Player `@`, enemy `g`, wall `#`, floor `.`, stairs `>`, relic `*`, potion `!`
- Items + inventory
  - Relic required to win by stepping on stairs
  - Potions restore HP
- Status panel + event log

## Controls

- Move: `WASD` / Arrow keys / `HJKL`
- Wait: `.` or Space
- Use potion: `p`
- Quit: `q`

## Run

```bash
cd /Users/mz/ghq/github.com/mizchi/tui.mbt/examples/roguelike
moon run
```

## Notes

- Minimum recommended terminal size: 50x18
- Uses a simple RNG for repeatable-ish maps (seeded from terminal size)
