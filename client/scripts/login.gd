extends Control

@onready var email_input: LineEdit = $Panel/EmailInput
@onready var password_input: LineEdit = $Panel/PasswordInput
@onready var status_label: Label = $Panel/StatusLabel

const WORLD_SCENE := "res://scenes/World.tscn"
var api_url := "http://localhost:3000"
var token := ""

func _ready() -> void:
	$Panel/LoginButton.pressed.connect(login)
	$Panel/RegisterButton.pressed.connect(register)

func login() -> void:
	status_label.text = "Logging in..."
	send_auth_request("/api/auth/login")

func register() -> void:
	status_label.text = "Registering..."
	send_auth_request("/api/auth/register")

func send_auth_request(path: String) -> void:
	if email_input.text.strip_edges() == "" or password_input.text == "":
		status_label.text = "Enter email and password."
		return

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_auth_done.bind(http))

	var body := JSON.stringify({
		"email": email_input.text.strip_edges(),
		"password": password_input.text,
		"displayName": email_input.text.strip_edges()
	})

	var err := http.request(
		api_url + path,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		body
	)
	if err != OK:
		status_label.text = "Request failed before sending. Error: " + str(err)

func _on_auth_done(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	var text := body.get_string_from_utf8()
	var data = JSON.parse_string(text)

	if response_code != 200 or typeof(data) != TYPE_DICTIONARY or not data.has("token"):
		status_label.text = "Login/register failed: " + text
		return

	token = data.token
	status_label.text = "Connected. Loading world..."
	load_world()

func load_world() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_world_loaded.bind(http))

	var err := http.request(
		api_url + "/api/world",
		["Authorization: Bearer " + token],
		HTTPClient.METHOD_GET
	)
	if err != OK:
		status_label.text = "World request failed before sending. Error: " + str(err)

func _on_world_loaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	var text := body.get_string_from_utf8()
	var data = JSON.parse_string(text)

	if response_code != 200 or typeof(data) != TYPE_DICTIONARY:
		status_label.text = "World load failed: " + text
		return

	Session.api_url = api_url
	Session.token = token
	Session.last_world_data = data
	get_tree().change_scene_to_file(WORLD_SCENE)
