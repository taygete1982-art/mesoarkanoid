extends ColorRect
class_name GameBall

@export var speed: float = 600.0
var velocity: Vector2 = Vector2.ZERO
var trail: Line2D
var max_trail_points: int = 20

func _ready() -> void:
    # Идеально гладкий шлейф кометы
    trail = Line2D.new()
    trail.width = 16.0
    
    var grad = Gradient.new()
    grad.set_color(0, Color(0.18, 0.65, 0.73, 0.7)) # Голова кометы
    grad.set_color(1, Color(0.18, 0.65, 0.73, 0.0)) # Исчезающий хвост
    trail.gradient = grad
    
    trail.joint_mode = Line2D.LINE_JOINT_ROUND
    trail.end_cap_mode = Line2D.LINE_CAP_ROUND
    get_parent().call_deferred("add_child", trail)
    
    velocity = Vector2(randf_range(-0.4, 0.4), -1.0).normalized() * speed
    
    # Центрируем точку трансформации (Pivot), чтобы шар сжимался из центра, а не из угла
    pivot_offset = size / 2.0

func _process(delta: float) -> void:
    global_position += velocity * delta
    
    # Динамически вытягиваем шар по направлению полета (Stretch)
    var motion_dir = velocity.normalized()
    rotation = motion_dir.angle() + PI/2
    scale = Vector2(0.85, 1.25) # Вытянутая форма кометы в полете
    
    # Плавный шлейф
    trail.add_point(global_position + pivot_offset)
    if trail.get_point_count() > max_trail_points:
        trail.remove_point(0)

# Функция сочного сплющивания при ударе (Squash)
func play_impact_effect() -> void:
    var tween = create_tween()
    # Мгновенно сжимаем шар при ударе и плавно возвращаем к норме за 0.15 секунды
    scale = Vector2(1.5, 0.5)
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)