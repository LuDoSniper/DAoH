extends CanvasLayer

@onready var health_bar = $MarginContainer/VBoxContainer/HealthBar
@onready var xp_bar = $MarginContainer/VBoxContainer/XPBar
@onready var money_label = $MarginContainer/VBoxContainer/TextureRect/HBoxContainer/Gold

func update_health(value: float):
	health_bar.value = value

func update_xp(value: float):
	xp_bar.value = value

func update_money(amount):
	money_label.text = "%d" % amount
