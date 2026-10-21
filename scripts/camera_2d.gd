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

		color_rect.position = color_rect_position * camera_scale
