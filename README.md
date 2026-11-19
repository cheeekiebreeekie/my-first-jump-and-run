# My first Game

**My first ever Game, made in Godot, featuring realistic physics and generic 2D platformer mechanics**

## Core Features

* **Custom Fluid Dynamics & Drag:** Beautifully simulated realistic Linear Drag, Quadratic Drag, Dampening, 
Buoyancy, Friction, etc. using real world formulas, well performing by using C++
* **Planetary Gravity & Theoretical Core Inversion:** Continuous gravity calculations
* **Movement Abilities:** Jumping, double jumping, horizontal dashes and downward stomping
* **Shaders:** Retroesque style shader rendering the game at 480*270

## Tech Stack

* **Engine:** Godot 4.X
* **Language:** GDScript, C++20

## System Requirements

* **OS:** Linux (x86_64) or Windows (x86_64)
* **Linux:** A terminal emulator in `PATH` supporting the `-e` flag (e.g., `alacritty`, `kitty`, `konsole`, or `xterm`).

## Installation & Running

1. **Download & Extract:** Download `jumpandrun.windows.zip` or `jumpandrun.linux.tar` from the latest GitHub release and extract it to your desired folder
>[!Warning]
>**Do not extract or install into a write-protected directory** (such as `/usr/bin`, `C:\Program Files`, or standard read-only mount points). 
>The application needs write access to its working directory.
2. **Keep Folder Structure Intact:** Do not move or rename files inside the extracted directory (the launcher expects `bin/` to be next to it)
3. **Launch:**
    * **Linux:** Double-click `launcher` or execute `./launcher` from a terminal in the games directory.
    * **Windows:** Double-click `launcher.exe`

> **Note for Linux Users:** If launching fails with a window error, ensure a supported terminal emulator (like `alacritty` or `xterm`) is installed. The launcher uses it to initialize console output.

## Controls
| Action | Input (Keyboard) | Notes
| :--- | :--- | :--- |
| **Move Left / Right** | `A` / `D` | Dynamic acceleration & friction |
| **Jump** | `W` | Grounded jump |
| **Double Jump** | `W` (in air) | Resets upon touching the floor | 
| **Stomp** | `S` (in air) | Rapid downward force |
| **Horizontal Dash** | `Shift` | Cooldown indicated in HUD |
| **Cycle Player Density** | `R` | Swaps player density |
## License

* Slightly changed **PolyForm Noncommercial License 1.0.0** ([LICENSE](https://github.com/cheeekiebreeekie/my-first-jump-and-run/blob/Dev/LICENSE.md))