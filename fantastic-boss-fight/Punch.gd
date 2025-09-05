extends Node3D

enum fists {PARRY_FIST, HEAVY_FIST}

const exhaustion_consumption : Dictionary[fists, float] = {
	fists.PARRY_FIST : 1.0, fists.HEAVY_FIST : 1.5
}

const HEAVY_FIST_EXPLOSION_TIME : float = 1.9

var current_fist : fists = fists.PARRY_FIST

var arm_exhaustion : float = 2.0
var heavy_fist_hold_time : float = 0.0

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("parry") and current_fist == fists.PARRY_FIST:
		parry_punch()
	elif event.is_action_pressed("parry") and current_fist == fists.HEAVY_FIST:
		heavy_punch()

func _physics_process(delta: float) -> void:
	
	if arm_exhaustion < 2.0:
		arm_exhaustion += delta * 1.5
	
	if Input.is_action_pressed("parry") and current_fist == fists.HEAVY_FIST:
		heavy_fist_hold_time += delta
	
	if heavy_fist_hold_time > HEAVY_FIST_EXPLOSION_TIME:
		heavy_fist_shockwave()
		heavy_fist_hold_time = 0.0

## Punches with the Parry Fist (based on Ultrakill's Feedbacker Arm).
## If player is looking at something in punch range and can be parried, it will be parried.
## Otherwise, it'll just do a regular punch.
func parry_punch() -> void:
	
	if arm_exhaustion < exhaustion_consumption[fists.PARRY_FIST]:
		# Play fail sfx
		return
	
	
## Punches with the Heavy Fist (based on Ultrakill's Knuckleblaster Arm).
## If player is looking at something in punch range, it will be punched.
func heavy_punch() -> void:
	
	if arm_exhaustion < exhaustion_consumption[fists.HEAVY_FIST]:
		# Play fail sfx
		return
	
## If player holds down punch button for HEAVY_FIST_EXPLOSION_TIME,
## this shockwave will be produced. 
func heavy_fist_shockwave() -> void:
	pass
	
