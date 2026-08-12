extends ColorRect
class_name FallingArtifact

var speed: float = 160.0
var shader_mat: ShaderMaterial

func setup(p_pos: Vector2) -> void:
    global_position = p_pos
    size = Vector2(24, 24)
    
    shader_mat = ShaderMaterial.new()
    shader_mat.shader = load("res://scripts/hit_flash.gdshader")
    material = shader_mat
    
    shader_mat.set_shader_parameter("base_color", Color(0.65, 0.22, 0.75))
    shader_mat.set_shader_parameter("noise_roughness", 0.4)
    shader_mat.set_shader_parameter("noise_scale", 60.0)
    shader_mat.set_shader_parameter("pulse_intensity", 0.6)
    shader_mat.set_shader_parameter("flash_color", Color(0.9, 0.5, 1.0))
    
    var shadow = ColorRect.new()
    shadow.size = size
    shadow.color = Color(0, 0, 0, 0.4)
    shadow.global_position = p_pos + Vector2(4, 4)
    get_parent().call_deferred("add_child", shadow)
    
    # Прячем ссылку на тень в метаданные самого объекта!
    set_meta("my_shadow", shadow)

func _process(delta: float) -> void:
    global_position.y += speed * delta
    if has_meta("my_shadow"):
        var shadow = get_meta("my_shadow")
        if is_instance_valid(shadow):
            shadow.global_position = global_position + Vector2(4, 4)
        
    if global_position.y > 960:
        clear_shadow()
        queue_free()

func clear_shadow() -> void:
    if has_meta("my_shadow"):
        var shadow = get_meta("my_shadow")
        if is_instance_valid(shadow):
            shadow.queue_free()