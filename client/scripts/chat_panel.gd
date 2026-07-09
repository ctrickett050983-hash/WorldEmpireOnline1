extends Panel

@onready var chat_log: RichTextLabel = $ChatLog
@onready var chat_input: LineEdit = $ChatInput
@onready var send_button: Button = $SendButton

var socket := WebSocketPeer.new()
var connected := false

func _ready() -> void:
	send_button.pressed.connect(send_chat)
	chat_input.text_submitted.connect(func(_t): send_chat())
	connect_socket()

func connect_socket() -> void:
	var ws_url := Session.api_url.replace("http://", "ws://").replace("https://", "wss://") + "?token=" + Session.token
	var err := socket.connect_to_url(ws_url)
	if err != OK:
		append_line("[color=red]Chat connection failed.[/color]")
	else:
		append_line("[color=gray]Connecting chat...[/color]")

func _process(_delta: float) -> void:
	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not connected:
		connected = true
		append_line("[color=green]Chat connected.[/color]")
	while socket.get_available_packet_count() > 0:
		var raw := socket.get_packet().get_string_from_utf8()
		var data = JSON.parse_string(raw)
		if typeof(data) == TYPE_DICTIONARY:
			if data.get("type", "") == "chat":
				append_line("[b]" + str(data.get("name", "Player")) + ":[/b] " + str(data.get("message", "")))
			elif data.get("type", "") == "hello":
				append_line("[color=gray]Server hello received.[/color]")
			else:
				append_line("[color=gray]" + raw + "[/color]")

func send_chat() -> void:
	var text := chat_input.text.strip_edges()
	if text == "": return
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		append_line("[color=red]Chat is not connected.[/color]")
		return
	var city_id = Session.selected_city.get("id", null)
	socket.send_text(JSON.stringify({"type":"chat", "cityId": city_id, "message": text}))
	chat_input.text = ""

func append_line(line: String) -> void:
	chat_log.append_text(line + "\n")
