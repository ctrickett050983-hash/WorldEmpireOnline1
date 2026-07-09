extends Control

@onready var email_input: LineEdit = $Panel/EmailInput
@onready var password_input: LineEdit = $Panel/PasswordInput
@onready var status_label: Label = $Panel/StatusLabel
@onready var api_input: LineEdit = $Panel/ApiInput

const WORLD_MAP_SCENE := "res://scenes/WorldMap.tscn"

func _ready() -> void:
	api_input.text = Session.api_url
	$Panel/LoginButton.pressed.connect(login)
	$Panel/RegisterButton.pressed.connect(register)

func login() -> void:
	status_label.text = "Logging in..."
	send_auth_request("/api/auth/login")

func register() -> void:
	status_label.text = "Registering..."
	send_auth_request("/api/auth/register")

func send_auth_request(path: String) -> void:
	Session.api_url = api_input.text.strip_edges().trim_suffix("/")
	if email_input.text.strip_edges() == "" or password_input.text == "":
		status_label.text = "Enter email and password."
		return

	Api.request_finished.connect(_on_auth_done, CONNECT_ONE_SHOT)
	Api.post_json(path, {
		"email": email_input.text.strip_edges(),
		"password": password_input.text,
		"displayName": email_input.text.strip_edges().split("@")[0]
	})

func _on_auth_done(ok: bool, data: Variant, status: int, raw: String) -> void:
	if not ok or typeof(data) != TYPE_DICTIONARY or not data.has("token"):
		status_label.text = "Login/register failed (" + str(status) + "): " + raw
		return
	Session.token = data.token
	Session.user = data.get("user", {})
	status_label.text = "Connected. Loading world..."
	Api.request_finished.connect(_on_world_loaded, CONNECT_ONE_SHOT)
	Api.get_json("/api/world", Session.token)

func _on_world_loaded(ok: bool, data: Variant, status: int, raw: String) -> void:
	if not ok or typeof(data) != TYPE_DICTIONARY or not data.has("cities"):
		status_label.text = "World load failed (" + str(status) + "): " + raw
		return
	Session.last_world_data = data
	get_tree().change_scene_to_file(WORLD_MAP_SCENE)
