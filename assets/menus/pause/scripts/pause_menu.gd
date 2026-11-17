class_name pause_menu extends Control

@export var children : MarginContainer
@export var exitButton : Button
@export var resumeButton : Button
@export var player : Player
var run : bool = true;
var ui_enabled : bool = false
var camera
var in_controls : bool = false
@export var camera_scale: Vector2 = Vector2(1, 1)
@export var default_zoom: Vector2 = Vector2(1.0, 1.0)

@onready var color_rect: ColorRect = $"../Player/Camera2D/ColorRect"
@onready var color_rect_position = color_rect.position

@onready var pause_Menu: pause_menu = %pauseMenu
@onready var pause_Menu_position = pause_Menu.position

@onready var resume: Button = %ResumeButton
@onready var settings: Button = %ControlsButton
@onready var save: Button = %SaveButton
@onready var load_: Button = %LoadButton
@onready var exit: Button = %ExitButton

@onready var moveup := %MoveUp
@onready var movedown := %MoveDown
@onready var moveleft := %MoveLeft
@onready var moveright := %MoveRight

@onready var base_size: Vector2 = color_rect.size

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = get_viewport().get_camera_2d()
	self.process_mode = Node.PROCESS_MODE_ALWAYS 
	disableUI()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if color_rect:

		camera_scale = Vector2(1, 1) / camera.zoom

		pause_Menu.scale = camera_scale

		var target_position = camera.global_position - (pause_Menu.size / 2) * camera_scale

		if in_controls:
			pause_Menu.position = pause_Menu.position.lerp(target_position - Vector2(1920, 0) * camera_scale, (1.0 - exp(-4 * delta)))
			return

		pause_Menu.position = target_position


func _input(event):
	if event.is_action_pressed("pause"):
		if ui_enabled:
			disableUI()
		else:
			enableUI()


func enableUI() -> void:
	if (!run):
		return
	ui_enabled = true
	player.set_physics_process(false)
	camera.set_process(false)
	camera.inputs_enabled = false
	self.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func disableUI() -> void:
	if (!run):
		return
	ui_enabled = false
	in_controls = false
	player.set_physics_process(true)
	camera.set_process(true)
	camera.inputs_enabled = true
	self.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func exitGame() -> void:
	get_tree().quit()


func _on_resume_pressed() -> void:
	ui_enabled = false
	disableUI()


func _on_exit_pressed() -> void:
	exitGame()


func _on_resume_button_down() -> void:
	pass # Replace with function body.

func _on_save_pressed() -> void:
	var level := get_tree().get_first_node_in_group("level")
	if level == null:
		return
	await save_manager.save_game(
		level.scene_file_path,
		player.get_character_material(), 
		player.global_position, 
		player.velocity,
		player.get_jump_timer(),
		player.get_can_double_jump(),
		player.get_can_downward_dash(),
		player.get_dash_timer()
	)
	disableUI()

func _on_load_pressed() -> void:
	await save_manager.load_game()
	disableUI()

func keycode_helper(function: String) -> int:
	var array := InputMap.action_get_events(function)
	if array[0] is InputEventKey:
		var keycode := int((array[0] as InputEventKey).physical_keycode)
		return keycode
	else:
		return 0

func render_helper(node:Node, keycode:int) -> void:
	node.get_node("Button").text = OS.get_keycode_string(keycode) if keycode != 0 else "ERROR"

func render_controls() -> void:

	var controls := {
		"move_up": moveup,
		"move_down": movedown,
		"move_left": moveleft,
		"move_right": moveright,
	}

	for action in controls:
		render_helper(controls[action], keycode_helper(action))

func _on_controls_pressed() -> void:

	render_controls();

	if in_controls:
		in_controls = false
	else:
		in_controls = true
