extends Node3D

var player: CharacterBody3D
var camera_pivot: Node3D
var hud: CanvasLayer
var prompt_label: Label
var info_label: Label
var phone_panel: PanelContainer
var property_panel: PanelContainer
var chat_panel: PanelContainer
var chat_log: RichTextLabel
var chat_input: LineEdit
var nearest_property: Dictionary = {}
var property_nodes: Dictionary = {}
var speed := 6.0
var sprint_speed := 10.0
var velocity_y := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_build_city()
	_build_player()
	_build_hud()
	Realtime.message_received.connect(_on_realtime_message)
	API.request_finished.connect(_on_api_done)
	_refresh_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.003)
		camera_pivot.rotate_x(-event.relative.y * 0.003)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-35), deg_to_rad(55))
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("phone"):
		_toggle_phone()
	if event.is_action_pressed("chat"):
		chat_panel.visible = true
		chat_input.grab_focus()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("interact") and not nearest_property.is_empty():
		_show_property_panel(nearest_property)

func _physics_process(delta: float) -> void:
	if player == null: return
	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	input_dir = input_dir.normalized()
	var basis := global_transform.basis
	var dir := (basis.x * input_dir.x + basis.z * input_dir.z).normalized()
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else speed
	player.velocity.x = dir.x * target_speed
	player.velocity.z = dir.z * target_speed
	if player.is_on_floor():
		velocity_y = 0.0
		if Input.is_action_just_pressed("jump"):
			velocity_y = 7.0
	else:
		velocity_y -= 18.0 * delta
	player.velocity.y = velocity_y
	player.move_and_slide()
	_update_nearest_property()

func _build_city() -> void:
	var sun := DirectionalLight3D.new(); sun.light_energy = 2.5; sun.rotation_degrees = Vector3(-45, -35, 0); add_child(sun)
	var world := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.58,0.74,0.93); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.8,0.85,0.9); env.ambient_light_energy = 0.8; world.environment = env; add_child(world)
	_create_box("Ground", Vector3(80,0.2,80), Vector3(0,-0.1,0), Color(0.16,0.42,0.25))
	_create_road(Vector3(0,0.02,0), Vector3(80,0.08,8))
	_create_road(Vector3(0,0.03,0), Vector3(8,0.08,80))
	for i in range(-4,5):
		_create_box("StreetLight", Vector3(0.25,4,0.25), Vector3(i*8,2,-5), Color(1,0.9,0.55))
		_create_box("Tree", Vector3(0.5,3,0.5), Vector3(i*8,1.5,6), Color(0.22,0.12,0.05))
		_create_box("TreeTop", Vector3(2.2,2.2,2.2), Vector3(i*8,4,6), Color(0.08,0.38,0.14))

	var props: Array = Session.city_detail.get("properties", [])
	var idx := 0
	for p in props:
		var x := -30.0 + float(idx % 5) * 15.0
		var z := -25.0 + float(idx / 5) * 18.0
		var height := 5.0 + float(idx % 3) * 2.0
		var color := Color(0.35 + float(idx%4)*0.08, 0.35, 0.45 + float(idx%3)*0.1)
		var building := _create_box(str(p.get("name","Property")), Vector3(8,height,8), Vector3(x,height/2.0,z), color)
		building.set_meta("property", p)
		property_nodes[str(p.get("id",""))] = building
		_create_sign(str(p.get("name","Property")), Vector3(x,height+1.2,z-4.3), p)
		idx += 1
	if props.is_empty():
		for i in range(10):
			_create_box("Placeholder Building", Vector3(8,6,8), Vector3(-30 + (i%5)*15,3,-20+(i/5)*20), Color(0.4,0.42,0.5))

func _create_road(pos: Vector3, size: Vector3) -> void:
	_create_box("Road", size, pos, Color(0.055,0.06,0.07))

func _create_box(n: String, size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = n; body.position = pos; add_child(body)
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = size; mesh.mesh = box
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.roughness = 0.75; mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size; col.shape = shape; body.add_child(col)
	return body

func _create_sign(text: String, pos: Vector3, prop: Dictionary) -> void:
	var label := Label3D.new(); label.text = text + "\n£" + str(prop.get("value",0)); label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; label.position = pos; label.modulate = Color.WHITE; add_child(label)

func _build_player() -> void:
	player = CharacterBody3D.new(); player.name = "Player"; player.position = Vector3(0,1,16); add_child(player)
	var mesh := MeshInstance3D.new(); var capsule := CapsuleMesh.new(); capsule.height=1.8; capsule.radius=0.35; mesh.mesh=capsule
	var mat := StandardMaterial3D.new(); mat.albedo_color=Color(0.1,0.55,1.0); mesh.material_override=mat; player.add_child(mesh)
	var col := CollisionShape3D.new(); var shape := CapsuleShape3D.new(); shape.height=1.8; shape.radius=0.35; col.shape=shape; player.add_child(col)
	camera_pivot = Node3D.new(); camera_pivot.position = Vector3(0,1.4,0); player.add_child(camera_pivot)
	var spring := SpringArm3D.new(); spring.spring_length = 6.0; spring.position = Vector3(0,0.7,0); camera_pivot.add_child(spring)
	var cam := Camera3D.new(); cam.current = true; spring.add_child(cam)

func _build_hud() -> void:
	hud = CanvasLayer.new(); add_child(hud)
	info_label = Label.new(); info_label.position=Vector2(16,14); info_label.add_theme_font_size_override("font_size",18); hud.add_child(info_label)
	prompt_label = Label.new(); prompt_label.position=Vector2(16,58); prompt_label.add_theme_font_size_override("font_size",18); prompt_label.text=""; hud.add_child(prompt_label)
	_build_phone()
	_build_property_panel()
	_build_chat()

func _build_phone() -> void:
	phone_panel = PanelContainer.new(); phone_panel.visible=false; phone_panel.position=Vector2(40,95); phone_panel.custom_minimum_size=Vector2(370,520); hud.add_child(phone_panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation",8); phone_panel.add_child(box)
	var title := Label.new(); title.text="📱 WorldPhone"; title.add_theme_font_size_override("font_size",24); box.add_child(title)
	for app in ["🏦 Bank", "🏠 Properties", "🏢 Businesses", "💬 Chat", "🛒 Marketplace", "📊 City Stats", "⚙ Settings"]:
		var b := Button.new(); b.text=app; box.add_child(b)
	var close := Button.new(); close.text="Close (P)"; close.pressed.connect(_toggle_phone); box.add_child(close)

func _build_property_panel() -> void:
	property_panel = PanelContainer.new(); property_panel.visible=false; property_panel.position=Vector2(450,95); property_panel.custom_minimum_size=Vector2(420,330); hud.add_child(property_panel)

func _build_chat() -> void:
	chat_panel = PanelContainer.new(); chat_panel.visible=false; chat_panel.position=Vector2(40,630); chat_panel.custom_minimum_size=Vector2(520,220); hud.add_child(chat_panel)
	var box := VBoxContainer.new(); chat_panel.add_child(box)
	chat_log = RichTextLabel.new(); chat_log.custom_minimum_size=Vector2(500,150); box.add_child(chat_log)
	chat_input = LineEdit.new(); chat_input.placeholder_text="Type message, press Enter"; chat_input.text_submitted.connect(_send_chat); box.add_child(chat_input)

func _toggle_phone() -> void:
	phone_panel.visible = not phone_panel.visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if phone_panel.visible else Input.MOUSE_MODE_CAPTURED

func _show_property_panel(p: Dictionary) -> void:
	for c in property_panel.get_children(): c.queue_free()
	property_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation",8); property_panel.add_child(box)
	var title := Label.new(); title.text = str(p.get("name", "Property")); title.add_theme_font_size_override("font_size",24); box.add_child(title)
	var owner := str(p.get("owner_user_id", ""))
	if owner.is_empty():
		owner = "Unowned"
	var value := float(p.get("value",0))
	var details := Label.new(); details.text = "Kind: %s\nOwner: %s\nValue: £%.2f\nFor sale: %s" % [p.get("kind","property"), owner, value, str(p.get("is_for_sale",true))]; box.add_child(details)
	var buy := Button.new(); buy.text="Buy Property"; buy.disabled = not bool(p.get("is_for_sale", true)); buy.pressed.connect(_buy_property.bind(str(p.get("id","")))); box.add_child(buy)
	var close := Button.new(); close.text="Close"; close.pressed.connect(func(): property_panel.visible=false; Input.mouse_mode=Input.MOUSE_MODE_CAPTURED); box.add_child(close)

func _buy_property(id: String) -> void:
	if id.is_empty(): return
	API.authed_post("/api/properties/%s/buy" % id, {}, "buy_property")

func _on_api_done(ok: bool, data: Variant, status_code: int, context: String) -> void:
	if context == "buy_property":
		if ok:
			prompt_label.text = "Property bought. Refreshing city..."
			API.get_json("/api/cities/%s" % str(Session.selected_city.get("id","")), "refresh_city")
		else:
			prompt_label.text = "Purchase failed: " + str(data)
	elif context == "refresh_city" and ok:
		Session.city_detail = data
		property_panel.visible = false
		prompt_label.text = "Ownership updated."

func _update_nearest_property() -> void:
	nearest_property = {}
	var nearest_dist := 9999.0
	for id in property_nodes.keys():
		var node: Node3D = property_nodes[id]
		var d := player.global_position.distance_to(node.global_position)
		if d < nearest_dist and d < 8.5:
			nearest_dist = d
			nearest_property = node.get_meta("property")
	if nearest_property.is_empty():
		prompt_label.text = "P: Phone | T: Chat | WASD: Move | Shift: Sprint"
	else:
		prompt_label.text = "Press E: " + str(nearest_property.get("name", "Property"))

func _refresh_hud() -> void:
	info_label.text = "%s | %s | Cash £%s" % [Session.player_name, Session.selected_city.get("name","City"), str(Session.player_cash)]

func _send_chat(text: String) -> void:
	if text.strip_edges().is_empty(): return
	Realtime.send_chat(str(Session.selected_city.get("id","")), text.strip_edges())
	chat_input.text = ""

func _on_realtime_message(data: Dictionary) -> void:
	if data.get("type", "") == "chat":
		chat_log.append_text("%s: %s\n" % [data.get("name", "Player"), data.get("message", "")])
	elif data.get("type", "") in ["property_bought", "city_settings_changed", "city_claimed"]:
		prompt_label.text = "World update received: " + str(data.get("type", "update"))
