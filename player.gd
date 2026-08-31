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
@export var acceleration: float = 600.0
@export var ground_friction: float = 3.0
@onready var horizontal_sprite_width = get_node("Sprite2D").texture.get_width()
@onready var vertical_sprite_width = get_node("Sprite2D").texture.get_height()
var max_power: float = 600.0
var jump_speed = -500.0
@export var dash_speed: float = 600.0
#densities in kg/cm³
var wood_density = 0.00087
var submersion_percent: float = 0.0
#friction variables
@export var air_friction = 0.5
@export var max_speed: float = 400
var friction_coefficient = 0.0
#density variables
var density_height_scale = 850000.0 #px as the standard height scale is 850000.0 cm
#get project gravity settings, should be 981px/s²
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
#enable abilities, needed to turn them off later
var can_jump = true
var can_double_jump = true
var can_dash = true
var can_downward_dash = true

func _physics_process(delta: float) -> void:
	#calculate character mass, calculated like a cuboid
	var character_size: float = horizontal_sprite_width * horizontal_sprite_width * vertical_sprite_width
	var character_mass: float = character_size * wood_density
	#gravity force
	var gravity_force: float = (character_mass * gravity)
	#current baromatric fluid density
	#baromatric approximation is rho = rho_0 * e^(-altitude / H) -altitude cause godot y is inversed
	var areas = $Area2D.get_overlapping_areas()
	if not areas.is_empty():
		#sort areas array by z_index so I don't have to set depth with attached scripts
		areas.sort_custom(func(a: Area2D, b: Area2D): return a.z_index > b.z_index)
		#get characters submerged size
		var character_bottom: float = global_position.y + (vertical_sprite_width / 2.0)
		var area_shape_node = areas[0].get_node("CollisionShape2D")
		var area_shape = area_shape_node.shape as RectangleShape2D
		if area_shape:
			var area_top_y: float = area_shape_node.global_position.y - (area_shape.size.y * 0.5 * area_shape_node.global_scale.y)
			var submerged_height: float = character_bottom - area_top_y
			submersion_percent = clamp(submerged_height / vertical_sprite_width, 0.0, 1.0)
	var current_fluid_density = areas[0].density if not areas.is_empty() else Densities.VACUUM
	var current_fluid_viscocity = areas[0].viscocity if not areas.is_empty() else Densities.VACUUM_VISCOCITY
	var current_density: float = current_fluid_density * exp(global_position.y / density_height_scale) if current_fluid_density == Densities.AIR else current_fluid_density
	#buyoncy 
	var character_submerged_size: float = character_size * submersion_percent
	var displaced_mass: float = current_density * character_submerged_size
	var effective_mass: float = character_mass + (0.8 * displaced_mass)
	var buyoncy: float = (current_density * character_submerged_size * gravity)
	#drag 
	var linear_drag = (-6.0 * PI * current_fluid_viscocity * (0.5 * (horizontal_sprite_width))) * velocity 
	var square_drag: Vector2 = (velocity.normalized() * -0.5 * current_density * velocity.length_squared() * 1.05 * (horizontal_sprite_width * horizontal_sprite_width)) if velocity.length() > 0 else Vector2.ZERO
	var total_drag: Vector2 = square_drag + linear_drag
	print(square_drag)
	#damping forces
	var damping_force: float = 0
	var slamming_force: float = 0
	if submersion_percent > 0.0 and submersion_percent < 1.0: 
		if abs(velocity.y) < 75.0:
			damping_force = velocity.y * (2 * sqrt(character_mass * (current_density * horizontal_sprite_width * gravity))) #critical damping force
		if velocity.y > 100.0:
			slamming_force = (PI / 4) * current_density * (horizontal_sprite_width * horizontal_sprite_width) * velocity.length_squared() #Wagners Hydrodynamic Impact Model
	#get X input direction and calculate force
	var direction := Input.get_axis("move_left", "move_right")
	var stall_force = acceleration * effective_mass
	var thrust_x: float = direction * min(stall_force, max_speed * stall_force / (max(abs(velocity.x), 2)))
	#friction
	if is_on_floor():
		var floor = get_last_slide_collision()
		if floor and "friction" in floor.get_collider():
			friction_coefficient = floor.get_collider().friction
		if abs(velocity.x) < 10.0 and direction == 0:
			velocity.x = 0.0
		if direction != 0 and sign(direction) != sign(velocity.x):
			friction_coefficient = friction_coefficient * 4
	else:
		friction_coefficient = 0.0
	var friction: float = sign(velocity.x) * friction_coefficient * (gravity_force - buyoncy)
	#apply all forces
	var total_vertical_force: Vector2 = Vector2(0.0, gravity_force - buyoncy - damping_force - slamming_force)
	var total_horizontal_force: Vector2 = Vector2( thrust_x - friction , 0.0)
	velocity += (total_vertical_force + total_horizontal_force + total_drag) / effective_mass * delta 
	#display velocityx
	var total_velocityx = round(velocity.x * 100) / 100
	var velocity_textx = "VelocityX: %spx/s"
	var actual_velocity_textx = velocity_textx % total_velocityx
	velocity_labelx.text = actual_velocity_textx
	#display velocityy
	var total_velocityy = round(velocity.y * 100) / 100
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
			velocity.y = 0
		can_downward_dash = false
		stomp_label.modulate.a = 0.5
		velocity.y -= 2*jump_speed
	#horizontal dash
	if Input.is_action_just_pressed("move_dash") and can_dash:
		dash_label.modulate.a = 0.5
		if direction != 0: #dash in input direction
			velocity.x = velocity.x + (direction * dash_speed)
		elif abs(velocity.x) >= 5: #only dash without input if velocity.x above 5px/s 
			velocity.x = velocity.x + (sign(velocity.x) * dash_speed)
		can_dash = false
		get_tree().create_timer(2).timeout.connect( #2 second timeout for horizontal dash
			func(): 
				can_dash = true
				dash_label.modulate.a = 1
				)
#character movement function
	move_and_slide()
