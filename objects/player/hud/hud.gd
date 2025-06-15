extends CanvasLayer

@onready var health_bar = $MarginContainer/VBoxContainer/HealthBar
@onready var xp_bar = $MarginContainer/VBoxContainer/XPBar
@onready var money_label = $MarginContainer/VBoxContainer/TextureRect/HBoxContainer/Gold
@onready var death_screen: Control = $DeathScreen
@onready var respawn: Button = $DeathScreen/respawn
@onready var timer: Timer = $DeathScreen/Timer
@onready var animation_player: AnimationPlayer = $DeathScreen/AnimationPlayer
@onready var emote_container: VBoxContainer = $EmoteWheel/ScrollContainer/EmoteContainer
@onready var emote_wheel: Control = $EmoteWheel

var emotes = [
	"Cheer",
	"Interact",
	"Use_Item"
]

func _ready() -> void:
	hide_death()
	respawn.hide()
	emote_wheel.hide()
	update_emote_wheel()

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

func toggle_emote_wheel() -> void:
	emote_wheel.visible = not emote_wheel.visible
	if emote_wheel.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func update_emote_wheel() -> void:
	for child in emote_container.get_children():
		child.queue_free()
	
	for emote in emotes:
		var button = Button.new()
		emote_container.add_child(button)
		button.text = emote
		button.pressed.connect(func(): _on_emote_button_pressed(emote))

func _on_emote_button_pressed(emote: String) -> void:
	emote_wheel.hide()
	get_parent().get_parent().play_emote(emote)
