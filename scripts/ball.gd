extends ColorRect
class_name GameBall

@export var speed: float = 600.0
var velocity: Vector2 = Vector2.ZERO
var trail: Line2D
var max_trail_points: int = 25

func _ready() -> void:
    # Одеваем шар в хрустальное жидкое стекло с глянцевым преломлением
    var ball_mat = ShaderMaterial.new()
    ball_mat.shader = load("res://scripts/hit_flash.gdshader")
    ball_mat.set_shader_parameter("base_color", Color(0.18, 0.68, 0.82, 1.0))
    material = ball_mat
    # РќР°СЃС‚СЂР°РёРІР°РµРј РјР°С‚РµСЂРёР°Р» РЅРµРѕРЅРѕРІРѕРіРѕ РЅР°Р»РѕР¶РµРЅРёСЏ (Additive Blend)
    var mat = CanvasItemMaterial.new()
    mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    
    # РЎРѕР·РґР°РµРј РЅРµРїСЂРµСЂС‹РІРЅСѓСЋ СЃРІРµС‚РѕРІСѓСЋ Р»РµРЅС‚Сѓ РєРѕРјРµС‚С‹
    trail = Line2D.new()
    trail.material = mat
    trail.width = 16.0
    
    # РџР»Р°РІРЅРѕРµ СЃСѓР¶РµРЅРёРµ С…РІРѕСЃС‚Р° Рє РєРѕРЅС†Сѓ
    var width_curve = Curve.new()
    width_curve.add_point(Vector2(0.0, 1.0)) # Р“РѕР»РѕРІР°: 100% С€РёСЂРёРЅР°
    width_curve.add_point(Vector2(1.0, 0.1)) # РҐРІРѕСЃС‚: 10% С€РёСЂРёРЅР°
    trail.width_curve = width_curve
    
    # РЈР»СЊС‚СЂР°-РјСЏРіРєРёР№ Р»Р°Р·СѓСЂРЅС‹Р№ РіСЂР°РґРёРµРЅС‚ СЂР°СЃС‚РІРѕСЂРµРЅРёСЏ
    var grad = Gradient.new()
    grad.set_color(0, Color(0.2, 0.75, 0.9, 0.8))  # Р“РѕСЂСЏС‰РёР№ РЅРµРѕРЅРѕРІС‹Р№ Р»Р°Р·СѓСЂРёС‚
    grad.set_color(1, Color(0.05, 0.3, 0.5, 0.0))  # Р Р°СЃС‚РІРѕСЂРµРЅРёРµ РІ РєРѕСЃРјРёС‡РµСЃРєРѕР№ РїС‹Р»Рё
    trail.gradient = grad
    
    trail.joint_mode = Line2D.LINE_JOINT_ROUND
    trail.end_cap_mode = Line2D.LINE_CAP_ROUND
    
    get_parent().call_deferred("add_child", trail)
    
    velocity = Vector2(randf_range(-0.4, 0.4), -1.0).normalized() * speed
    pivot_offset = size / 2.0

func _process(delta: float) -> void:
    global_position += velocity * delta
    
    # Р­С„С„РµРєС‚ Squash & Stretch РїРѕ РІРµРєС‚РѕСЂСѓ СЃРєРѕСЂРѕСЃС‚Рё
    var motion_dir = velocity.normalized()
    rotation = motion_dir.angle() + PI/2
    scale = Vector2(0.8, 1.3) # Р”РёРЅР°РјРёС‡РµСЃРєРѕРµ РІС‹С‚СЏРіРёРІР°РЅРёРµ СЃС„РµСЂС‹
    
    # Р”РѕР±Р°РІР»СЏРµРј С‚РѕС‡РєСѓ РёР· С†РµРЅС‚СЂР° С€Р°СЂР° РґР»СЏ Р±РµСЃС€РѕРІРЅРѕСЃС‚Рё СЃРІРµС‚РѕРІРѕР№ Р»РµРЅС‚С‹
    trail.add_point(global_position + pivot_offset)
    if trail.get_point_count() > max_trail_points:
        trail.remove_point(0)

func play_impact_effect() -> void:
    var tween = create_tween()
    scale = Vector2(1.6, 0.4) # РЎРѕС‡РЅС‹Р№ СѓРїСЂСѓРіРёР№ Squash РїСЂРё СѓРґР°СЂРµ
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)