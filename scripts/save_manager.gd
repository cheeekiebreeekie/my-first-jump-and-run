extends Node

const DEFAULT_SAVE_NAME = "default_save"
const SAVE_PATH = "save"
const SAVE_TYPE = ".json"

func get_save_dir() -> String:
	var base: String
	if OS.has_feature("editor"):
		base = ProjectSettings.globalize_path("res://")
	else:
		base = OS.get_executable_path().get_base_dir().get_base_dir()
	return base.path_join(SAVE_PATH)

func save_game(level: String, density: String, pos: Vector2, vel: Vector2) -> void:
	var dir:= get_save_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var data := {
		"level": level,
		"density": density,
		"position": {
			"x": pos.x,
			"y": pos.y
		},
		"velocity": {
			"x": vel.x,
			"y": vel.y
		}
	}
	var file := FileAccess.open(dir.path_join("save" + "1" + SAVE_TYPE), FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file (ERROR %d" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))

func load_game() -> void:
	var level_root := get_tree().current_scene
	var path := get_save_dir().path_join("save" + "1" + SAVE_TYPE)
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		return
	var level := String(data["level"])
	var density := String(data["density"])
	var pos := Vector2(data["position"]["x"], data["position"]["y"])
	var vel := Vector2(data["velocity"]["x"], data["velocity"]["y"])
	await level_root._start_level_transition(level, density, pos, vel, true)
