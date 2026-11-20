# My First Jump And Run

Developer documentation for *My First Jump And Run*, a 2D platformer built in Godot 4 with a C++ GDExtension for the physics. The player's movement and fluid behavior are implemented in C++; levels, menus, and the save system are GDScript.

> [!NOTE]
> This page covers development. For the player-facing description and controls, see the [README](../README.md)

## Related articles

- [Building](Building/Building.md)
- [Architecture](Architecture/Architecture.md)
- [Player](Architecture/Player.md)
-

- [Troubleshooting](Troubleshooting/Troubleshooting.md)

## Requirements

- Godot 4.2 or newer (`compatability_minimum` in `addons/cpp/example.gdextension`; the project itself is set up for 4.7)
- godot-cpp, included as a git submodule
- SCons, gcc-13 / g++-13, and a MinGW-w64 toolchain for the Windows Launcher

## Quick Start

```console
$ git submodule update --init --recursive
$ scons platform=linux target=template_debug
```

Then open `project.godot` in the Godot editor. See [Building](Building/Building.md) for release builds, the launcher, and Windows.

## Repository layout

| &nbsp;Path | &nbsp;Contents |
| :--- | :--- |
| &nbsp;`src/` | &nbsp;C++ GDExtension source (`player.cpp`, `register_types.cpp`) |
| &nbsp;`godot-cpp/` | &nbsp;godot-cpp submodule |
| &nbsp;`scenes/` | &nbsp;Godot scenes, including levels and menus |
| &nbsp;`scripts/` | &nbsp;GDScript, including `save_manager.gd` |
| &nbsp;`assets/` | &nbsp;Sprites, textures and `pause_Menu.gd` template |
| &nbsp;`changelogs/` | &nbsp;Per-version changelogs and the template |
| &nbsp;`jumpandrun.xxx/` | &nbsp;Release folders with the launcher and README |