extends Node3D

@onready var knight: Node3D = $Skins/Knight
@onready var barbarian: Node3D = $Skins/Barbarian
@onready var mage: Node3D = $Skins/Mage
@onready var rogue: Node3D = $Skins/Rogue
@onready var label: Label = $ClassMenu/Panel/Bandeau/Label
@onready var rich_text_label: RichTextLabel = $ClassMenu/Panel/RichTextLabel

@onready var chevalier_button: Button = $ClassMenu/Classes/left/Chevalier
@onready var barbare_button: Button = $ClassMenu/Classes/left/Barbare
@onready var voleur_button: Button = $ClassMenu/Classes/right/Voleur
@onready var mage_button: Button = $ClassMenu/Classes/right/Mage

var panel_selected = preload("res://addons/menu/round_damaged_brown.png")
var panel = preload("res://addons/menu/round_damaged_brown_dark.png")

var selected_stylebox = StyleBoxTexture.new()
var default_stylebox = StyleBoxTexture.new()

var is_hosting: bool = false

var description = {
	"Chevalier": "Noble guerrier en armure lourde, le Chevalier incarne l'honneur et la défense. Il manie l’épée et le bouclier avec brio, protégeant ses alliés et tenant la ligne face à l’ennemi. Grâce à sa robustesse et ses compétences défensives, il est le pilier de toute escouade.",
	"Voleur": "Rapide, agile et rusé, le Voleur frappe dans l’ombre avant de disparaître. Maître des attaques critiques et de l’évasion, il utilise dagues, poisons et techniques de furtivité pour éliminer ses cibles sans être vu. L’ennemi ne le voit jamais venir.",
	"Mage": "Maître des arcanes, le Mage puise son pouvoir dans les éléments. Qu’il déchaîne le feu, le givre ou la foudre, il inflige des dégâts massifs à distance. Bien qu’il soit fragile, sa puissance mystique peut renverser le cours d’une bataille en un instant.",
	"Barbare": "Furie incarnée, le Barbare est une brute sauvage qui charge dans la mêlée sans crainte. Armé de haches ou de massues, il utilise sa rage pour infliger des dégâts colossaux. Plus il est blessé, plus il devient dangereux. Il est la tempête dans le chaos du champ de bataille."
}

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_knight_pressed() -> void:
	_update_skin("knight")

func _on_barbarian_pressed() -> void:
	_update_skin("barbarian")

func _on_rogue_pressed() -> void:
	_update_skin("rogue")

func _on_mage_pressed() -> void:
	_update_skin("mage")

func _update_skin(skin):
	selected_stylebox.texture = panel_selected
	default_stylebox.texture = panel
	knight.visible = false
	barbarian.visible = false
	mage.visible = false
	rogue.visible = false
	
	update_theme(chevalier_button, default_stylebox)
	update_theme(barbare_button, default_stylebox)
	update_theme(voleur_button, default_stylebox)
	update_theme(mage_button, default_stylebox)
	
	if skin == "knight":
		knight.visible = true
		label.text = "Chevalier"
		update_theme(chevalier_button, selected_stylebox)
	elif skin == "barbarian":
		barbarian.visible = true
		label.text = "Barbare"
		update_theme(barbare_button, selected_stylebox)
	elif skin == "mage":
		mage.visible = true
		label.text = "Mage"
		update_theme(mage_button, selected_stylebox)
	elif skin == "rogue":
		rogue.visible = true
		label.text = "Voleur"
		update_theme(voleur_button, selected_stylebox)
	rich_text_label.text = description[label.text]


func _on_host_pressed() -> void:
	is_hosting = true
	_start_game()


func _on_rejoindre_pressed() -> void:
	is_hosting = false
	_start_game()


func _start_game():
	var world_scene = preload("res://scenes/world/world.tscn")
	var world = world_scene.instantiate()
	world.set_meta("is_hosting", is_hosting)
	get_tree().root.add_child(world)
	queue_free()

func update_theme(button, texture):
	button.add_theme_stylebox_override("normal", texture)
	button.add_theme_stylebox_override("hover", texture)
	button.add_theme_stylebox_override("pressed", texture)
	button.add_theme_stylebox_override("focus", texture)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/home/home_menu.tscn")
