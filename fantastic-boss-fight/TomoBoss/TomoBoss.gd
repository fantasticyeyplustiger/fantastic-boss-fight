extends Boss

#enum attacks {}

#var previous_attack : attacks
#var current_attack : attacks = attacks.PUNCH_RUSH

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	super(_delta)
