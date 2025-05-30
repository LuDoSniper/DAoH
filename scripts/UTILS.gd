extends Node

func print_local(node: Node, message: String) -> void:
	print(node.get_tree(), " - ", multiplayer.get_unique_id(), ": ", message)
