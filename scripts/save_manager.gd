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
	print("save_game entered")
	print("save_game: dir = ", get_save_dir())
	var dir:= get_save_dir()
	var err := DirAccess.make_dir_recursive_absolute(dir)
	print("save_game: make_dir err = ", err)
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
	var path := dir.path_join("save" + "1" + SAVE_TYPE)
	print("save_game: writing to ", path)
	var file := FileAccess.open(dir.path_join("save" + "1" + SAVE_TYPE), FileAccess.WRITE)
	if file == null:
		print("save_game: open failed, error = ", FileAccess.get_open_error())
		push_error("Could not write save file (ERROR %d" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	print("save_game: done")

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
