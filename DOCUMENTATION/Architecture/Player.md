[Back](Architecture.md)

# Player

This page describes the `Player` class: the header `src/player.h`, the implementation `src/player.cpp`, the per-frame physics, the movement abilities, and the values that tune them. For how `Player` fits into the rest of the project, see [Architecture](Architecture.md).

## Files

| &nbsp;File | &nbsp;Contents |
| :--- | :--- |
| &nbsp;`src/player.h` | &nbsp;Class declaration, member variables, inline getters and setters, tunable values |
| &nbsp;`src/player.cpp` | &nbsp;`_bind_methods()`, `_ready()`, and `_physics_process()` |

## Class overview

`Player` extends `CharacterBody2D`. Its class is registered at scene initialization in `src/register_types.cpp`. The physics runs in `_physics_process()`. Abilities, material, and frame skip are exposed to GDScript through `_bind_methods()`.

## Scene requirements

`_ready()` looks up these children. Missing nodes produce an error from `_get_Node()`:

- `Sprite2D`: its texture supplies the width and height. These are read once.
- `Area2D`: used for fluid detection. Without it, `_physics_process()` prints `"Missing Area Detector"` and returns before `move_and_slide()`, so the player does not move.
- `Camera2D/VelocityLabelX`, `Camera2D/VelocityLabelY`, `Camera2D/MediumLabel`, `Camera2D/CurrentDensityLabel`, `Camera2D/GravityForceLabel`, `Camera2D/BuoyancyLabel`, `Camera2D/DashLabel`, `Camera2D/DoubleJumpLabel`, `Camera2D/StompLabel`: the HUD labels. They are used without null checks.

## GDScript interface

These methods are bound with `ClassDB::bind_method()`:

| &nbsp;Method | &nbsp;Purpose |
| :--- | :--- |
| &nbsp;`get_character_material()` / `set_character_material(name)` | &nbsp;Read or set the material. Currently accepts 'oak', 'concrete', or 'aerogel' (See `density_names` in `src/player.h`). <br>Unkown names print an error and leave the material unchanged |
| &nbsp;`get_jump_timer()` / `set_jump_timer(jump_timer_set)` | &nbsp;Jump lock timer |
| &nbsp;`get_can_double_jump()` / `set_can_double_jump(can_double_jump_set)` | &nbsp;Whether a double jump is available |
| &nbsp;`get_can_downward_dash()` / `set_can_downward_dash(can_downward_dash_set)` | &nbsp;Whether a stomp is available |
| &nbsp;`get_dash_timer()` / `set_dash_timer(dash_timer_set)` | &nbsp;Horizontal dash cooldown |
| &nbsp;`set_frame_skip(frame_skip_set)` | &nbsp;Starts a frame skip (see below) |

The `velocity` property is inherited from `CharacterBody2D. `main.gd` sets it directly. `get_character_density()`is C++ only and is not bound.

The setters also change the alpha of the matching HUD label, so the label dims while the ability is unavailable. `set_jump_timer()` changes the alpha of the double-jump label, since there is no separate jump label.

## Frame skip

`set_frame_skip(frame_skip_set)` sets `frame_skip_counter` to 2 and `floor_detection_timeout` to 0.1s. During the next two physics frames, `_physics_process()` only calls `move_and_slide()`. Forces, abilities, and the HUD are not updated. [`main.gd`](Main_gd.md) uses this during level transitions.

## Per-frame processing

`_physics_process()` runs these steps in order

1. Read the velocity into a local copy.
2. Handle frame skip and return if it is active.
3. Return if the code is running in the editor.
4. Compute [gravity](#gravity) from height.
5. Compute the size and [mass](#mass-and-density) from the current sprite and material.
6. Find the [fluid and the submersion percent](#fluids-and-submersion).
7. Compute [buoyancy and effective mass](#buoyancy-and-effective-mass).
8. Compute [drag](#drag).
9. Compute [damping and slamming](#damping-and-slamming).
10. Compute [horizontal thrust](#horizontal-thrust-and-friction).
11. Compute [friction](#horizontal-thrust-and-friction).
12. Sum the forces and [integrate](#integration) the velocity.
13. Update the [HUD labels](#hud-labels).
14. Process the [abilities](#abilities).
15. Write the velocity back and call `move_and_slide()`.

### Gravity

The core sits at `planet_radius` below the origin. Godot's y axis points down.

```
 r = planet_radius - global_y            (r = 0 is replaced with 0.001 to avoid +/- inf result)

|r| < R: g = g0 * (|r| / R) * sign(r)
|r| >= R: g = g0 * (R^2 / |r|^2) * sign(r)
```

`g0` is `physics/2d/default_gravity` from the project settings, reading `_ready()` (981 px/s²). `R` is `planet_radius` (10000 px). Below the core, `r` is negative, so gravity points upward. This is the core inversion described in README.

### Mass and density

The player is treated as a cuboid:

```
character_size = w^2 * h
character_mass = character_size * density
gravity_force = character_mass * g
```

`w` is the texture width and `h` is the texture height. `character_size` holds the volume, not a scale factor. `density` comes from the current material.

### Fluids and submersion

The fluid is the overlapping `Area2D` with the highest `z_index`. Any overlapping `Area2D` counts, not only water areas, so an unrelated area above a fluid will take over. The fluid must define `density` and `viscocity` script properties. The spelling matches the source. With no fluid, density and viscosity are both 0.

Submersion is the fraction of the player's height below the fluid's top edge. The top edge comes from the fluid's `CollisionShape2D` , and that shape must be a `RectangleShape2D`. Otherwise the submersion is 0, even though the fluid's density and viscosity still apply.

```
character_bottom = global_y + h * 0.5
submersion       = clamp((character_bottom - fluid_top) / h, 0, 1)
```

If the fluid density equals the `AIR` constant exactly (`0.000001225`), the density is scaled with height. Any other value is used as is:

```
rho = rho_air * exp(y / 850000)
```

### Buoyancy and effective mass

```
submerged_size = character_size * submersion
displaced_mass = rho * submerged_size
effective_mass = character_mass + 0.8 * displaced_mass
buoyancy       = rho * submerged_size * g
```

The effective mass is used for acceleration. The 0.8 stands for the added mass coefficient (~0.8 for square surfaces).

### Drag

Drag has a linear term and a quadratic term with a skin-friction term.

```
linear    = 6 * pi * viscosity * (w / 2) * v
quadratic = 0.5 * rho * 1.05 * w^2 * S * v * |v|
skin      = 0.5 * rho * 0.005 * w^2 * S * 4 * v * |v|

total_drag = linear + quadratic + skin
```

S standing for `submersion_percent`

### Damping and slamming

Damping only applies when the player is submerged. The damping ratio is 0.2.

```
k          = rho * w^2 * |g|
c_critical = 2 * sqrt(effective_mass * k)
damping    = v.y * c_critical * 0.2
```

Slamming applies when falling fast. Since y points down, that means `v.y > 50`:

```
added_mass = rho * w^3 * (pi / 2) * exp(-S * target_depth)
slamming   = clamp(v.y^2 * added_mass * (target_depth / w), 0, v.y * effective_mass / delta)
```

The slamming force cap is divided by delta to avoid overshoots.

### Horizontal thrust and friction

The input direction is `get_axis("move_left", "move_right")`, a value from -1 to 1. Thrust is capped by the stall force, so it weakens as speed increases:

```
stall  = 800 * effective_mass
thrust = dir * min(stall, 200 * stall / max(|v.x|, 1))
```

When the input opposes the current horizontal velocity, the thrust is multiplied by 4.

Friction only applies while on the floor. The coefficient is read from the `friction` property of the floor collider. Off the floor, the coefficient is set to 0.

```
friction = sign(v.x) * coefficient * (gravity_force - buoyancy)
```

Friction is multiplied by 4 when `|v.x|` exceeds `(effective_mass * g - drag.x) / effective_mass`. On the floor, with no input and `|v.x| < 10`, `v.x` is set to 0 so the player stops.

### Integration

```
F_vertical   = (0, gravity_force - buoyancy - slamming - damping)
F_horizontal = (thrust - friction, 0)
velocity    += (F_vertical + F_horizontal - total_drag) / effective_mass * delta
```

The ability code runs after this and can change `velocity` before `move_and_slide()`.

### HUD labels

Every frame, the labels show the horizontal and vertical velocity, the medium's density, the current density, the vertical force, the buoyancy. The F3 key toggles their visibility through `scripts/F3_toggle_label_visibility.gd`.

### Abilities

| &nbsp;Ability | &nbsp;Input | &nbsp;Effect | &nbsp;Limit |
| :--- | :--- | :--- | :--- |
| &nbsp;Jump | &nbsp;`move_up` (held) | &nbsp;`v.y += jump_speed` (-500) | &nbsp;On the floor. Sets a 0.5s lock. |
| &nbsp;Double jump | &nbsp;`move_up` (just pressed) | `v.y += 1.1 * jump_speed` | &nbsp;Once per airtime. |
| &nbsp;Stomp | &nbsp;`move_down` (just pressed) | &nbsp;If `v.y < 0`, sets `v.y = 0`. Then adds 1000 to `v.y`. | Once per airtime. |
| &nbsp;Horizontal dash | &nbsp;`move_dash` (just pressed) | &nbsp;`v.x += 600` in the input direction, or in the direction of travel if `\|v.x\|` >= 5` | &nbsp;2s cooldown. Starts even if nothing happens. |
| &nbsp;Density cycle | &nbsp;`r` (just pressed) | &nbsp;Next material: oak, concrete, aerogel, then oak | None |

Holding `move_up`on the floor jumps again each time the 0.5s lock expires. At standard gravity the lock expires before the player touches the ground again.

Double jump and stomp recharge while on the floor. The recharge runs at most every 0.1s, controlled by `floor_detection_timeout`.

## Tunable values

These are member initializers in `src/player.h`. Changing one requires a recompile.

| &nbsp;Member | &nbsp;Value | &nbsp;Meaning |
| :--- | :--- | :--- |
| &nbsp;`acceleration` | &nbsp;800.0 | &nbsp;Scales the stall force |
| &nbsp;`max_power` | &nbsp;200.0 | &nbsp;Caps thrust at higher speeds |
| &nbsp;`jump_speed` | &nbsp;-500.0 | &nbsp;Jump impulse |
| &nbsp;`dash_speed` | &nbsp;600.0 | &nbsp;Horizontal dash impulse |
| &nbsp;`target_depth` | &nbsp;6.0 | &nbsp;Depth factor in slamming |
| &nbsp;`density_height_scale` | &nbsp;850000.0 | &nbsp;Height scale for air density |
| &nbsp;`surface_gravity` | &nbsp;981.0 | &nbsp;Default gravity, replaced in `_ready()` from project settings |
| &nbsp;`planet_radius` | &nbsp;10000.0 | &nbsp;Distance to the core |
| &nbsp;`damping_ratio` | &nbsp;0.2 | &nbsp;Damping |
| &nbsp;`oak_density` | &nbsp;0.00077 | &nbsp;Density of `oak` |
| &nbsp;`concrete_density` | &nbsp;0.0024 | &nbsp;Density of `concrete` |
| &nbsp;`aerogel_density` | &nbsp;0.000002 | &nbsp;Density of `aerogel` |

Some values are set in `_physics_process()` rather than in the header: the 0.5s jump lock, the 1.1 double-jump factor, the 1000 stomp impulse, the 2s dash cooldown, the 0.1s floor recharge, and the 2-frame skip.

## Implementation notes

- `vertical_sprite_width` holds the textures height.
- The `friction` multiplier on reversed input changes `friction_coefficient` itself. If the floor collider has a `friction` property, the value is reloaded every floor frame, so it does not accumulate. If the collider has no such property, the coefficient keeps its previous value, and holding reversed input multiplies it again each frame.
- In `player.cpp`, the `Densities` namespace defines `WATER`, `AIR_VISCOSITY`, `WATER_VISCOSITY`, and `GRASS_FRICTION`, but the physics code does not use them.
- `set_jump_timer()` dims the double-jump label, since there is no jump label

## See also

- [Architecture](Architecture.md)
- [Building](../Building/Building.md)