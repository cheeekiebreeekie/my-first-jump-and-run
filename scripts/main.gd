extends Node2D

@onready var level_load_transition_rect: ColorRect = $LevelLoadTransition/ColorRect
@onready var pause_Menu : pause_menu = %pauseMenu
@onready var tween_speed : float

func _start_level_transition(
	target_level_path: String,
	density : String = "oak",
	pos : Vector2 = Vector2(0, -64),
	vel : Vector2 = Vector2(0, 0),
	jump_timer : float = 0.0,
	can_double_jump : bool = true,
	can_downward_dash : bool = true,
	dash_timer : float = 0.0,
	is_load: bool = false
	) -> void:

	var shader_material = level_load_transition_rect.material as ShaderMaterial

	if is_load:
		tween_speed = 0.1
	else:
		tween_speed = 2.4 

	if not shader_material:
		push_error("No ShaderMaterial found on ColorRect!")
		return

	$Player.velocity = Vector2(0, 0)

	var camera = get_viewport().get_camera_2d()
	if camera && "is_zoom" in camera:
		if !is_load:
			camera.is_zoom = false
		else:
			camera.is_zoom = true
			camera.set_process(false)
			camera.position = Vector2(0, 0);

	ResourceLoader.load_threaded_request(target_level_path)

	var tween_in = create_tween()
	tween_in.tween_property(shader_material, "shader_parameter/progress", 1.0, tween_speed)
	#pause actions

	$Player.set_frame_skip(true)
	$Player.set_physics_process(false)

	pause_Menu.run = false
	camera.inputs_enabled = false
	await tween_in.finished

	while ResourceLoader.load_threaded_get_status(target_level_path) != ResourceLoader.THREAD_LOAD_LOADED:
		await get_tree().process_frame

	var old_level = get_tree().get_first_node_in_group("level")
	if old_level:
		old_level.queue_free()

	var new_level_resource = ResourceLoader.load_threaded_get(target_level_path)
	var new_level = new_level_resource.instantiate()
	add_child(new_level)
	move_child(new_level, 0)

	$Player.global_position = pos
	$Player.velocity = vel

	var tween_out = create_tween()
	tween_out.tween_property(shader_material, "shader_parameter/progress", 0.0, 0.5 * tween_speed)
	await tween_out.finished

	$Player.set_character_material(density)
	$Player.set_jump_timer(jump_timer)
	$Player.set_can_double_jump(can_double_jump)
	$Player.set_can_downward_dash(can_downward_dash)
	$Player.set_dash_timer(dash_timer)

	$Player.set_frame_skip(true)
	$Player.set_physics_process(true)

	camera.inputs_enabled = true
	pause_Menu.run = true

	if camera and "is_zoom" in camera:
		camera.is_zoom = true
		camera.set_process(true)
