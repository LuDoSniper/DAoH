extends Node3D
@export var text: String = "TEST"
@onready var label_3d: Label3D = $Label3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label_3d.text = text
