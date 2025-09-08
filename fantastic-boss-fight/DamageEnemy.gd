extends Area3D

func get_hitscanned(damage : float) -> void:
	Global.emit_signal("hitscan_the_enemy", damage)

func get_punched() -> void:
	Global.emit_signal("punch_the_enemy")
