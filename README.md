# Zig Doom Fire

A configurable, terminal-based Doom Fire simulation written in Zig. ⚡

Customize the fire with adjustable intensity, wind, oxygen levels, color themes, symbol sets, and rendering speed.

![Doom Fire](.img/fire.gif)

> **Terminal compatibility:** The project has been tested with Windows Terminal `1.23.13503.0`. Rendering performance and color display may vary across terminal emulators. If RGB rendering is slow or causes display issues, try `ANSI` mode.

## Features

- **Configurable fire:** Adjust fire intensity, wind, oxygen levels, frame delay, and random seed.
- **Color customization:** Choose from multiple palettes, including classic fire, cool tones, grayscale, supernatural colors, and neon effects.
- **Symbol themes:** Render the fire using ASCII characters or Unicode symbols.
- **Dynamic terminal sizing:** Adapt the matrix to terminal dimensions and handle window resizing while running.
- **Multiple color modes:** Use RGB or ANSI color output.
- **Debug mode:** Inspect runtime parameters, matrix dimensions, random seed, and memory usage.
- **Interactive controls:** Pause the simulation, toggle the fire, adjust wind and oxygen, change rendering speed, or exit cleanly.
- **Cross-platform shutdown:** Handle keyboard interrupts and restore terminal state during normal shutdown on supported platforms.

## Requirements

- Zig compiler `0.15.1` (tested version).
- A terminal emulator with ANSI escape-sequence support.

## Build

Build the project using Zig:

```sh
zig build
```

For an optimized release build, use `ReleaseFast`:

```sh
zig build -Doptimize=ReleaseFast
```

The optimized build prioritizes runtime performance over debug-friendly behavior.

## Run

Launch the executable:

```sh
zig-out/bin/zig-doom-fire
```

Display the available command-line options:

```sh
zig-out/bin/zig-doom-fire --help
```

## Command-Line Options

| Option | Description | Default |
|---|---|---|
| `-h`, `--help` | Display the help message | — |
| `-v`, `--version` | Display the project version | — |
| `-d` | Enable debug output | Disabled |
| `-hc` | Display the interactive controls map | Disabled |
| `-s` | Set the random seed | Current timestamp in milliseconds |
| `-ms` | Set the frame delay in milliseconds | `45` ms on Windows; `50` ms on other platforms |
| `-i` | Set the fire intensity | `0.60 × matrix height` |
| `-tc` | Set the color theme | `warm` |
| `-ts` | Set the symbol theme | `classic` |
| `-cm` | Set the color mode | `rgb` |

### Available Values

**Color theme (`-tc`)**

| Theme | Description |
|---|---|
| `ash` | Gray and ashy tones |
| `warm` | Classic fire colors |
| `doom` | Intense, deep Doom-inspired fire |
| `blood` | Dark red and infernal tones |
| `cool` | Blue and icy tones |
| `viridis` | Green tones with lavender highlights |
| `plasma` | Intense green energy |
| `hellBloom` | Pink and purple infernal flames |
| `oblivion` | Ethereal purple gradients |
| `singularity` | Bright purple plasma |
| `neon` | Multicolored neon tones |
| `void_fire_x` | Dark purple and navy tones |
| `void_fire_y` | Bright neon void colors |

**Symbol theme (`-ts`)**

| Theme | Active Character | Description |
|---|---|---|
| `classic` | `#` | Large ASCII blocks |
| `star` | `*` | Star-like particles |
| `arrow` | `^` | Directional flame tips |
| `plus` | `+` | Small cross-shaped particles |
| `triangle` | `▲` | Solid triangular shapes |
| `apark` | `✦` | Bright decorative sparks |
| `block` | `█` | Dense Unicode blocks |

**Color mode (`-cm`)**

- `rgb` — RGB color output.
- `ansi` — ANSI color output, which may perform better on some terminals.

## Examples

Run with the default configuration:

```sh
zig-out/bin/zig-doom-fire
```

Enable debug output:

```sh
zig-out/bin/zig-doom-fire -d
```

Set a custom random seed:

```sh
zig-out/bin/zig-doom-fire -s 1768304672407
```

Change the frame delay:

```sh
zig-out/bin/zig-doom-fire -ms 150
```

Set the fire intensity:

```sh
zig-out/bin/zig-doom-fire -i 30
```

Select a color theme:

```sh
zig-out/bin/zig-doom-fire -tc Cool
```

Use a different symbol theme:

```sh
zig-out/bin/zig-doom-fire -ts Star
```

Use ANSI color output:

```sh
zig-out/bin/zig-doom-fire -cm ANSI
```

Combine multiple options:

```sh
zig-out/bin/zig-doom-fire -tc Neon -ts Spark -cm ANSI -ms 75
```

## Terminal Recommendations

A black terminal background is recommended for the intended fire effect and good contrast across color themes.

RGB rendering may perform differently depending on the terminal emulator. If performance or color display is an issue, try ANSI mode.

Unicode symbol themes may also depend on the terminal's font and character support.

## Debug Mode

Enable debug output with `-d` to inspect runtime information, including:

- Project name and version.
- Persistent and scratch memory usage.
- Frame delay, fire intensity, wind, and oxygen levels.
- Random seed and matrix dimensions.
- Color and symbol themes.
- Elapsed execution time, excluding breaks.

Debug output is useful for inspecting the simulation's runtime configuration and troubleshooting unexpected behavior.

## Interactive Controls

The simulation accepts keyboard input while running.

| Key | Action |
|---|---|
| `p`, `Space` | Toggle pause and resume. The current frame remains visible while paused. |
| `s` | Toggle the fire effect on or off. |
| `w` | Increase oxygen by `1`, up to `5`. |
| `x` | Decrease oxygen by `1`, down to `-5`. |
| `a` | Increase wind by `1`, up to `5`. |
| `d` | Decrease wind by `1`, down to `-5`. |
| `+` | Increase the frame delay by `10` ms, up to `3000` ms. |
| `-` | Decrease the frame delay by `10` ms, down to `0` ms. |
| `q`, `Ctrl+C` | Request a clean exit. |

Input is processed on a separate thread, allowing the render loop to continue while waiting for key presses. Atomic flags coordinate input and rendering operations.

## Shutdown and Signal Handling

The application supports clean shutdown through keyboard controls and interrupt handling on supported platforms.

During normal shutdown, the application attempts to restore the terminal state and stop background input processing. Exact behavior may depend on the operating system, terminal emulator, and how the process terminates.