extends Node

signal message_received(data: Dictionary)
signal connection_changed(connected: bool)

var socket := WebSocketPeer.new()
var connected := false

func connect_to_server() -> void:
	if Session.token.is_empty():
		return
	var ws_url := Session.api_url.replace("http://", "ws://").replace("https://", "wss://") + "/?token=" + Session.token.uri_encode()
	var err := socket.connect_to_url(ws_url)
	connected = err == OK
	connection_changed.emit(connected)

func _process(_delta: float) -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		if connected:
			connected = false
			connection_changed.emit(false)
		return
	socket.poll()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN and not connected:
		connected = true
		connection_changed.emit(true)
	while socket.get_available_packet_count() > 0:
		var text := socket.get_packet().get_string_from_utf8()
		var data = JSON.parse_string(text)
		if typeof(data) == TYPE_DICTIONARY:
			message_received.emit(data)

func send_chat(city_id: String, message: String) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var payload := {"type":"chat", "cityId": city_id, "message": message}
	socket.send_text(JSON.stringify(payload))
