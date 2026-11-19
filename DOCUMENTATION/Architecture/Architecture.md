[Main Page](../My_First_Jump_And_Run.md)

# Architecture

This page gives an overview of how the project is divided into systems and how they connect.

## Overview

The project has two layers:

- **C++ (GDExtension):** the `Player` class, which handles the per frame physics and the movement abilities. See [Player](Player.md).
- **GDScript:** scenes, level transitions, menus, and the save manager.

The C++ side covers the physics arithmetic. Everything else lives in scenes and scripts.

## Extension registration

The extension is registered at scene initialization by `src/register_types.cpp`, which exposes `Player` to Godot. Build details are on [Building](../Building/Building.md) page.

## Level transitions

Level changes are handled in the `scripts/main.gd`. The screen fades out, the next level loads in the background, and the current level is then replaced. Save loading uses the same path. See the [Main.gd](Main_gd.md) page for a detailed explanation.

## Save system

`save_manager` is an autoload that writes and reads the save file. It is available in every scene. See [Save system](Save_System.md) for the file location, the JSON fields, and the load flow.

## Player interface

`Player` exposes its state to GDScript through bound methods, such as the ability timers and the current material. The full list is on the [Player](Player.md) page.