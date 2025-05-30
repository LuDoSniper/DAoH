extends Node

func _ready() -> void:
	var args = OS.get_cmdline_args()
	
	if "--server" in args:
		var world_scene = preload("res://scenes/world/world.tscn")
		var world = world_scene.instantiate()
		world.set_meta("server", true)
		get_tree().root.call_deferred("add_child", world)
		get_tree().call_deferred("set_current_scene", world)
		call_deferred("queue_free")
	else:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main/main.tscn")
