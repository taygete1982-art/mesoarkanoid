extends ColorRect
class_name GameBrick

var hp: int = 1
var type: int = 1
var shadow_node: ColorRect
var shader_mat: ShaderMaterial

func setup(p_type: int, p_pos: Vector2, p_shadow: ColorRect) -> void:
    type = p_type
    hp = p_type
    shadow_node = p_shadow
    global_position = p_pos
    
    # Привязываем шейдер вспышки напрямую к материалу
    shader_mat = ShaderMaterial.new()
    shader_mat.shader = load("res://scripts/hit_flash.gdshader")
    material = shader_mat
    
    # Эффект каменной фаски объема
    var light_top = ColorRect.new()
    light_top.size = Vector2(size.x, 3)
    light_top.color = Color(1, 1, 1, 0.22)
    add_child(light_top)
    
    var dark_bot = ColorRect.new()
    dark_bot.size = Vector2(size.x, 3)
    dark_bot.position = Vector2(0, size.y - 3)
    dark_bot.color = Color(0, 0, 0, 0.3)
    add_child(dark_bot)
    
    update_appearance()

func take_hit() -> bool:
    hp -= 1
    
    # Настоящая, безопасная шейдерная вспышка по канонам Godot 4
    var tween = create_tween()
    shader_mat.set_shader_parameter("flash_modifier", 1.0) # Мгновенный яркий блик
    # Плавно гасим вспышку до нуля за 0.12 секунды
    tween.tween_method(func(val: float): shader_mat.set_shader_parameter("flash_modifier", val), 1.0, 0.0, 0.12)

    if hp <= 0:
        if is_instance_valid(shadow_node): shadow_node.queue_free()
        queue_free()
        return true
    update_appearance()
    return false

func update_appearance() -> void:
    if type == 1: color = Color(0.68, 0.47, 0.32) # Глина
    elif type == 2: color = Color(0.46, 0.43, 0.40) # Камень
    elif type == 3: color = Color(0.88, 0.67, 0.15) # Золото
    
    if hp < type:
        color = color.darkened(0.25) # Затемнение при трещинах