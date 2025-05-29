extends Node

func print_local(node: Node, message: String) -> void:
	print(node.get_tree(), ": ", message)
