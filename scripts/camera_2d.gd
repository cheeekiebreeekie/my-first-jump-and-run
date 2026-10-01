extends Camera2D

@export var player: Player
@export var max_lead_distance: Vector2 = Vector2(960.0, 540.0)
@export var max_player_speed: Vector2 = Vector2(1200.0, 600.0) # Player's top running/falling speeds
@export var smoothness: float = 3.0 # Lower values increase heavy inertia/drag
@export var default_zoom: Vector2 = Vector2(1.0, 1.0)
@export var max_zoom: Vector2 = Vector2(0.5, 0.5)
@export var zoom_speed: float = 8.0
@export var camera_scale: Vector2 = Vector2(1, 1)

@onready var color_rect: ColorRect = $ColorRect
@onready var color_rect_position = color_rect.position

@onready var pause_Menu: pause_menu = $pauseMenu
@onready var pause_Menu_position = pause_Menu.position

@onready var resume: Button = %ResumeButton
@onready var resume_base_size = resume.size
@onready var resume_position = resume.position

@onready var settings: Button = %SettingsButton
@onready var settings_base_size = settings.size
@onready var settings_position = settings.position

@onready var save: Button = %SaveButton
@onready var save_base_size = save.size 
@onready var save_position = save.position

@onready var load_: Button = %LoadButton
@onready var load_base_size = load_.size
@onready var load_position = load_.position

@onready var exit: Button = %ExitButton
@onready var exit_base_size = exit.size
@onready var exit_position = exit.position

@onready var base_size: Vector2 = color_rect.size

var is_zoom: bool = true
var inputs_enabled: bool = true

var current_lead: Vector2 = Vector2.ZERO

func _ready() -> void:
	zoom = default_zoom;
	make_current()

func _process(delta: float) -> void:


	if not player:
		return

	# Calculate normalized speed ratios (0.0 to 1.0 based on player speed)
	var speed_ratio_x = clamp(abs(player.velocity.x) / max_player_speed.x, 0.0, 1.0)
	var speed_ratio_y = clamp(abs(player.velocity.y) / max_player_speed.y, 0.0, 1.0)

	# Target lead grows smoothly with velocity magnitude
	var target_lead = Vector2.ZERO
	target_lead.x = sign(player.velocity.x) * speed_ratio_x * max_lead_distance.x
	target_lead.y = sign(player.velocity.y) * speed_ratio_y * max_lead_distance.y

	# Exponential smoothing creates organic, weighted acceleration
	var blend: Vector2 = Vector2(0.0, 0.0)
	blend.x = 1.0 - exp(-smoothness * delta)
	blend.y = 1.0 - exp(-smoothness / 2 * delta)
	current_lead.x = lerp(current_lead.x, target_lead.x, blend.x)
	current_lead.y = lerp(current_lead.y, target_lead.y, blend.y)

	# Apply offset relative to local origin
	position.x = current_lead.x
	position.y = current_lead.y	

	# detect zoom
	if Input.is_action_just_pressed("middle_click") and inputs_enabled:
		if is_zoom == true:
			is_zoom = false
		elif is_zoom == false:
			is_zoom = true
	# Apply zoom
	if is_zoom:
		zoom = zoom.lerp(max_zoom, zoom_speed*delta)
	else:
		zoom = zoom.lerp(default_zoom, zoom_speed*delta)

	if color_rect:

		camera_scale = Vector2(1, 1) / zoom

		color_rect.scale = camera_scale
		pause_Menu.scale = camera_scale

		color_rect.position = color_rect_position * camera_scale

		pause_Menu.position = pause_Menu_position * camera_scale
