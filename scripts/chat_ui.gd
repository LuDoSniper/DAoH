extends CanvasLayer

@onready var chat_panel = $ChatPanel
@onready var message_input: LineEdit = $ChatPanel/VBoxContainer/ContainerInput/MessageInput
@onready var message_container: VBoxContainer = $ChatPanel/VBoxContainer/Container/ScrollContainer/MessageContainer
@onready var auto_hide_timer: Timer = $FermetureAutomatique

func _ready():
	chat_panel.hide()
	message_input.show()
	message_input.text = ""

func _input(event):
	if event.is_action_pressed("open_chat") and (!chat_panel.visible or !GameState.chat_active):
		chat_panel.show()
		if chat_panel.visible:
			GameState.chat_active = true
			message_input.show()
			get_viewport().set_input_as_handled()
			message_input.grab_focus()
			auto_hide_timer.stop()
		else:
			GameState.chat_active = false
			auto_hide_timer.stop()
	if event.is_action_pressed("pause") and chat_panel.visible:
		GameState.ignore_pause = true
		chat_panel.hide()
		GameState.chat_active = false
		auto_hide_timer.stop()

func _on_message_input_text_submitted(new_text: String) -> void:
	send_message(new_text)

func send_message(message: String, origin: int = multiplayer.get_unique_id(), prompt: bool = true) -> void:
	if not multiplayer.is_server():
		if message != "":
			UTILS.print_local(self, "I AM REQUESTING A SENDING : " + message)
			rpc_id(1, "_request_send_message", origin, message, prompt)
		else:
			auto_hide_timer.start()
	else:
		_request_send_message(origin, message, prompt)

@rpc("any_peer")
func _request_send_message(id: int, message: String, prompt: bool = true) -> void:
	if multiplayer.is_server():
		UTILS.print_local(self, "I AM RECEIVING A REQUEST : " + message + " FROM : " + str(id))
		rpc("_remote_recieve_message", id, message, prompt)

@rpc("any_peer")
func _remote_recieve_message(id: int, message: String, prompt: bool = true) -> void:
	if not multiplayer.is_server():
		UTILS.print_local(self, "I AM RECEIVING A MESSAGE : " + message)
		
		#var prompt_str = "[" + str(id) + "]: " if prompt else ""
		var prompt_str = "[" + MULTIPLAYER.get_character_name_by_peer_id(id) + "]: " if prompt else ""

		message = prompt_str + message.strip_edges()
		
		var label = Label.new()
		label.text = message
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		message_container.add_child(label)
		message_input.text = ""
		message_input.hide()

		await get_tree().process_frame
		_scroll_to_bottom()
		GameState.chat_active = false
		
		chat_panel.show()
		auto_hide_timer.start()

func _scroll_to_bottom():
	var scroll = $ChatPanel/VBoxContainer/Container/ScrollContainer
	var content_height = message_container.get_combined_minimum_size().y
	var viewport_height = scroll.get_size().y
	scroll.scroll_vertical = content_height - viewport_height

func _on_fermeture_automatique_timeout() -> void:
	chat_panel.hide()
	message_input.hide()
	GameState.chat_active = false
