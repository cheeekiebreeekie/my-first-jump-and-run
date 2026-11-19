[Back](Architecture.md)

# Player

This page describes the `Player` class: the header `src/player.h`, the implementation `src/player.cpp`, the per-frame physics, the movement abilities, and the values that tune them. For how `Player` fits into the rest of the project, see [Architecture](Architecture.md).

## Files

| &nbsp;File | &nbsp;Contents |
| :--- | :--- |
| &nbsp;`src/player.h` | &nbsp;Class declaration, memeber variables, inline getters and setters, tunable values |
| &nbsp;`src/player.cpp` | &nbsp;`_bind_methods()`, `_ready()`, and `_physics_process()` |

## Class overview

`Player` extends `CharacterBody2D`. Its class is registered at scene initialization in `src/register_types.cpp`. The physics runs in `_physics_process()`. Abilities, material, frame skip are exposed to GDScript through `_bind_methods()`.

## Scene requirements

`_ready()` looks up thees children. Missing nodes produce an error from `_get_Node()`:

- `Sprite2D`: its texture supplies the width and height. These are read once.
- `Area2D`: used for fluid detection. Without it, `physics_process()` prints `"Missing Area Detector"` and returns before `move_and_slide()`, so the player does not move.
- `Camera2D/VelocityLabelX`, `Camera2D/VelocityLabelY`, `Camera2D/MediumLabel`, `Camera2D/CurrentDensityLabel`, `Camera2D/GravityForceLabel`, `Camera2D/BuoyancyLabel`, `Camera2D/DashLabel`, `Camera2D/DoubleJumpLabel`, `Camera2D/StompLabel`: the HUD labels. They are used without null checks.

## GDScript interface

These methods are bound with `ClassDB::bind_method()`:

| &nbsp;Method | &nbsp;Purpose |
| :--- | :--- |
| &nbsp;`get_character_material()` / `set_character_material(name)` | &nbsp;Read or set the material. Currently accepts 'oak', 'concrete', or 'aerogel' (See `density_names` in `src/player.h`). <br>Unkown names print an error and leave the material unchanged |
| &nbsp;`get_jump_timer()` / `set_jump_timer(jump_timer_set)` | &nbsp;Jump lock timer |
| &nbsp;`get_can_double_jump()` / `set_can_double_jump(can_double_jump_set)` | &nbsp;Wheter a double jump is available |
| &nbsp;`get_can_downward_dash()` / `set_can_downward_dash(can_downward_dash_set)` | &nbsp;Wheter a stomp is available |
| &nbsp;`get_dash_timer()` / `set_dash_timer(dash_timer_set)` | &nbsp;Horizontal dash cooldown |
| &nbsp;`set_frame_skip(frame_skip_set)` | &nbsp;Starts a frame skip (see below) |

The `velocity` property is inherited from `CharacterBody2D. `main.gd` sets it directly. `get_character_density()`is C++ only and is not bound.

The setters also change the alpha of the matching HUD label, so the label dims while the ability is unavailable. `set_jump_timer()` changes the alpha of the double-jump label, since there is no seperate jump label.

## Frame skip

`set_frame_skip