extends ColorRect

@onready var collision_shape: CollisionShape2D = $"../CollisionShape2D"

func _ready() -> void:
	sync_with_collision_shape()

func sync_with_collision_shape() -> void:
	if not collision_shape:
		return
		
	var shape = collision_shape.shape as RectangleShape2D
	if shape:
		# 1. Match ColorRect size to the RectangleShape2D size
		size = shape.size
		
		# 2. Offset ColorRect position so it aligns with CollisionShape2D center
		# (CollisionShape2D is centered, ColorRect origin is top-left)
		position = collision_shape.position - (shape.size / 2.0)
