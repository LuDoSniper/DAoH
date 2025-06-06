extends CanvasLayer

@onready var health_bar = $VBoxContainer/HealthBar
@onready var xp_bar = $VBoxContainer/XPBar
@onready var money_label = $VBoxContainer/MoneyLabel
@onready var compass_needle = $TextureRect

func update_health(max, amount):
	health_bar.value = (amount / max) * 100

func update_xp(max, amount):
	xp_bar.value = (amount / max) * 100

func update_money(amount):
	money_label.text = "💰 %d" % amount
