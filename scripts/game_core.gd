@warning_ignore("integer_division")
extends Node2D

var paddle_node: GamePaddle
var ball_node: GameBall
var bricks_container: Node2D
var shadows_container: Node2D
var artifacts_container: Node2D
var obstacles_container: Node2D
var audio_player: AudioStreamPlayer
var ui_label: Label

var shake_amount: float = 0.0
var shake_decay: float = 4.0
var original_position: Vector2 = Vector2.ZERO
var bg_flash_modifier: float = 0.0
var obstacle_time: float = 0.0

var target_camera_y: float = 0.0
var current_camera_y: float = 0.0
var scroll_speed: float = 3.0
var lowest_destroyed_row: int = 34

var is_ball_caught: bool = false
var ball_catch_offset_x: float = 0.0

var collected_artifacts_count: int = 0
var base_paddle_width: float = 120.0
var current_paddle_width: float = 120.0
var current_level_index: int = 0
var save_path: String = "user://save_game.dat"
var tower_matrix: Array[String] = []

func _ready() -> void:
	load_game_data()
	original_position = global_position
	current_camera_y = global_position.y
	target_camera_y = global_position.y
	
	for i in range(35):
		if i >= 30: tower_matrix.append("3333333")
		elif i >= 20: tower_matrix.append("2222222")
		else: tower_matrix.append("1111111")
	
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 1.3
	env.glow_bloom = 0.3
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env_node.environment = env
	add_child(env_node)

	var bg_gradient = GradientTexture2D.new()
	bg_gradient.width = 540
	bg_gradient.height = 960
	bg_gradient.fill = GradientTexture2D.FILL_LINEAR
	bg_gradient.fill_from = Vector2(0.5, 0.0)
	bg_gradient.fill_to = Vector2(0.5, 1.0)
	var grad = Gradient.new()
	grad.set_color(0, Color(0.08, 0.06, 0.04))
	grad.set_color(1, Color(0.18, 0.13, 0.09))
	bg_gradient.gradient = grad
	
	var bg_sprite = TextureRect.new()
	bg_sprite.texture = bg_gradient
	bg_sprite.size = Vector2(540, 960)
	bg_sprite.name = "Background"
	add_child(bg_sprite)
	
	var ambient_particles = CPUParticles2D.new()
	ambient_particles.amount = 25
	ambient_particles.lifetime = 6.0
	ambient_particles.preprocess = 4.0
	ambient_particles.speed_scale = 0.4
	ambient_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ambient_particles.emission_rect_extents = Vector2(270, 480)
	ambient_particles.position = Vector2(270, 480)
	ambient_particles.gravity = Vector2(0, -10)
	ambient_particles.initial_velocity_min = 5.0
	ambient_particles.initial_velocity_max = 15.0
	ambient_particles.scale_amount_min = 2.0
	ambient_particles.scale_amount_max = 5.0
	ambient_particles.color = Color(0.85, 0.65, 0.25, 0.18)
	var dust_tex = PlaceholderTexture2D.new()
	dust_tex.size = Vector2(2, 2)
	ambient_particles.texture = dust_tex
	add_child(ambient_particles)
	
	shadows_container = Node2D.new()
	add_child(shadows_container)
	bricks_container = Node2D.new()
	add_child(bricks_container)
	artifacts_container = Node2D.new()
	add_child(artifacts_container)
	obstacles_container = Node2D.new()
	add_child(obstacles_container)
	
	paddle_node = GamePaddle.new()
	paddle_node.size = Vector2(current_paddle_width, 20)
	paddle_node.color = Color(0.72, 0.51, 0.31)
	paddle_node.global_position = Vector2(270.0 - (current_paddle_width / 2.0), 850.0)
	add_child(paddle_node)
	
	var paddle_shadow = ColorRect.new()
	paddle_shadow.size = Vector2(current_paddle_width, 20)
	paddle_shadow.color = Color(0, 0, 0, 0.4)
	paddle_shadow.name = "PaddleShadow"
	paddle_shadow.global_position = paddle_node.global_position + Vector2(8.0, 8.0)
	shadows_container.add_child(paddle_shadow)
	
	ball_node = GameBall.new()
	ball_node.size = Vector2(16, 16)
	ball_node.color = Color(0.15, 0.62, 0.74)
	ball_node.global_position = Vector2(262.0, 500.0)
	add_child(ball_node)
	
	ui_label = Label.new()
	update_ui_text()
	ui_label.position = Vector2(25, 25)
	add_child(ui_label)
	
	audio_player = AudioStreamPlayer.new()
	var synth_stream = AudioStreamGenerator.new()
	synth_stream.mix_rate = 22050
	synth_stream.buffer_length = 0.1
	audio_player.stream = synth_stream
	add_child(audio_player)
	
	build_mega_tower()

func build_mega_tower() -> void:
	var block_w = 66
	var block_h = 24
	var start_x = (540.0 - (7.0 * (float(block_w) + 6.0))) / 2.0
	for row in range(tower_matrix.size()):
		var line = tower_matrix[row]
		for col in range(line.length()):
			var type = int(line[col])
			if type == 0: continue
			var pos = Vector2(start_x + float(col) * (float(block_w) + 6.0), 380.0 - float(row) * (float(block_h) + 6.0))
			var shadow = ColorRect.new()
			shadow.size = Vector2(block_w, block_h)
			shadow.color = Color(0, 0, 0, 0.45)
			shadow.global_position = pos + Vector2(6, 6)
			shadows_container.add_child(shadow)
			var brick = GameBrick.new()
			brick.size = Vector2(block_w, block_h)
			brick.set_meta("row_index", row)
			bricks_container.add_child(brick)
			brick.setup(type, pos, shadow)
	var obs = ColorRect.new()
	obs.size = Vector2(110, 18)
	obs.color = Color(0.55, 0.22, 0.22)
	obs.global_position = Vector2(215, 430)
	obs.set_meta("base_x", 215.0)
	obstacles_container.add_child(obs)
func _process(delta: float) -> void:
	if shake_amount > 0.0:
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
		var rx = randf_range(-shake_amount, shake_amount)
		var ry = randf_range(-shake_amount, shake_amount)
		global_position = Vector2(original_position.x + rx, current_camera_y + ry)
	else:
		global_position = Vector2(original_position.x, current_camera_y)

	var bg = get_node_or_null("Background")
	if bg and bg_flash_modifier > 0.0:
		bg_flash_modifier = lerp(bg_flash_modifier, 0.0, 10.0 * delta)
		bg.modulate = Color(1.0 + bg_flash_modifier * 0.5, 1.0 + bg_flash_modifier * 0.3, 1.0, 1.0)

	if current_camera_y != target_camera_y:
		current_camera_y = lerp(current_camera_y, target_camera_y, scroll_speed * delta)
		if bg: bg.global_position.y = current_camera_y
		if ui_label: ui_label.global_position.y = current_camera_y + 25.0
		if paddle_node: paddle_node.global_position.y = current_camera_y + 850.0

	var paddle_shadow = shadows_container.get_node_or_null("PaddleShadow")
	if paddle_shadow and is_instance_valid(paddle_node):
		paddle_shadow.size.x = current_paddle_width
		paddle_shadow.global_position = paddle_node.global_position + Vector2(8.0, 8.0)
		
	obstacle_time += delta
	for obs in obstacles_container.get_children():
		if obs.has_meta("base_x"):
			var base_x = obs.get_meta("base_x")
			obs.global_position.x = base_x + sin(obstacle_time * 2.0) * 140.0
			obs.global_position.y = current_camera_y + 430.0

	if is_ball_caught:
		if is_instance_valid(ball_node) and is_instance_valid(paddle_node):
			ball_node.global_position.x = paddle_node.global_position.x + ball_catch_offset_x
			ball_node.global_position.y = paddle_node.global_position.y - 16.0
			ball_node.velocity = Vector2.ZERO
			if Input.is_action_just_released("click") or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				is_ball_caught = false
				var hit_center = (ball_node.global_position.x + 8.0) - (paddle_node.global_position.x + (current_paddle_width / 2.0))
				var hit_factor = hit_center / (current_paddle_width / 2.0)
				ball_node.velocity = Vector2(hit_factor, -1.0).normalized() * ball_node.speed
				ball_node.play_impact_effect()
				play_asmr_sound(220.0, 0.06, false)
		return

	ball_node.global_position += ball_node.velocity * delta
	
	if ball_node.global_position.x <= 0.0:
		ball_node.global_position.x = 0.0
		ball_node.velocity.x = abs(ball_node.velocity.x)
		ball_node.play_impact_effect()
		play_asmr_sound(120.0, 0.02, true)
	elif ball_node.global_position.x >= 540.0 - 16.0:
		ball_node.global_position.x = 540.0 - 16.0
		ball_node.velocity.x = -abs(ball_node.velocity.x)
		ball_node.play_impact_effect()
		play_asmr_sound(120.0, 0.02, true)
		
	if ball_node.global_position.y <= current_camera_y:
		ball_node.global_position.y = current_camera_y
		ball_node.velocity.y = abs(ball_node.velocity.y)
		ball_node.play_impact_effect()
		play_asmr_sound(120.0, 0.02, true)
		
	if ball_node.global_position.y > current_camera_y + 960.0:
		ball_node.global_position = Vector2(262.0, current_camera_y + 500.0)
		ball_node.velocity = Vector2(randf_range(-0.4, 0.4), -1.0).normalized() * ball_node.speed
		spawn_water_splash(Vector2(paddle_node.global_position.x + (current_paddle_width / 2.0), current_camera_y + 940.0))
		play_asmr_sound(75.0, 0.25, false)
		shake_amount = 3.5

	for obs in obstacles_container.get_children():
		if get_rect_intersection(ball_node.global_position, ball_node.size, obs.global_position, obs.size):
			ball_node.velocity.y = -ball_node.velocity.y
			ball_node.play_impact_effect()
			play_asmr_sound(200.0, 0.04, true)
			shake_amount = 2.0
			break

	if get_rect_intersection(ball_node.global_position, ball_node.size, paddle_node.global_position, paddle_node.size):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_ball_caught = true
			ball_catch_offset_x = ball_node.global_position.x - paddle_node.global_position.x
			play_asmr_sound(140.0, 0.05, false)
		else:
			ball_node.global_position.y = paddle_node.global_position.y - 16.0
			var hit_center = ball_node.global_position.x + 8.0 - (paddle_node.global_position.x + (current_paddle_width / 2.0))
			var hit_factor = hit_center / (current_paddle_width / 2.0)
			ball_node.velocity = Vector2(hit_factor, -1.0).normalized() * ball_node.speed
			ball_node.play_impact_effect()
			play_asmr_sound(170.0, 0.04, true)
			shake_amount = 1.5

	for art in artifacts_container.get_children():
		if get_rect_intersection(art.global_position, art.size, paddle_node.global_position, paddle_node.size):
			if art.has_method("clear_shadow"): art.clear_shadow()
			art.queue_free()
			collected_artifacts_count += 1
			current_paddle_width += 15.0
			paddle_node.update_width(current_paddle_width)
			update_ui_text()
			play_asmr_sound(440.0, 0.15, false)
			shake_amount = 2.0
			save_game_data()

	for brick in bricks_container.get_children():
		if get_rect_intersection(ball_node.global_position, ball_node.size, brick.global_position, brick.size):
			ball_node.velocity.y = -ball_node.velocity.y
			ball_node.play_impact_effect()
			spawn_sand_particles(brick.global_position + Vector2(33, 12), brick.color)
			var brick_row = brick.get_meta("row_index")
			var is_destroyed = brick.take_hit()
			if is_destroyed:
				if brick.type >= 2: spawn_artifact(brick.global_position + Vector2(20, 5))
				play_asmr_sound(260.0, 0.07, false)
				shake_amount = 4.0
				bg_flash_modifier = 0.4
				if brick_row == lowest_destroyed_row:
					call_deferred("check_row_clearance")
			else:
				play_asmr_sound(190.0, 0.04, true)
				shake_amount = 2.0
			break

func spawn_artifact(pos: Vector2) -> void:
	var art = FallingArtifact.new()
	artifacts_container.add_child(art)
	art.setup(pos)

func spawn_sand_particles(pos: Vector2, color: Color) -> void:
	var particles = CPUParticles2D.new()
	particles.global_position = pos
	particles.amount = 16
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, 380)
	particles.initial_velocity_min = 70.0
	particles.initial_velocity_max = 150.0
	particles.color = color
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = curve
	var particle_texture = PlaceholderTexture2D.new()
	particle_texture.size = Vector2(5, 5)
	particles.texture = particle_texture
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(0.6).timeout.connect(particles.queue_free)

func spawn_water_splash(pos: Vector2) -> void:
	var splash = CPUParticles2D.new()
	splash.global_position = pos
	splash.amount = 12
	splash.lifetime = 0.6
	splash.one_shot = true
	splash.explosiveness = 0.95
	splash.spread = 45.0
	splash.direction = Vector2(0, -1)
	splash.gravity = Vector2(0, 450)
	splash.initial_velocity_min = 120.0
	splash.initial_velocity_max = 220.0
	splash.color = Color(0.24, 0.64, 0.85, 0.6)
	var tex = PlaceholderTexture2D.new()
	tex.size = Vector2(4, 4)
	splash.texture = tex
	add_child(splash)
	splash.emitting = true
	get_tree().create_timer(0.7).timeout.connect(splash.queue_free)

func check_row_clearance() -> void:
	var current_row_has_bricks = false
	for brick in bricks_container.get_children():
		if brick.get_meta("row_index") == lowest_destroyed_row:
			current_row_has_bricks = true
			break
	if not current_row_has_bricks:
		lowest_destroyed_row -= 1
		target_camera_y -= 30.0
		play_asmr_sound(150.0, 0.15, false)
		if lowest_destroyed_row < 0:
			lowest_destroyed_row = 34
			target_camera_y = 0.0
			current_camera_y = 0.0
			build_mega_tower()

func update_ui_text() -> void:
	var percent = int((current_paddle_width / base_paddle_width) * 100)
	if ui_label:
		ui_label.text = "Р­С‚Р°Р¶ Р—РёРєРєСѓСЂР°С‚Р°: " + str(35 - lowest_destroyed_row) + "/35 | Р РµР»РёРєРІРёРё: " + str(collected_artifacts_count) + " | Р Р°РєРµС‚РєР°: " + str(percent) + "%"

func save_game_data() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_32(current_level_index)
		file.store_32(collected_artifacts_count)
		file.store_float(current_paddle_width)
		file.close()

func load_game_data() -> void:
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			current_level_index = file.get_32()
			collected_artifacts_count = file.get_32()
			current_paddle_width = file.get_float()
			file.close()

func get_rect_intersection(pos1: Vector2, size1: Vector2, pos2: Vector2, size2: Vector2) -> bool:
	return pos1.x < pos2.x + size2.x and pos1.x + size1.x > pos2.x and pos1.y < pos2.y + size2.y and pos1.y + size1.y > pos2.y

func play_asmr_sound(frequency: float, duration: float, is_noise: bool) -> void:
	audio_player.play()
	var playback = audio_player.get_stream_playback()
	if playback == null: return
	var sample_count = int(22050 * duration)
	var phase = 0.0
	for i in range(sample_count):
		var frame = 0.0
		if is_noise:
			frame = randf_range(-0.25, 0.25) * (1.0 - float(i) / sample_count)
		else:
			var increment = 2.0 * PI * frequency / 22050.0
			phase += increment
			frame = sin(phase) * 0.35 * (1.0 - float(i) / sample_count)
		playback.push_frame(Vector2(frame, frame))
