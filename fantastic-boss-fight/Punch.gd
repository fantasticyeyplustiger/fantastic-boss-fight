extends Node3D

const exhaustion_consumption : Dictionary[Global.fists, float] = {
	Global.fists.PARRY_FIST : 1.0, Global.fists.HEAVY_FIST : 1.5
}

const MAX_HEAVY_FIST_HOLD_TIME : float = 0.7
#const MAX_FIST_SWAP_COOLDOWN : float = 0.5

var current_fist : Global.fists = Global.fists.PARRY_FIST

var arm_exhaustion : float = 2.0
var heavy_fist_hold_time : float = 0.0
#var fist_swap_cooldown : float = 0.0

## Shockwave damage.
var damage : float = 1.0

var arm_material : Material

func _ready() -> void:
	arm_material = $Armature/Skeleton3D/LeftArm.get_surface_override_material(0)
	arm_material.emission = Color.CYAN

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
	
	arm_material.emission = Color.CYAN
	arm_material.emission_energy_multiplier = 4.0
	
	$SFX/ParryPunch.play()
	$AnimationPlayer.stop()
	$AnimationPlayer.play("ParryPunch")
	
	if Global.can_projectile_boost:
		SpawnObject.projectile_boost()
		hit_parry(false, 0.1)
	else:
		arm_exhaustion -= exhaustion_consumption[current_fist]
		Global.emit_signal("punch")
	
## This function should be called when the player hits a parry.
## Plays the parry animation and SFX.
func hit_parry(flash_screen : bool = true, stop_time : float = 0.25) -> void:
	arm_material.emission_energy_multiplier = 8.0
	arm_material.emission = Color.WHITE
	$AnimationPlayer.stop()
	$AnimationPlayer.play("ParryHit")
	$AnimationPlayer.advance(0) # Because animation doesn't change instantly, call this
	$SFX/Parry.play()
	$ParryFlash.visible = flash_screen
	
	get_tree().paused = true
	await get_tree().create_timer(stop_time).timeout
	get_tree().paused = false
	
	$ParryFlash.visible = false
	
	var tween : Tween = get_tree().create_tween()
	
	tween.tween_property(
		arm_material,
		"emission",
		Color.CYAN,
		0.65
	).set_ease(Tween.EASE_IN)

## Punches with the Heavy Fist (based on Ultrakill's Knuckleblaster Arm).
## If player is looking at something in punch range, it will be punched.
func heavy_punch() -> void:
	
	if arm_exhaustion < 1.0:
		return
	
	arm_material.emission = Color.ORANGE
	arm_material.emission_energy_multiplier = 2.0
	
	$SFX/HeavyPunch.play()
	$AnimationPlayer.stop()
	$AnimationPlayer.play("HeavyPunch")
	
	await get_tree().create_timer(0.1).timeout
	
	if not current_fist == Global.fists.HEAVY_FIST:
		return
	
	arm_exhaustion -= exhaustion_consumption[current_fist]
	Global.emit_signal("punch")
	
	await get_tree().create_timer(MAX_HEAVY_FIST_HOLD_TIME).timeout
	
	if not current_fist == Global.fists.HEAVY_FIST:
		return
	
	if Input.is_action_pressed("parry"):
		heavy_fist_shockwave()
	else:
		$AnimationPlayer.stop(true)
		$AnimationPlayer.play("TakeBackHeavyPunch")
	
## If player keeps holding punch with Heavy Fist for MAX_HEAVY_FIST_HOLD_TIME seconds
## (or presses it at that mark) this shockwave will be made.
func heavy_fist_shockwave() -> void:
	$AnimationPlayer.play("HeavyPunchShockwave")
	$SFX/HeavyPunchShockwave.play()
	
	arm_material.emission_energy_multiplier = 0.0
	
	SpawnObject.explosion_detailed(
		$Armature/Skeleton3D/ShockwavePosition.global_position,
		"#FFFFFF96",
		0.75,
		true
	)
	
	$Shockwave/Hitbox.set_deferred("disabled", false)
	await get_tree().create_timer(0.5).timeout
	
	if not current_fist == Global.fists.HEAVY_FIST:
		return
	
	$SFX/HeavyPunchReload.play()
	$Shockwave/Hitbox.set_deferred("disabled", true)
	
	var tween : Tween = get_tree().create_tween()
	
	tween.tween_property(
		arm_material,
		"emission_energy_multiplier",
		2.0,
		0.2
	)
	
