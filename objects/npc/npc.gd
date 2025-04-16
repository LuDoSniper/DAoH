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

var player_in_range := false
var current_line := 0

func _ready():
	print("READY")
	label.text = npc_name
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("players"):
		player_in_range = true
		print("Le joueur peut interagir avec", npc_name)

func _on_body_exited(body):
	if body.is_in_group("players"):
		player_in_range = false
		current_line = 0

func _unhandled_input(event):
	if player_in_range and event.is_action_pressed("interact"):
		DIALOGUEUI.show_dialogue(npc_name, dialogue_lines)

func show_next_dialogue():
	if current_line < dialogue_lines.size():
		print(npc_name + ": " + dialogue_lines[current_line])
		current_line += 1
	else:
		print(npc_name + ": Fin de la discussion.")
		current_line = 0
