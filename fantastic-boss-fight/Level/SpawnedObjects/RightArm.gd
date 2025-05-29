extends CharacterBody3D

var damage : float = 50.0
var toward_player : bool = true

func _physics_process(_delta: float) -> void:
	if toward_player:
		velocity = (Global.player_position - global_position) * 3.0
		look_at(Global.player_position)
	else:
		velocity = (Global.boss_position - global_position) * 4.0
		look_at(Global.boss_position)
	move_and_slide()

func hit(area: Area3D) -> void:
	if area.get_parent().parrying:
		toward_player = false

func destroy_self() -> void:
	queue_free()
