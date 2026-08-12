extends Resource
class_name ArtifactData

@export var id: String = ""
@export var name: String = ""
@export_enum("common", "rare", "epic", "legendary") var rarity: String = "common"
@export_multiline var description: String = ""
@export var bonus_type: String = "" # Например: "paddle_width", "score_multiplier", "drop_rate"
@export var bonus_value: float = 0.0
@export var is_unlocked: bool = false
