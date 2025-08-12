extends CharacterBody3D

enum buffs {PUNCHED, RAILGUN, EXPLODED, ORB_SLICED}

const ADD_BUFF_DMG : Dictionary[buffs, float] = {
	buffs.PUNCHED : 1.0,
	buffs.RAILGUN : 3.0,
	buffs.EXPLODED : 0.5,
	buffs.ORB_SLICED : 0.75
}

func _ready() -> void:
	pass

func initialize(spawn_position : Vector3) -> void:
	pass
