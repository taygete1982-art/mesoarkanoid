@warning_ignore("integer_division")
extends Node2D

var paddle_node: GamePaddle
var ball_node: GameBall
var bricks_container: Node2D
var shadows_container: Node2D
var artifacts_container: Node2D
var audio_player: AudioStreamPlayer
var ui_label: Label

# Настройки Сочности и Тряски
var shake_amount: float = 0.0
var shake_decay: float = 4.0
var original_position: Vector2 = Vector2.ZERO
var bg_flash_modifier: float = 0.0

# Механика Магнитного Зацепа (Фича с форумов)
var is_ball_caught: bool = false
var ball_catch_offset_x: float = 0.0

# Данные прогресса
var collected_artifacts_count: int = 0
var base_paddle_width: float = 120.0
var current_paddle_width: float = 120.0
var current_level_index: int = 0
var save_path: String = "user://save_game.dat"

var levels_data: Array[String] = [
    "2220222_2020202_2033302_1113111_1011101_1001001",
    "0003000_0032300_0321230_3211123_0111110_0011100",
    "0003000_0003000_0023200_0123210_0013100_0001000",
    "3333333_2020202_2020202_1010101_1111111_0000000",
    "0003000_0023200_0133310_2311132_0133310_0023200"
]

func _ready() -> void:
    load_game_data()
    original_position = global_position
    
    var bg_gradient = GradientTexture2D.new()
    bg_gradient.width = 540
    bg_gradient.height = 960
    bg_gradient.fill = GradientTexture2D.FILL_LINEAR
    bg_gradient.fill_from = Vector2(0.5, 0.0)
    bg_gradient.fill_to = Vector2(0.5, 1.0)
    
    var grad = Gradient.new()
    grad.set_color(0, Color(0.11, 0.08, 0.05))
    grad.set_color(1, Color(0.22, 0.16, 0.11))
    bg_gradient.gradient = grad
    
    var bg_sprite = TextureRect.new()
    bg_sprite.texture = bg_gradient
    bg_sprite.size = Vector2(540, 960)
    bg_sprite.name = "Background"
    add_child(bg_sprite)
    
    shadows_container = Node2D.new()
    add_child(shadows_container)
    bricks_container = Node2D.new()
    add_child(bricks_container)
    artifacts_container = Node2D.new()
    add_child(artifacts_container)
    
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
    
    load_level(current_level_index)

func load_level(index: int) -> void:
    for child in bricks_container.get_children(): child.queue_free()
    for child in shadows_container.get_children():
        if child.name != "PaddleShadow": child.queue_free()
    for art in artifacts_container.get_children(): art.queue_free()
    
    var rows = levels_data[index].split("_")
    var block_w = 66
    var block_h = 24
    var start_y = 140
    # ИСПРАВЛЕНИЕ ВОРНИНГА: принудительно приводим к float перед делением
    var start_x = (540.0 - (7.0 * (float(block_w) + 6.0))) / 2.0
    
    for row in range(rows.size()):
        var line = rows[row]
        for col in range(line.length()):
            var type = int(line[col])
            if type == 0: continue
            
            var pos = Vector2(start_x + float(col) * (float(block_w) + 6.0), float(start_y) + float(row) * (float(block_h) + 6.0))
            
            var shadow = ColorRect.new()
            shadow.size = Vector2(block_w, block_h)
            shadow.color = Color(0, 0, 0, 0.45)
            shadow.global_position = pos + Vector2(6, 6)
            shadows_container.add_child(shadow)
            
            var brick = GameBrick.new()
            brick.size = Vector2(block_w, block_h)
            bricks_container.add_child(brick)
            brick.setup(type, pos, shadow)
func _process(delta: float) -> void:
    # 1. Мягкая контролируемая тряска экрана
    if shake_amount > 0.0:
        shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
        global_position = original_position + Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
    else:
        global_position = original_position

    # 2. Постепенно гасим золотую вспышку заднего фона
    var bg = get_node_or_null("Background")
    if bg and bg_flash_modifier > 0.0:
        bg_flash_modifier = lerp(bg_flash_modifier, 0.0, 10.0 * delta)
        bg.modulate = Color(1.0 + bg_flash_modifier * 0.5, 1.0 + bg_flash_modifier * 0.3, 1.0, 1.0)

    # 3. Синхронизация тени ракетки
    var paddle_shadow = shadows_container.get_node_or_null("PaddleShadow")
    if paddle_shadow and is_instance_valid(paddle_node):
        paddle_shadow.size.x = current_paddle_width
        paddle_shadow.global_position = paddle_node.global_position + Vector2(8, 8)
        
    # 4. ЛОГИКА МАГНИТНОГО ЗАЦЕПА (Если мяч пойман ракеткой)
    if is_ball_caught:
        if is_instance_valid(ball_node) and is_instance_valid(paddle_node):
            # Мяч жестко следует за движением ракетки по оси X
            ball_node.global_position.x = paddle_node.global_position.x + ball_catch_offset_x
            ball_node.global_position.y = paddle_node.global_position.y - 16.0
            ball_node.velocity = Vector2.ZERO
            
            # Игрок отпускает ЛКМ / тап — прицельный выстрел вверх!
            if Input.is_action_just_released("click") or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
                is_ball_caught = false
                var hit_center = (ball_node.global_position.x + 8.0) - (paddle_node.global_position.x + (current_paddle_width / 2.0))
                var hit_factor = hit_center / (current_paddle_width / 2.0)
                ball_node.velocity = Vector2(hit_factor, -1.0).normalized() * ball_node.speed
                ball_node.play_impact_effect()
                play_asmr_sound(220.0, 0.06, false) # Упругий звук запуска
        return

    # 5. Обычное движение шара (если он на свободе)
    ball_node.global_position += ball_node.velocity * delta
    
    # Отскок от боковых стен
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
        
    # Отскок от потолка
    if ball_node.global_position.y <= 0.0:
        ball_node.global_position.y = 0.0
        ball_node.velocity.y = abs(ball_node.velocity.y)
        ball_node.play_impact_effect()
        play_asmr_sound(120.0, 0.02, true)
    # Падение в воду Евфрата
    if ball_node.global_position.y > 960.0:
        ball_node.global_position = Vector2(262.0, 500.0)
        ball_node.velocity = Vector2(randf_range(-0.4, 0.4), -1.0).normalized() * ball_node.speed
        play_asmr_sound(75.0, 0.25, false)
        shake_amount = 3.5

    # Столкновение с ракеткой: проверяем зажат ли ЛКМ/Тап для МАГНИТНОГО ЗАЦЕПА
    if get_rect_intersection(ball_node.global_position, ball_node.size, paddle_node.global_position, paddle_node.size):
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            # Мяч переходит в режим удержания (Catch Mechanic)
            is_ball_caught = true
            ball_catch_offset_x = ball_node.global_position.x - paddle_node.global_position.x
            play_asmr_sound(140.0, 0.05, false) # Мягкий щелчок захвата
        else:
            # Обычный классический отскок, если кнопка не зажата
            ball_node.global_position.y = paddle_node.global_position.y - 16.0
            var hit_center = ball_node.global_position.x + 8.0 - (paddle_node.global_position.x + (current_paddle_width / 2.0))
            var hit_factor = hit_center / (current_paddle_width / 2.0)
            ball_node.velocity = Vector2(hit_factor, -1.0).normalized() * ball_node.speed
            ball_node.play_impact_effect()
            play_asmr_sound(170.0, 0.04, true)
            shake_amount = 1.5

    # Ловля падающего пурпура
    for art in artifacts_container.get_children():
        if get_rect_intersection(art.global_position, art.size, paddle_node.global_position, paddle_node.size):
            if is_instance_valid(art.shadow_node): art.shadow_node.queue_free()
            art.queue_free()
            collected_artifacts_count += 1
            current_paddle_width += 15.0
            paddle_node.update_width(current_paddle_width)
            update_ui_text()
            play_asmr_sound(440.0, 0.15, false)
            shake_amount = 2.0
            save_game_data()

    # Разрушение кирпичей, шейдерные вспышки и сок
    for brick in bricks_container.get_children():
        if get_rect_intersection(ball_node.global_position, ball_node.size, brick.global_position, brick.size):
            ball_node.velocity.y = -ball_node.velocity.y
            ball_node.play_impact_effect()
            spawn_sand_particles(brick.global_position + Vector2(33, 12), brick.color)
            
            var is_destroyed = brick.take_hit()
            if is_destroyed:
                if brick.type >= 2:
                    spawn_artifact(brick.global_position + Vector2(20, 5))
                play_asmr_sound(260.0, 0.07, false)
                shake_amount = 4.0
                bg_flash_modifier = 0.4 # Запускаем золотую вспышку всего заднего фона при взрыве плиты!
                call_deferred("check_level_clear")
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
    particles.amount = 14
    particles.lifetime = 0.45
    particles.one_shot = true
    particles.explosiveness = 1.0
    particles.spread = 180.0
    particles.gravity = Vector2(0, 350)
    particles.initial_velocity_min = 60.0
    particles.initial_velocity_max = 130.0
    particles.color = color
    var particle_texture = PlaceholderTexture2D.new()
    particle_texture.size = Vector2(4, 4)
    particles.texture = particle_texture
    add_child(particles)
    particles.emitting = true
    get_tree().create_timer(0.5).timeout.connect(particles.queue_free)

func check_level_clear() -> void:
    if bricks_container.get_child_count() == 0:
        current_level_index = (current_level_index + 1) % levels_data.size()
        load_level(current_level_index)
        ball_node.global_position = Vector2(262, 500)
        ball_node.velocity = Vector2(randf_range(-0.4, 0.4), -1.0).normalized() * ball_node.speed
        save_game_data()

func update_ui_text() -> void:
    var percent = int((current_paddle_width / base_paddle_width) * 100)
    if ui_label:
        ui_label.text = "Зона: Урук (" + str(current_level_index + 1) + "/5) | Реликвии: " + str(collected_artifacts_count) + " | Ракетка: " + str(percent) + "%"

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