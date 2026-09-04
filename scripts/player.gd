extends CharacterBody2D
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
#To-Do: Realistic x Movement, friction and jumping

#get nodes, @onready waits for parent initialization before getting the node to avoid Nil error
@onready var dash_label = get_node("Camera2D/DashLabel")
@onready var double_jump_label = get_node("Camera2D/DoubleJumpLabel")
@onready var velocity_labelx = get_node("Camera2D/VelocityLabelX")
@onready var velocity_labely = get_node("Camera2D/VelocityLabelY")
@onready var stomp_label = get_node("Camera2D/StompLabel")
@onready var medium_label = get_node("Camera2D/MediumLabel")
@onready var current_density_label = get_node("Camera2D/CurrentDensityLabel")
@onready var gravity_force_label = get_node("Camera2D/GravityForceLabel")
@onready var buyoncy_label = get_node("Camera2D/BuyoncyLabel")

#acceleration and speed variables
@export var acceleration: float = 800.0
var thrust_x: float = 0.0
var max_power: float = 200.0
var jump_speed = -500.0
@export var dash_speed: float = 600.0	
var target_depth: float = 6.0
#dimensions
@onready var horizontal_sprite_width = get_node("Sprite2D").texture.get_width()
@onready var vertical_sprite_width = get_node("Sprite2D").texture.get_height()
#densities in kg/cm³
var oak_density = 0.00077
var aerogel_density = 0.000002
var helium_density = 0.0000001786
var character_density = oak_density
#friction variables
var friction_coefficient = 0.0
var square_drag: Vector2 = Vector2.ZERO
var linear_drag: Vector2 = Vector2.ZERO
var total_force: Vector2 = Vector2.ZERO
var total_drag: Vector2 = Vector2.ZERO
#density variables
var density_height_scale = 850000.0 #px as the standard height scale is 850000.0 cm
#get project gravity settings, should be 981px/s²
var surface_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var gravity: float = surface_gravity
var planet_radius: float = 10000.0
#enable abilities, needed to turn them off later
var can_jump = true
var can_double_jump = true
var can_dash = true
var can_downward_dash = true

func _physics_process(delta: float) -> void:
	#calculate gravity based on height
	var radius_from_core: float = planet_radius - global_position.y
	if is_zero_approx(radius_from_core):
		radius_from_core = 0.001
	var abs_radius_from_core: float = abs(radius_from_core)
	var core_direction: float = 1.0 if radius_from_core >= 0 else -1.0
	if abs_radius_from_core <= planet_radius:
		gravity = surface_gravity * (abs_radius_from_core / planet_radius) * core_direction
	elif abs_radius_from_core > planet_radius:
		gravity = surface_gravity * (pow(planet_radius, 2.0) / pow(abs_radius_from_core, 2.0)) * core_direction
		
	#calculate character mass, calculated like a cuboid
	var character_size: float = horizontal_sprite_width * horizontal_sprite_width * vertical_sprite_width
	var character_mass: float = character_size * character_density
	
	#gravity force
	var gravity_force: float = (character_mass * gravity)
	
	#get current Area2D
	var areas = $Area2D.get_overlapping_areas()
	var submersion_percent: float = 0.0
	if not areas.is_empty():
		#sort areas array by z_index so I don't have to set depth with attached scripts
		areas.sort_custom(func(a: Area2D, b: Area2D): return a.z_index > b.z_index)
		#get characters submerged size | character bottom y = pos y + (height / 2) godot +y is down
		var character_bottom: float = global_position.y + (vertical_sprite_width / 2.0)
		
		var area_shape_node = areas[0].get_node("CollisionShape2D")
		var area_shape = area_shape_node.shape as RectangleShape2D
		if area_shape:
			#bottom y of the fluids/gasses area, y pos - (y size * 0.5 * y scale)
			var area_top_y: float = area_shape_node.global_position.y - (area_shape.size.y * 0.5 * area_shape_node.global_scale.y)
			var submerged_height: float = character_bottom - area_top_y
			submersion_percent = clamp(submerged_height / vertical_sprite_width, 0.0, 1.0)
			
	#current baromatric fluid density
	#baromatric approximation is rho = rho_0 * e^(-altitude / H) -altitude cause godot y is inversed
	var current_fluid_density = areas[0].density if not areas.is_empty() else Densities.VACUUM
	var current_fluid_viscocity = areas[0].viscocity if not areas.is_empty() else Densities.VACUUM_VISCOCITY
	var current_density: float = current_fluid_density * exp(global_position.y / density_height_scale) if current_fluid_density == Densities.AIR else current_fluid_density
	
	#buyoncy 
	var character_submerged_size: float = character_size * submersion_percent
	var displaced_mass: float = current_density * character_submerged_size
	var effective_mass: float = character_mass + (0.8 * displaced_mass)
	var buyoncy: float = (current_density * character_submerged_size * gravity)
	
	#drag 
	#linear drag (6 * Pi * rho * r) * v
	linear_drag = (6.0 * PI * current_fluid_viscocity * (0.5 * horizontal_sprite_width)) * velocity 
	#square drag and skin friction (0.5 * rho * 1.05 "drag coeff" * A * S * v * |v|) + (0.5 * rho * 0.005 * A * S * 4 * v * |v|)
	square_drag = (0.5 * current_density * 1.05 * pow(horizontal_sprite_width, 2.0) * submersion_percent * velocity * velocity.length()) + (0.5 * current_density * 0.005 * pow(horizontal_sprite_width, 2.0) * submersion_percent * 4 * velocity * velocity.length()) if velocity.length() > 0 else Vector2.ZERO
	total_drag = square_drag + linear_drag
	
	#damping forces
	var slamming_force: float = 0.0
	var added_mass: float = 0.0
	var stiffness: float = 0.0
	var critical_damping: float = 0.0
	var damping_ratio: float = 0.0
	var damping_force: float = 0.0 
	if submersion_percent > 0.0: 
		#damping force v.y * cc * 
		stiffness = current_fluid_density * pow(horizontal_sprite_width, 2.0) * abs(gravity) #k = rho * width * g
		critical_damping = 2.0 * sqrt(effective_mass * stiffness) #cc 2 sqrt(meff * k)
		damping_ratio = 0.2 #cc, pulled out my ass with the help of gemini
		damping_force = velocity.y * critical_damping * damping_ratio 
		if velocity.y > 50.0 and submersion_percent < 1.0:
			#Wagners Hydrodynamic Impact Model 
			# madded = rho * w^3 + (PI / 2) * e^(-c * k)
			added_mass = current_fluid_density * pow(horizontal_sprite_width, 3.0) * (PI / 2.0) * exp(-submersion_percent * target_depth)
			# Fs = v.y^2 * madded * (k / w)
			slamming_force = clampf(pow(velocity.y, 2.0) * (added_mass * (target_depth / horizontal_sprite_width)), 0.0, (velocity.y * effective_mass) / delta)
	
	#get X input direction and calculate force
	var direction := Input.get_axis("move_left", "move_right")
	#minimum force
	var stall_force = acceleration * effective_mass 
	#dynamic current force
	if sign(direction) == sign(velocity.x):
		thrust_x = direction * min(stall_force, (max_power * stall_force) / (max(abs(velocity.x), 1.0)))
	elif sign(direction) != sign(velocity.x):
		thrust_x = 2 * direction * min(stall_force, (max_power * stall_force) / (max(abs(velocity.x), 1.0)))
	#friction
	if is_on_floor():
		var current_floor = get_last_slide_collision()
							 #handle exceptions of floors without friction variable
		if current_floor and "friction" in current_floor.get_collider(): 
			friction_coefficient = current_floor.get_collider().friction
		if abs(velocity.x) < 10.0 and direction == 0:
			velocity.x = 0.0
		if direction != 0 and sign(direction) != sign(velocity.x):
			friction_coefficient = friction_coefficient * 4
	else:
		friction_coefficient = 0.0
	var friction: float = sign(velocity.x) * friction_coefficient * (gravity_force - buyoncy)
	if abs(velocity.x) > (effective_mass * gravity - total_drag.x) / effective_mass:
		friction = friction * 4.0
	#sum all forces and turn them into acceleration
	var total_vertical_force: Vector2 = Vector2(0.0, gravity_force - buyoncy - slamming_force - damping_force)
	var total_horizontal_force: Vector2 = Vector2(thrust_x - friction , 0.0)
	total_force = (total_vertical_force + total_horizontal_force - total_drag) / effective_mass * delta 
	velocity += total_force
	
	#display velocityx
	var total_velocityx = round(velocity.x * 100.0) / 100.0
	var velocity_textx = "VelocityX: %spx/s"
	var actual_velocity_textx = velocity_textx % total_velocityx
	velocity_labelx.text = actual_velocity_textx
	#display velocityy
	var total_velocityy = round(velocity.y * 100.0) / 100.0
	var velocity_texty = "VelocityY: %spx/s"
	var actual_velocity_texty = velocity_texty % total_velocityy
	velocity_labely.text = actual_velocity_texty
	#display medium
	var medium_text = "Medium: %s"
	var actual_medium_text = medium_text % current_fluid_density
	medium_label.text = actual_medium_text
	#display current density
	var density_text = "Current Density: %s"
	var actual_density_text = density_text % current_density
	current_density_label.text = actual_density_text
	#display current gravity force
	var gravity_text = "Vertical Force: %s"
	var actual_gravity_text = gravity_text % total_vertical_force
	gravity_force_label.text = actual_gravity_text
	#display current buyoncy
	var buyoncy_text = "Buyoncy: %s"
	var actual_buyoncy_text = buyoncy_text % buyoncy
	buyoncy_label.text = actual_buyoncy_text

	#jumping
	if is_on_floor() and Input.is_action_pressed("move_up") and can_jump:
		can_jump = false
		velocity.y += jump_speed
		get_tree().create_timer(0.5).timeout.connect(func(): can_jump = true) #0.5 second delay for jumping to avoid bugs on edges
	
	#double jumping
	if !is_on_floor() and Input.is_action_just_pressed("move_up") and can_double_jump:
		can_double_jump = false
		double_jump_label.modulate.a = 0.5
		velocity.y += 1.1 * jump_speed
		
	#floor detection for ability activation and label alpha channel 100%
	if is_on_floor():
		can_double_jump = true
		can_downward_dash = true
		double_jump_label.modulate.a = 1.0
		stomp_label.modulate.a = 1.0
		
	#downward dash
	if !is_on_floor() and Input.is_action_just_pressed("move_down") and can_downward_dash:
		if sign(velocity.y) == sign(jump_speed): #if moving upward, reset velocity.y to 0 before applying downward dash velocity
			velocity.y = 0.0
		can_downward_dash = false
		stomp_label.modulate.a = 0.5
		velocity.y -= 2*jump_speed
		
	#horizontal dash
	if Input.is_action_just_pressed("move_dash") and can_dash:
		dash_label.modulate.a = 0.5
		if direction != 0.0: #dash in input direction
			velocity.x = velocity.x + (direction * dash_speed)
		elif abs(velocity.x) >= 5.0: #only dash without input if velocity.x above 5px/s 
			velocity.x = velocity.x + (sign(velocity.x) * dash_speed)
		can_dash = false
		get_tree().create_timer(2.0).timeout.connect( #2 second timeout for horizontal dash
			func(): 
				can_dash = true
				dash_label.modulate.a = 1.0
				)
	#character movement function
	move_and_slide()
