extends Node
class_name ApiClient

signal request_finished(ok: bool, data: Variant, status: int, raw: String)

func get_json(path: String, token: String = "") -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed.bind(http))
	var headers := PackedStringArray([])
	if token != "":
		headers.append("Authorization: Bearer " + token)
	var err := http.request(Session.api_url + path, headers, HTTPClient.METHOD_GET)
	if err != OK:
		emit_signal("request_finished", false, {"error":"request_not_sent","code":err}, 0, "")
		http.queue_free()

func post_json(path: String, payload: Dictionary, token: String = "") -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed.bind(http))
	var headers := PackedStringArray(["Content-Type: application/json"])
	if token != "":
		headers.append("Authorization: Bearer " + token)
	var err := http.request(Session.api_url + path, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		emit_signal("request_finished", false, {"error":"request_not_sent","code":err}, 0, "")
		http.queue_free()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	var raw := body.get_string_from_utf8()
	var data: Variant = JSON.parse_string(raw)
	var ok := response_code >= 200 and response_code < 300 and typeof(data) != TYPE_NIL
	emit_signal("request_finished", ok, data, response_code, raw)
