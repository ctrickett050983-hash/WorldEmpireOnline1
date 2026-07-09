extends Node

signal request_finished(ok: bool, data: Variant, status: int, context: String)

func post(path: String, payload: Dictionary, context: String = "") -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed.bind(http, context))
	var err := http.request(Session.api_url + path, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		request_finished.emit(false, {"error":"request_failed", "code":err}, 0, context)
		http.queue_free()

func get_json(path: String, context: String = "") -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed.bind(http, context))
	var headers: PackedStringArray = []
	if Session.token.length() > 0:
		headers.append("Authorization: Bearer " + Session.token)
	var err := http.request(Session.api_url + path, headers, HTTPClient.METHOD_GET)
	if err != OK:
		request_finished.emit(false, {"error":"request_failed", "code":err}, 0, context)
		http.queue_free()

func auth_post(path: String, payload: Dictionary, context: String = "") -> void:
	post(path, payload, context)

func authed_post(path: String, payload: Dictionary, context: String = "") -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed.bind(http, context))
	var headers := PackedStringArray(["Content-Type: application/json", "Authorization: Bearer " + Session.token])
	var err := http.request(Session.api_url + path, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		request_finished.emit(false, {"error":"request_failed", "code":err}, 0, context)
		http.queue_free()

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, context: String) -> void:
	var text := body.get_string_from_utf8()
	var data: Variant = {}
	if text.length() > 0:
		data = JSON.parse_string(text)
		if data == null:
			data = {"raw": text}
	var ok := response_code >= 200 and response_code < 300
	request_finished.emit(ok, data, response_code, context)
	http.queue_free()
