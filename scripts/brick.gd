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
    
    # Создаем уникальный материал для GPU рендеринга
    shader_mat = ShaderMaterial.new()
    shader_mat.shader = load("res://scripts/hit_flash.gdshader")
    material = shader_mat
    
    # Тонко настраиваем математику шума под разные типы материалов
    if type == 1:
        # Обожженная глина: пористая, матовая, средний шум
        shader_mat.set_shader_parameter("base_color", Color(0.68, 0.47, 0.32))
        shader_mat.set_shader_parameter("noise_roughness", 0.5)
        shader_mat.set_shader_parameter("noise_scale", 50.0)
    elif type == 2:
        # Древний базальт: грубый, крупнозернистый, темный камень
        shader_mat.set_shader_parameter("base_color", Color(0.42, 0.39, 0.36))
        shader_mat.set_shader_parameter("noise_roughness", 0.7)
        shader_mat.set_shader_parameter("noise_scale", 30.0)
    elif type == 3:
        # Золото Вавилона: мелкая благородная чеканка + легкое постоянное сияние
        shader_mat.set_shader_parameter("base_color", Color(0.88, 0.67, 0.15))
        shader_mat.set_shader_parameter("noise_roughness", 0.3)
        shader_mat.set_shader_parameter("noise_scale", 75.0)
        shader_mat.set_shader_parameter("pulse_intensity", 0.4) # Золото маняще пульсирует
        shader_mat.set_shader_parameter("flash_color", Color(1.0, 0.9, 0.5))

    update_appearance()

func take_hit() -> bool:
    hp -= 1
    
    # Безопасная вспышка удара через плавный лямбда-метод Tween
    var tween = create_tween()
    shader_mat.set_shader_parameter("flash_modifier", 1.0)
    tween.tween_method(func(val: float): 
        if is_instance_valid(shader_mat):
            shader_mat.set_shader_parameter("flash_modifier", val)
    , 1.0, 0.0, 0.14)

    if hp <= 0:
        if is_instance_valid(shadow_node): shadow_node.queue_free()
        queue_free()
        return true
    update_appearance()
    return false

func update_appearance() -> void:
    if hp < type:
        # Считываем текущий цвет материала и сочно затемняем его, имитируя трещины внутри камня
        var current_color: Color = shader_mat.get_shader_parameter("base_color")
        shader_mat.set_shader_parameter("base_color", current_color.darkened(0.22))
        # Увеличиваем шероховатость шума у поврежденной плиты
        var current_rough: float = shader_mat.get_shader_parameter("noise_roughness")
        shader_mat.set_shader_parameter("noise_roughness", clamp(current_rough + 0.15, 0.0, 1.0))