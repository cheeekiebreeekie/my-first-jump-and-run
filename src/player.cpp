#include "player.h"
#include "godot_cpp/classes/kinematic_collision2d.hpp"
#include "godot_cpp/variant/string.hpp"

#include <algorithm>
#include <string>
#include <format>
#include <math.h>

#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/classes/sprite2d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/collision_shape2d.hpp>
#include <godot_cpp/classes/collision_object2d.hpp>
#include <godot_cpp/classes/rectangle_shape2d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <godot_cpp/core/class_db.hpp>


namespace Densities {
    constexpr double AIR = 0.000001225;
    constexpr double WATER = 0.001;
    constexpr double VACUUM = 0.0;
    constexpr double VACUUM_VISCOSITY = 0.0;
    constexpr double AIR_VISCOSITY = 0.000001813;
    constexpr double GRASS_FRICTION = 0.50;
    constexpr double WATER_VISCOSITY = 0.00001002;
}


namespace godot{

Player::Player(){
}
Player::~Player(){
}

void Player::_bind_methods(){

}

void Player::_ready(){



    //import project gravity settings
    ProjectSettings *settings = ProjectSettings::get_singleton();
    Sprite2D *sprite  = get_node<Sprite2D>("Sprite2D");

    surface_gravity = settings->get_setting("physics/2d/default_gravity");
    gravity = surface_gravity;

    //get character width and height
    if (sprite != nullptr){
        Ref<Texture2D> texture = sprite->get_texture();

        if (texture.is_valid()) {
            horizontal_sprite_width = static_cast<int>(texture->get_width());
            vertical_sprite_width = static_cast<int>(texture->get_height());
        }
    }

    //get Area2D as pointer so it doesn't pull the entire area2d object into memory
    Node *detector_node = get_node_or_null(NodePath("Area2D"));
    if (detector_node != nullptr) {
        area_detector = Object::cast_to<Area2D>(detector_node);
    }
    //get labels
    //velocty.x label
    Node *velocity_label_x_node = get_node_or_null(NodePath("Camera2D/VelocityLabelX"));
    if (velocity_label_x_node != nullptr) {
        velocity_label_x = Object::cast_to<Label>(velocity_label_x_node); 
    }
    //velocity.y label
    Node *velocity_label_y_node = get_node_or_null(NodePath("Camera2D/VelocityLabelY"));
    if (velocity_label_y_node != nullptr) {
        velocity_label_y = Object::cast_to<Label>(velocity_label_y_node);
    }
    //medium label
    Node *medium_label_node = get_node_or_null(NodePath("Camera2D/MediumLabel"));
    if (medium_label_node != nullptr) {
        medium_label = Object::cast_to<Label>(medium_label_node);
    }
    //current density label
    Node *current_density_label_node = get_node_or_null(NodePath("Camera2D/CurrentDensityLabel"));
    if (current_density_label_node != nullptr) {
        current_density_label = Object::cast_to<Label>(current_density_label_node);
    }
    //total_vertical_force label
    Node *gravity_force_label_node = get_node_or_null(NodePath("Camera2D/GravityForceLabel"));
    if (gravity_force_label_node != nullptr) {
        gravity_force_label = Object::cast_to<Label>(gravity_force_label_node);
    }
    //current buoyancy label
    Node *buoyancy_label_node = get_node_or_null(NodePath("Camera2D/BuoyancyLabel"));
    if (buoyancy_label_node != nullptr) {
        buoyancy_label = Object::cast_to<Label>(buoyancy_label_node);
    }
    //dash label
    Node *dash_label_node = get_node_or_null(NodePath("Camera2D/DashLabel"));
    if (dash_label_node != nullptr) {
        dash_label = Object::cast_to<Label>(dash_label_node);
    }
    //double jump label
    Node *double_jump_label_node = get_node_or_null(NodePath("Camera2D/DoubleJumpLabel"));
    if (double_jump_label_node != nullptr) {
        double_jump_label = Object::cast_to<Label>(double_jump_label_node);
    }
    //downward dash label
    Node *stomp_label_node = get_node_or_null(NodePath("Camera2D/StompLabel"));
    if (stomp_label_node != nullptr) {
        stomp_label = Object::cast_to<Label>(stomp_label_node);
    }
    ////////////////////////////////////////////////////////////////////


}

void Player::_physics_process(double delta) {

    if (Engine::get_singleton()->is_editor_hint()) {
        return;
    }



    Vector2 velocity = get_velocity();

    top_z_level_area = nullptr;

    //calculates gravity based on height
    radius_from_core = planet_radius - static_cast<double>(get_global_position().y);
    if (Math::is_zero_approx(radius_from_core)){
        radius_from_core = 0.001;
    }

    abs_radius_from_core = Math::abs(radius_from_core);
    core_direction = (radius_from_core >= 0) ? 1.0 : -1.0;

    if (abs_radius_from_core <= planet_radius){
        gravity = surface_gravity * (abs_radius_from_core / planet_radius) * core_direction;
    } else if (abs_radius_from_core >= planet_radius) {
        gravity = surface_gravity * (Math::pow(planet_radius, 2.0) / Math::pow(abs_radius_from_core, 2.0)) *core_direction;
    }

    //calculate character mass, calculated like a cuboid
    character_size = horizontal_sprite_width * horizontal_sprite_width * vertical_sprite_width;
    character_mass = character_size * character_density;

    //gravity force
    gravity_force = (character_mass * gravity);

    ////////////////////////////////////////////////////////////////////
    //get overlapping areas/////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////
    if (!area_detector){
        return;
    }
    TypedArray<Area2D> areas = area_detector->get_overlapping_areas();
    submersion_percent = 0.0;
    //can't sort inline godot objects in c++ so we have to push them into a vector and then sort them ourselves
    if (!areas.is_empty()) {
        std::vector<Area2D*> sorted_areas;
        sorted_areas.reserve(areas.size());

        for (int i = 0; i < areas.size(); i++) {
            Area2D *area = Object::cast_to<Area2D>(areas[i]);
            if (area) {
                sorted_areas.push_back(area);
            }
        }

        if (!sorted_areas.empty()) {
            std::sort(sorted_areas.begin(), sorted_areas.end(), [](Area2D *a, Area2D *b) {
                return a->get_z_index() > b->get_z_index();
            });
            top_z_level_area = sorted_areas[0];
        }
        character_bottom = static_cast<double>(get_global_position().y) + (vertical_sprite_width * 0.5);

        CollisionShape2D *area_shape_node = top_z_level_area->get_node<CollisionShape2D>(NodePath("CollisionShape2D"));

        if (area_shape_node) {
            Ref<RectangleShape2D> area_shape = Object::cast_to<RectangleShape2D>(area_shape_node->get_shape().ptr());
        
            //get submersion percent
            if (area_shape.is_valid()) {
                double area_shape_node_global_y = static_cast<double>(area_shape_node->get_global_position().y);
                double area_shape_size = static_cast<double>(area_shape->get_size().y);
                double area_shade_node_global_scale = static_cast<double>(area_shape_node->get_global_scale().y);
                double area_top_y = area_shape_node_global_y - (area_shape_size * 0.5 * area_shade_node_global_scale);

                double submerged_height = character_bottom - area_top_y;

                submersion_percent = Math::clamp(submerged_height / vertical_sprite_width, 0.0, 1.0);
            }
        }
    }
    ////////////////////////////////////////////////////////////////////

    //current barometric fluid density
    //barometric aproximation is rho = rho_0 * e^(-altitude / H) -altitude cause godot y is inversed
    double current_fluid_density = top_z_level_area 
        ? static_cast<double>(top_z_level_area->get("density")) 
        : Densities::VACUUM;
    double current_fluid_viscocity = top_z_level_area
        ? static_cast<double>(top_z_level_area->get("viscocity"))
        : Densities::VACUUM_VISCOSITY;
    double current_density = current_fluid_density == Densities::AIR
        ? current_fluid_density * Math::exp(get_global_position().y / density_height_scale)
        : current_fluid_density;
    ////////////////////////////////////////////////////////////////////

    //buoyancy 
    double character_submerged_size = character_size * submersion_percent;
    double displaced_mass = current_density * character_submerged_size;
    double effective_mass = character_mass + (0.8 * displaced_mass);
    double buoyancy = (current_density * character_submerged_size * gravity);
    ////////////////////////////////////////////////////////////////////

    //drag
    //linear drag (6 * Pi * rho * r) * v
    linear_drag = (6.0 * Math_PI * current_fluid_viscocity * (0.5 * horizontal_sprite_width) * velocity);
    //square drag and skin friction (0.5 * rho * 1.05 "drag coeff" * A * S * v * |v|) + (0.5 * rho * 0.005 * A * S * 4 * v * |v|)
    square_drag = velocity.length() > 0
        ? (0.5 * current_density * 1.05 * Math::pow(horizontal_sprite_width, 2.0) * submersion_percent * velocity * velocity.length()) + (0.5 * current_density * 0.005 * Math::pow(horizontal_sprite_width, 2.0) * submersion_percent * 4 * velocity * velocity.length())
        : Vector2(0.0, 0.0);
    total_drag = square_drag + linear_drag;
    ////////////////////////////////////////////////////////////////////

    //damping forces
    double slamming_force = 0.0;
    double added_mass = 0.0;
    double stiffness = 0.0;
    double critical_damping = 0.0;
    double damping_force = 0.0;

    if (submersion_percent > 0.0) {
        //damping force v.y * cc * d || velocity.y * critical_damping * damping_ratio
        stiffness = current_fluid_density * Math::pow(horizontal_sprite_width, 2.0) * Math::abs(gravity); //k = rho * width* g
        critical_damping = 2.0 * Math::sqrt(effective_mass * stiffness); //cc 2 sqrt(meff * k)
        damping_force = velocity.y * critical_damping * damping_ratio;

        //slamming force
        if (velocity.y > 50.0) {
            //madded = rho * w^3 + (PI / 2) * e^(-c * k)
            added_mass = current_fluid_density * Math::pow(horizontal_sprite_width, 3.0) * (Math_PI / 2.0) * Math::exp(-submersion_percent * target_depth);
            //Fs = v.y^2 * madded * (k / w)
            slamming_force = Math::clamp(Math::pow(static_cast<double>((velocity.y)), 2.0) * (added_mass * (target_depth / horizontal_sprite_width)), 0.0, (velocity.y * effective_mass) / delta);
        }
    }
    ////////////////////////////////////////////////////////////////////

    //get X input direction and calculate force
    double direction = Input::get_singleton()->get_axis("move_left", "move_right");
    //minimum force
    double stall_force = acceleration * effective_mass;
    //dynamic current force
    if (Math::sign(direction) == Math::sign(velocity.x)) {
        thrust_x = direction * Math::min(stall_force, (max_power * stall_force) / Math::max(static_cast<double>(Math::abs(velocity.x)), 1.0));
    } else if (Math::sign(direction) != Math::sign(velocity.x)) {
        thrust_x = 2 * direction * Math::min(stall_force, (max_power * stall_force) / Math::max(static_cast<double>(Math::abs(velocity.x)), 1.0)) ;
    }
    ////////////////////////////////////////////////////////////////////

    //friction
    if (is_on_floor()) {
        Ref<KinematicCollision2D> current_floor = get_last_slide_collision();

        if (current_floor.is_valid() /*&& current_floor->get_collider()->get("friction")*/) {
            Object *collider = current_floor->get_collider();
            if (collider != nullptr) {
                Variant friction_val = collider->get("friction");
                if (friction_val.get_type() != Variant::NIL) {
                    friction_coefficient = static_cast<double>(friction_val);
                }
            }
        }
        if (Math::abs(velocity.x) < 10.0 && direction == 0) {
            velocity.x = 0.0;
        }
        if (direction != 0 && Math::sign(direction) != Math::sign(velocity.x)){
            friction_coefficient *= 4.0;
        }
    } else {
        friction_coefficient = 0.0;
    }

    friction = Math::sign(velocity.x) * friction_coefficient * (gravity_force - buoyancy);

    if (Math::abs(velocity.x) > (effective_mass * gravity - total_drag.x) / effective_mass) {
        friction *= 4.0;
    }
    ////////////////////////////////////////////////////////////////////

    //sum up all forces and turn them into acceleration
    total_vertical_force = Vector2(0.0, gravity_force - buoyancy - slamming_force -damping_force);
    total_horizontal_force = Vector2(thrust_x - friction, 0.0);
    total_force = (total_vertical_force + total_horizontal_force - total_drag) / effective_mass * delta;
    velocity += total_force;
    ////////////////////////////////////////////////////////////////////

    //displays
    //display velocity.x
    double total_velocity_x = Math::round(velocity.x * 100.0) / 100.0;
    std::string velocity_text_x = std::format("VelocityX: {}", total_velocity_x);
    velocity_label_x->set_text(velocity_text_x.c_str());
    //display velocity.y
    double total_velocity_y = Math::round(velocity.y * 100.0) / 100.0;
    std::string velocity_text_y = std::format("VelocityY: {}", total_velocity_y);
    velocity_label_y->set_text(velocity_text_y.c_str());
    //display medium
    std::string medium_text = std::format("Medium: {:f}", current_fluid_density);
    medium_label->set_text(medium_text.c_str());
    //display current density
    std::string density_text = std::format("Current Density: {}", current_density);
    current_density_label->set_text(density_text.c_str());
    //display current gravity force
    std::string gravity_text = std::format("Vertical Force: ({}, {})", total_vertical_force.x, total_vertical_force.y);
    gravity_force_label->set_text(gravity_text.c_str());
    //display current buoyancy
    std::string buoyancy_text = std::format("Buoyancy: {}", buoyancy);
    buoyancy_label->set_text(buoyancy_text.c_str());
    ////////////////////////////////////////////////////////////////////

    //abiliities
    //jumping
    if (jump_timer > 0) {
        jump_timer -= delta;
    }
    if (is_on_floor() && Input::get_singleton()->is_action_pressed("move_up") && jump_timer <= 0) {
        jump_timer = 0.5;
        velocity.y += jump_speed; 
    }
    ////////////////////////////////////////////////////////////////////
    //double jumping
    if (!is_on_floor() && Input::get_singleton()->is_action_just_pressed("move_up") && can_double_jump) {
        can_double_jump = false;
        Color color = double_jump_label->get_modulate();
        color.a = 0.5;
        double_jump_label->set_modulate(color);
        velocity.y += 1.1 * jump_speed;
    }
    ////////////////////////////////////////////////////////////////////
    //downward dash
    if (!is_on_floor() && Input::get_singleton()->is_action_just_pressed("move_down") && can_downward_dash) {
        if (Math::sign(velocity.y) == Math::sign(jump_speed)) {
            velocity.y = 0.0;
        }
        can_downward_dash = false;
        Color color = stomp_label->get_modulate();
        color.a = 0.5;
        stomp_label->set_modulate(color);
        velocity.y -= 2*jump_speed;
    }
    ////////////////////////////////////////////////////////////////////
    //horizontal dash
    if (dash_timer > 0) {
        dash_timer -= delta;
    }
    if (dash_timer <= 0){
        Color color = dash_label->get_modulate();
        color.a = 1.0;
        dash_label->set_modulate(color);
        if (Input::get_singleton()->is_action_just_pressed("move_dash")) {
            Color color = dash_label->get_modulate();
            color.a = 0.5;
            dash_label->set_modulate(color);
            if (direction != 0.0) {
                velocity.x += (direction * dash_speed);
            } else if (Math::abs(velocity.x) >= 5.0) {
                velocity.x += (Math::sign(velocity.x) * dash_speed);
            }
            dash_timer = 2.0;
        }
    }

    //floor detection for ability activation and label alpha channel 100%
    if (is_on_floor()) {
        can_double_jump = true;
        can_downward_dash = true;
        Color colora = double_jump_label->get_modulate();
        colora.a = 1.0;
        double_jump_label->set_modulate(colora);
        Color colorb = stomp_label->get_modulate();
        colorb.a = 1.0;
        stomp_label->set_modulate(colorb);
    }
    ////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////


    set_velocity(velocity);
    move_and_slide();

}

}