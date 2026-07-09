extends Node

var api_url: String = "http://localhost:3000"
var token: String = ""
var user = {}
var player = {}
var current_character = {}
var current_city = {}
var last_world_data = {}

func is_logged_in() -> bool:
	return token != ""

func clear() -> void:
	token = ""
	user = {}
	player = {}
	current_character = {}
	current_city = {}
	last_world_data = {}
