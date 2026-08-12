extends ColorRect
class_name GamePaddle

@export var follow_speed: float = 0.25
var half_width: float = 60.0

func _process(_delta: float) -> void:
    var mouse_x: float = get_global_mouse_position().x
    # Ограничиваем движение строго в рамках экрана 540px
    var target_x: float = clamp(mouse_x - half_width, 0.0, 540.0 - (half_width * 2.0))
    global_position.x = lerp(global_position.x, target_x, follow_speed)

func update_width(new_width: float) -> void:
    size.x = new_width
    half_width = new_width / 2.0