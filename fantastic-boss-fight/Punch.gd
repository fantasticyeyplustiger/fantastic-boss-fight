extends Node3D

const exhaustion_consumption : Dictionary[Global.fists, float] = {
	Global.fists.PARRY_FIST : 1.0, Global.fists.HEAVY_FIST : 1.5
}

#const MAX_FIST_SWAP_COOLDOWN : float = 0.5

var current_fist : Global.fists = Global.fists.PARRY_FIST

var arm_exhaustion : float = 2.0
var heavy_fist_hold_time : float = 0.0
#var fist_swap_cooldown : float = 0.0

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("swap_fists"):
		swap_fist()
	
	if event.is_action_pressed("parry") and current_fist == Global.fists.PARRY_FIST:
		parry_punch()
	elif event.is_action_pressed("parry") and current_fist == Global.fists.HEAVY_FIST:
		heavy_punch()

func _physics_process(delta: float) -> void:
	
	if arm_exhaustion < 2.0:
		arm_exhaustion += delta * 1.5
	
	if Input.is_action_pressed("parry") and current_fist == Global.fists.HEAVY_FIST:
		heavy_fist_hold_time += delta

func swap_fist() -> void:
	match current_fist:
		Global.fists.PARRY_FIST: current_fist = Global.fists.HEAVY_FIST
		Global.fists.HEAVY_FIST: current_fist = Global.fists.PARRY_FIST
	
	Global.current_fist = current_fist
	
	$AnimationPlayer.stop()
	$AnimationPlayer.play("Default")

## Punches with the Parry Fist (based on Ultrakill's Feedbacker Arm).
## If player is looking at something in punch range, it will be punched.
func parry_punch() -> void:
	
	if arm_exhaustion < 1.0:
		return
	
	$SFX/ParryPunch.play()
	$AnimationPlayer.stop()
	$AnimationPlayer.play("ParryPunch")
	
	arm_exhaustion -= exhaustion_consumption[current_fist]
	Global.emit_signal("punch")
	
## This function should be called when the player hits a parry.
## Plays the parry animation and SFX.
func hit_parry() -> void:
	$AnimationPlayer.stop()
	$AnimationPlayer.play("ParryHit")
	$AnimationPlayer.advance(0)
	$SFX/Parry.play()
	$ParryFlash.visible = true
	
	get_tree().paused = true
	await get_tree().create_timer(0.3).timeout
	get_tree().paused = false
	
	$ParryFlash.visible = false

## Punches with the Heavy Fist (based on Ultrakill's Knuckleblaster Arm).
## If player is looking at something in punch range, it will be punched.
func heavy_punch() -> void:
	
	if arm_exhaustion < 1.0:
		return
	
	$SFX/HeavyPunch.play()
	$AnimationPlayer.stop()
	$AnimationPlayer.play("HeavyPunch")
	
	await get_tree().create_timer(0.1).timeout
	
	if current_fist == Global.fists.PARRY_FIST:
		return
	
	arm_exhaustion -= exhaustion_consumption[current_fist]
	Global.emit_signal("punch")
	
	await get_tree().create_timer(0.8).timeout
	
	if current_fist == Global.fists.PARRY_FIST:
		return
	
	if Input.is_action_pressed("parry"):
		heavy_fist_shockwave()
	else:
		$AnimationPlayer.stop(true)
		$AnimationPlayer.play("TakeBackHeavyPunch")
	
## If player keeps holding punch with Heavy Fist for 0.9 seconds (or presses it at that mark)
## this shockwave will be made.
func heavy_fist_shockwave() -> void:
	pass
	
