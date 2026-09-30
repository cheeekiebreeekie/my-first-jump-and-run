class_name pause_menu extends Control

@export var children : MarginContainer
@export var exitButton : Button
@export var resumeButton : Button
@export var player : Player
var run : bool = true;
var ui_enabled : bool = false
var camera

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = get_viewport().get_camera_2d()
	self.process_mode = Node.PROCESS_MODE_ALWAYS 
	disableUI()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


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
