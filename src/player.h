#pragma once

#include <godot_cpp/classes/character_body2d.hpp>
#include <godot_cpp/classes/area2d.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <godot_cpp/classes/project_settings.hpp>

namespace godot {
class Player : public CharacterBody2D {
    GDCLASS(Player, CharacterBody2D)
private:
    Area2D *area_detector = nullptr;
    Area2D *top_z_level_area = nullptr;

    Label *velocity_label_x = nullptr;
    Label *velocity_label_y = nullptr;
    Label *medium_label = nullptr;
    Label *current_density_label = nullptr;
    Label *gravity_force_label = nullptr;
    Label *buoyancy_label = nullptr;
    Label *dash_label = nullptr;
    Label *double_jump_label = nullptr;
    Label *stomp_label = nullptr;

    //acceleration and speed variables
    double acceleration = 800.0;
    double thrust_x = 0.0;
    double max_power = 200.0;
    double jump_speed = -500.0;
    double dash_speed = 600.0;
    double target_depth = 6.0;

    //dimensions
    int horizontal_sprite_width = 0;
    int vertical_sprite_width = 0;
    double character_bottom = 0.0;

    //densities in kg/cm³
    double oak_density = 0.00077;
    double aerogel_density = 0.000002;
    double helium_density = 0.0000001786;
    double character_density = oak_density;

    //friction variables
    double friction_coefficient = 0.0;
    double friction = 0.0;
    Vector2 square_drag = Vector2(0.0, 0.0);
    Vector2 linear_drag = Vector2(0.0, 0.0);
    Vector2 total_drag = Vector2(0.0, 0.0);
    Vector2 total_force = Vector2(0.0, 0.0);
    Vector2 total_vertical_force = Vector2(0.0, 0.0);
    Vector2 total_horizontal_force = Vector2(0.0, 0.0);

    //density and mass variables
    double density_height_scale = 850000.0;
    double character_size = 1.0;
    double character_mass = character_size * character_density;

    //gravity settings, should be 981px/s²
    double surface_gravity = 981.0;
    double gravity = 0.0;
    double gravity_force = 0.0;
    double planet_radius = 10000.0;
    double radius_from_core = planet_radius;
    double abs_radius_from_core = radius_from_core;
    double core_direction = 1.0;
    double submersion_percent = 0.0;

    //damping
    double damping_ratio = 0.2;

    //abilities
    bool can_jump = true;
    double jump_timer = 0.0;
    bool can_double_jump = true;
    bool can_dash = true;
    double dash_timer = 0.0;
    bool can_downward_dash = true;


protected:
    static void _bind_methods();

public:
    void _physics_process(double delta) override;
    void _ready() override;

    Player();
    ~Player();
};

}