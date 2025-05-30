extends CharacterBody3D

@onready var area: Area3D = $Area3D
@onready var label: Label3D = $Label3D
@export var npc_name: String = "CACA"

# Dialogue de test
var dialogue_lines: Array[String] = [
	"Salut, aventurier !",
	"Bienvenue dans le monde de Godoria.",
	"Bonne chance pour ta quête !"
]

func _ready():
	label.text = npc_name
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("players") and body.is_multiplayer_authority():
		label.show()
		body.set_current_npc(self)

func _on_body_exited(body):
	if body.is_in_group("players") and body.is_multiplayer_authority():
		label.hide()
		body.set_current_npc(null)


func get_dialogue_lines():
	return dialogue_lines
