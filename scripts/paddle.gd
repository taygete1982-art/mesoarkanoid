extends ColorRect
class_name GamePaddle

@export var follow_speed: float = 0.25
var half_width: float = 60.0
var shader_mat: ShaderMaterial

func _ready() -> void:
	# Одеваем ракетку в шейдер
	shader_mat = ShaderMaterial.new()
	shader_mat.shader = load("res://scripts/hit_flash.gdshader")
	material = shader_mat
	
	# Вытягиваем шум по горизонтали (scale по Y маленький, по X большой) для имитации волокон дерева
	shader_mat.set_shader_parameter("base_color", Color(0.72, 0.51, 0.31))
	shader_mat.set_shader_parameter("noise_roughness", 0.35)
	shader_mat.set_shader_parameter("noise_scale", 25.0)

func _process(_delta: float) -> void:
	var mouse_x: float = get_global_mouse_position().x
	var target_x: float = clamp(mouse_x - half_width, 0.0, 540.0 - (half_width * 2.0))
	global_position.x = lerp(global_position.x, target_x, follow_speed)

func update_width(new_width: float) -> void:
	size.x = new_width
	half_width = new_width / 2.0
