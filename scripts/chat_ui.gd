extends CanvasLayer

@onready var chat_panel 					= $ChatPanel
@onready var message_input: LineEdit 		= $ChatPanel/VBoxContainer/ContainerInput/MessageInput
@onready var message_container: VBoxContainer = $ChatPanel/VBoxContainer/Container/ScrollContainer/MessageContainer
@onready var auto_hide_timer: Timer 		= $FermetureAutomatique

"""
func _process(delta):
	if auto_hide_timer.is_stopped():
		return

	print("Temps restant :", auto_hide_timer.time_left)
"""

func _ready():
	chat_panel.visible 		= false
	message_input.visible 	= true
	message_input.text 		= ""

func _input(event):
	if event.is_action_pressed("open_chat") and (!chat_panel.visible or !GameState.chat_active):
		chat_panel.visible = !chat_panel.visible
		if chat_panel.visible:
			GameState.chat_active 	= true
			message_input.visible 	= true
			get_viewport().set_input_as_handled()
			message_input.grab_focus()
			auto_hide_timer.stop()
		else:
			GameState.chat_active = false
			auto_hide_timer.stop()
	if event.is_action_pressed("pause") and chat_panel.visible:
		print("_input()")
		print(GameState.chat_active)
		chat_panel.visible = !chat_panel.visible
		GameState.chat_active = false
		auto_hide_timer.stop()

func _on_message_input_text_submitted(new_text: String) -> void:
	new_text = new_text.strip_edges()
	if new_text != "":
		var label 					= Label.new()
		label.text 					= new_text
		label.autowrap_mode 		= TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		#print("Ajout message :", new_text)
		message_container.add_child(label)
		message_input.text 		= ""
		message_input.visible 	= false

		await get_tree().process_frame
		_scroll_to_bottom()
		
		GameState.chat_active	= false
		auto_hide_timer.start()

func _scroll_to_bottom():
	var scroll 				= $ChatPanel/VBoxContainer/Container/ScrollContainer
	var content_height 		= message_container.get_combined_minimum_size().y
	var viewport_height 	= scroll.get_size().y
	scroll.scroll_vertical 	= content_height - viewport_height


func _on_fermeture_automatique_timeout() -> void:
	chat_panel.visible 		= false
	message_input.visible 	= false
	GameState.chat_active 	= false
