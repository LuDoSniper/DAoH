extends CanvasLayer

@onready var health_bar = $MarginContainer/VBoxContainer/HealthBar
@onready var xp_bar = $MarginContainer/VBoxContainer/XPBar
@onready var money_label = $MarginContainer/VBoxContainer/TextureRect/HBoxContainer/Gold
@onready var death_screen: Control = $DeathScreen
@onready var respawn: Button = $DeathScreen/respawn
@onready var timer: Timer = $DeathScreen/Timer
@onready var animation_player: AnimationPlayer = $DeathScreen/AnimationPlayer

func _ready() -> void:
	hide_death()
	respawn.hide()

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

func show_death() -> void:
	animation_player.play("show_death")
	timer.wait_time = 3.0
	timer.start()

func hide_death() -> void:
	death_screen.modulate.a = 0
	respawn.hide()

func _on_respawn_pressed() -> void:
	hide_death()
	get_parent().get_parent().respawn()

func _on_timer_timeout() -> void:
	respawn.show()
