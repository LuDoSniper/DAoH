extends Node

func print_local(node: Node, message: String) -> void:
	print(node.get_tree(), " - ", multiplayer.get_unique_id(), ": ", message)

func custom_min(values: Array) -> int:
	var minimum = values[0]
	for value in values:
		if value < minimum:
			minimum = value
	
	return minimum
