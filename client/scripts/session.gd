extends Node

var api_url: String = "http://localhost:3000"
var token: String = ""
var user: Dictionary = {}
var last_world_data: Dictionary = {}
var selected_city: Dictionary = {}
var selected_city_detail: Dictionary = {}
var character: Dictionary = {}

func is_logged_in() -> bool:
	return token != ""

func auth_headers() -> PackedStringArray:
	return PackedStringArray(["Authorization: Bearer " + token])

func json_headers() -> PackedStringArray:
	return PackedStringArray(["Content-Type: application/json"])

func reset() -> void:
	token = ""
	user = {}
	last_world_data = {}
	selected_city = {}
	selected_city_detail = {}
	character = {}
