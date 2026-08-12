extends ColorRect
class_name FallingArtifact

var speed: float = 160.0
var shadow_node: ColorRect

func setup(p_pos: Vector2) -> void:
    global_position = p_pos
    color = Color(0.65, 0.22, 0.75) # Пурпур Вавилона
    size = Vector2(24, 24)
    
    # Объемная окантовка (фаска)
    var bevel = ReferenceRect.new()
    bevel.size = size
    bevel.border_color = Color(1, 1, 1, 0.25)
    add_child(bevel)
    
    # Мягкая тень под летящим предметом
    shadow_node = ColorRect.new()
    shadow_node.size = size
    shadow_node.color = Color(0, 0, 0, 0.4)
    shadow_node.global_position = p_pos + Vector2(4, 4)
    get_parent().call_deferred("add_child", shadow_node)

func _process(delta: float) -> void:
    global_position.y += speed * delta
    if is_instance_valid(shadow_node):
        shadow_node.global_position = global_position + Vector2(4, 4)
        
    # Автоудаление, если упал в воду
    if global_position.y > 960:
        if is_instance_valid(shadow_node): shadow_node.queue_free()
        queue_free()