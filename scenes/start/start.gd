extends Node

func _ready() -> void:
	var args = OS.get_cmdline_args()
	
	if "--server" in args:
		var world_scene = preload("res://scenes/world/world.tscn")
		var world = world_scene.instantiate()
		world.set_meta("server", true)
		get_tree().root.add_child(world)
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/menu/home/home_menu.tscn")
