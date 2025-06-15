extends CanvasLayer

@onready var health_bar = $MarginContainer/VBoxContainer/HealthBar
@onready var xp_bar = $MarginContainer/VBoxContainer/XPBar
@onready var money_label = $MarginContainer/VBoxContainer/TextureRect/HBoxContainer/Gold

func update_health(value: float):
	var tween = create_tween()
	tween.tween_method(tween_health, health_bar.value, value, 0.25)

func tween_health(value: float) -> void:
	health_bar.value = value

func update_xp(value: float):
	var tween = create_tween()
	tween.tween_method(tween_health, xp_bar.value, value, 0.25)

func xp_health(value: float) -> void:
	xp_bar.value = value

func update_money(amount):
	money_label.text = "%d" % amount
