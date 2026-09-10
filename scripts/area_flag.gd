extends Area2D

@export_file("*.tscn") var next_level_path: String

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player") or body.name == "Player":
        var main_node = get_tree().root.get_node("main")
        main_node._start_level_transition(next_level_path)