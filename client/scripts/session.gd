extends Node

var api_url: String = "http://localhost:3000"
var token: String = ""
var user: Dictionary = {}
var last_world_data: Dictionary = {}
var selected_city: Dictionary = {}
var city_detail: Dictionary = {}
var player_cash: float = 0.0
var player_name: String = "Player"

func is_logged_in() -> bool:
	return token.length() > 0

func clear() -> void:
	token = ""
	user = {}
	last_world_data = {}
	selected_city = {}
	city_detail = {}
