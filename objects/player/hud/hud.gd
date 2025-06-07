extends CanvasLayer

@onready var health_bar = $MarginContainer/VBoxContainer/HealthBar
@onready var xp_bar = $MarginContainer/VBoxContainer/XPBar
@onready var money_label = $MarginContainer/VBoxContainer/TextureRect/HBoxContainer/Gold

func update_health(max, amount):
	health_bar.value = (amount / max) * 100

func update_xp(max, amount):
	xp_bar.value = (amount / max) * 100

func update_money(amount):
	money_label.text = "%d" % amount
