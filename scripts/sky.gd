extends Area2D

var density = Densities.AIR
var viscocity = Densities.AIR_VISCOCITY

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("fluids")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
