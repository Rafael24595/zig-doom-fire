# Zig Doom Fire

A terminal-based Doom Fire simulation implemented in Zig ⚡.
Supports configurable matrix size, fire intensity, wind effect, oxygen level and color/symbol themes.

![doom fire](.img/fire.gif)

```Text
Warning: This program has been tested on modern terminals (Terminal Windows 1.23.13503.0). Older terminals may exhibit slow rendering or display issues when using RGB color mode. For better performance, consider using ANSI mode.
```

---

## Features

- Configurable life simulation with adjustable:
  - Matrix size (dynamic to terminal)
  - Fire intensity
  - Wind effect
  - Oxygen level
  - Color themes
  - Symbol themes
- Color inheritance mode allows new cells to inherit or blend colors from parent cells
- Debug mode displaying internal state such as intensity, wind, oxygen, themes, memory usage, and seed
- Cross-platform signal handling for clean exit (Windows / Unix/Linux)

---

## Build & Run

### Requirements
- Zig compiler (Tested on 0.15.1)

### Build
```sh
  zig build
```

### Run
```sh
  zig-out/bin/zig-doom-fire [options]
```

---

## Dynamic Matrix Size

The simulation adapts automatically to the size of your terminal window.  

- Number of rows and columns is detected at runtime.
- Resizing the terminal while running adjusts the matrix dimensions dynamically.  
- Ensures the simulation always fills the visible area.

## Command Line Options

| Option | Description | Default | Values |
|--------|-------------|---------|--------|
| `-h`, `--help` | Show the help message | — | — |
| `-v`, `--version` | Show project's version | — | — |
| `-d` | Enable debug mode | Off | — |
| `-hc` | Show the controls map | Off | — |
| `-s` | Random seed | Current timestamp in ms | Any unsigned integer |
| `-ms` | Frame delay in milliseconds | 50 | Any unsigned integer |
| `-i` | Intensity | 0.60 × matrix height | Any unsigned integer |
| `-tc` | Color theme | Warm | Warm, Cool, GREEN_THEME, Gray, Neon |
| `-tc` | Symbol theme | Classic | Classic, Star, Arrow, Plus, Triangle, Spark, Block |
| `-cm` | Color mode | RGB | RGB, ANSI |

## Color Themes

Several themes are included for different visual effects.

| Palette | Description | Example Colors | Notes |
| ------- | ----------- | -------------- | ----- |
| Ash | Gray / ashy fire | Black, GrayDark, Gray, GrayLight, White | Smoke, ashes, subdued flames |
| Warm | Classic warm fire | Black, Orange, Yellow, White | Classic fire tones |
| Doom | Classic Doom-style intense fire | Black, Brown, Orange, Gold, White | More intense and deep than Warm |
| Blood | Red infernal fire | Black, Brown, Red, Coral, White | Perfect for burning blood or demonic effects |
| Cool | Blue / cold fire | Black, Navy, Cyan, White | Icy or water-like flames  |
| Viridis | Green supernatural fire | Black, GreenDark, GreenMedium, GreenBright, Lavender | Stable green with lavender highlight for volume |
| Plasma | Green intense / plasma | Black, GreenDark, GreenMedium, GreenBright | Violent green without highlights, ideal for contained energy |
| HellBloom | Pink infernal fire | Black, Purple, NeonPink, White | Aggressive pink, dramatic, Doom 64 style |
| Oblivion | Purple ethereal fire | Black, DeepPurple, Purple, Violet, Lavender, PaleLavender | Smooth gradient purple → white, elegant and magical |
| Singularity | Purple plasma / energy | Black, DeepPurple, NeonPurple, HotPurple, White | More aggressive, bright tip for energy effects |
| Neon | Neon multicolor | Black, NeonBlue, NeonPink, NeonOrange, White | Futuristic, luminous fire  |
| VoidFireX | Dark purple / void | Black, Navy, Purple, Lavender, White | Dark monochrome, conveys emptiness or contained energy |
| VoidFireY | Neon void | Black, NeonBlue, NeonPurple, NeonPink, White | Intense neon energy, maximum brightness for alien fire |


## Symbol Themes & Rendering

- Supports ASCII or Unicode block characters for active cells.
- Inactive cells are spaces ' '.
- Active cells can be colored using ANSI escape codes or RGB mode.
- Example character sets:

| Mode | Active Char | Inactive Char | Notes |
| ---- | ----------- | -------------- | ----- |
| Classic | `#` | ` ` | Large ASCII block |
| Star | `*` | ` ` | Medium ASCII |
| Arrow | `^` | ` ` | Tip of a flame / directional |
| Plus | `+` | ` ` | Small cross / subtle |
| Triangle | `▲` | ` ` | Solid flame shape |
| Spark | `✦`| ` ` | Bright spark / magical |
| Block | `█` | ` ` | Unicode block, dense |


---

### Recommended Terminal Setup

For the most immersive experience, using a **black terminal background** is recommended. This ensures the fire effect and color/symbol themes display as intended.

---

### Examples
#### Run with default settings:

```sh
  zig-out/bin/zig-doom-fire
```

#### Run in debug mode:
```sh
  zig-out/bin/zig-doom-fire -d
```

#### Set custom seed:
```sh
  zig-out/bin/zig-doom-fire -s 1768304672407
```

#### Set custom frame delay:
```sh
  zig-out/bin/zig-doom-fire -ms 150
```

#### Set specific color theme:
```sh
  zig-out/bin/zig-doom-fire -tc Cool
```

#### Set specific symbol theme:
```sh
  zig-out/bin/zig-doom-fire -ts Star
```

---

## Debug Mode

When enabled (-d), the program will print additional runtime information:
- Project name and version
- Memory usage (persistent & scratch)
- Execution parameters: speed, intensity, wind, oxygen, themes
- Random seed and matrix dimensions
- Time (Not counting breaks)

---

## Interactive Controls

The simulation supports real-time key input. This allows you to interactively pause, reload, or exit the simulation while it is running.

| Key | Action |
| --- | ------ |
| `p`, `Space` | Toggle pause/resume. When paused, the simulation stops updating the matrix but the display remains visible. Pressing again resumes the simulation. |
| `s`, | Toggle on/off the fire effect. |
| `w` | Increases the current oxygen level by 1, up to a maximum of 5. |
| `x` | Decreases the current oxygen level by 1, up to a minimum of -5. |
| `a` | Increases the current wind value by 1, up to a maximum of 5. |
| `d` | Decreases the current wind value by 1, up to a minimum of -5. |
| `+` | Increases the current sleep time by 10 ms, up to a maximum of 3000 ms (3 seconds). |
| `-` | Decreases the current sleep time by 10 ms, down to a minimum of 0 ms. |
| `q`, `CTRL+C` | Exit the simulation cleanly. |

### Notes

- Input is handled asynchronously in a separate thread, so the simulation continues rendering frames even while waiting for a keypress.
- Pause, reload, and exit are implemented using atomic flags, ensuring safe concurrent access between the input thread and the render loop.
- Works on Windows, Linux with platform-specific raw mode setup to ensure immediate key detection.

---
