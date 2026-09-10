extends Node2D

@onready var level_load_transition_rect: ColorRect = $LevelLoadTransition/ColorRect

func _start_level_transition(target_level_path: String) -> void:
	var shader_material = level_load_transition_rect.material as ShaderMaterial
	if not shader_material:
		push_error("No ShaderMaterial found on ColorRect!")
		return

	var camera = get_viewport().get_camera_2d()

	if camera and "is_zoom" in camera:
		camera.is_zoom = false

	ResourceLoader.load_threaded_request(target_level_path)

	var tween_in = create_tween()
	tween_in.tween_property(shader_material, "shader_parameter/progress", 1.0, 2.4)
	$Player.velocity = Vector2.ZERO
	$Player.set_physics_process(false)
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

	$Player.global_position = Vector2(0, -20)
	$Player.set_physics_process(true)
	camera.inputs_enabled = true

	var tween_out = create_tween()
	tween_out.tween_property(shader_material, "shader_parameter/progress", 0.0, 1.2)
