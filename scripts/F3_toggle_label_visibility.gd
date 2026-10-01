extends Label

@onready var camera = get_viewport().get_camera_2d()
@onready var self_position = self.position
@onready var self_font_size = self.get_theme_font_size("font_size")

func _process(_delta: float) -> void:
	if camera:
		self.scale = camera.camera_scale
		self.position = self_position / camera.zoom

func _unhandled_input(event: InputEvent) -> void:
	if self.name in ["DashLabel", "DoubleJumpLabel", "StompLabel"]:
		return
	if event.is_action_pressed("F3"):
		if (self.visible == true):
			self.visible = false
		else:
			self.visible = true
