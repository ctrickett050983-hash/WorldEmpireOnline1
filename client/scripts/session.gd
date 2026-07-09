extends Node

const SAVE_PATH := "user://session_settings.json"

var api_url: String = "http://localhost:3000"
var token: String = ""
var user: Dictionary = {}
var last_world_data: Dictionary = {}
var selected_city: Dictionary = {}
var city_detail: Dictionary = {}
var player_cash: float = 0.0
var player_name: String = "Player"
var remember_me: bool = false
var saved_email: String = ""
var saved_password: String = ""

func _ready() -> void:
	load_local_settings()

func is_logged_in() -> bool:
	return token.length() > 0

func clear() -> void:
	token = ""
	user = {}
	last_world_data = {}
	selected_city = {}
	city_detail = {}
	player_cash = 0.0
	player_name = "Player"

func apply_login(data: Dictionary) -> void:
	token = str(data.get("token", ""))
	user = data.get("user", {})
	if typeof(user) != TYPE_DICTIONARY:
		user = {}
	player_name = str(user.get("display_name", user.get("email", "Player")))
	player_cash = float(user.get("cash", 0.0))

func save_local_settings() -> void:
	var data := {
		"api_url": api_url,
		"remember_me": remember_me,
		"saved_email": saved_email,
		"saved_password": saved_password if remember_me else ""
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_local_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	api_url = str(parsed.get("api_url", api_url))
	remember_me = bool(parsed.get("remember_me", false))
	saved_email = str(parsed.get("saved_email", ""))
	saved_password = str(parsed.get("saved_password", ""))

func logout() -> void:
	clear()
