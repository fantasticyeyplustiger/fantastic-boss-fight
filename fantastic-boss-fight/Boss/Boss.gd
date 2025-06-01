extends CharacterBody3D

const LOW_DAMAGE : float = 25.0
const MED_DAMAGE : float = 50.0
const HIGH_DAMAGE : float = 100.0

const WALK_SPEED : float = 7.5
const SPRINT_SPEED : float = 35.0

const GRAVITY : float = 19.6

const Y_VALUE_FOR_FLOOR : float = 1.1

@onready var attack_cd_timer = $AttackCooldown
@onready var walk_cooldown = $CanWalkCooldown

@onready var charge_hitbox = $ChargePath/Hitbox
@onready var charge_visible_hitbox = $ChargePath/VisibleHitbox

var health : float = 1_000_000
var damage : float

var attacking : bool = false
var attack_cooldown : bool = true
var can_walk : bool = true
var should_look_at_player : bool = false
var parrying : bool = false

var current_attack : int = 1

func _ready() -> void:
	attack_cd_timer.start(2.0)

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	if not attacking and not attack_cooldown:
		attacking = true
		attack_loop()
	elif not attacking and can_walk:
		walk_towards_player()
	
	if should_look_at_player:
		look_at(Global.player_position + Vector3(0.0, 0.8, 0.0))
	
	Global.boss_position = global_position


func attack_loop() -> void:
	
	var target_position : Vector3 = Global.player_position
	attack_cooldown = true
	can_walk = false
	
	match current_attack:
		1, 2, 3: 
			if not Global.player_in_air:
				ground_charge(target_position)
			else:
				air_charge(target_position)
		4: throw_fist()
		5, 6, 9: clap()
		7: ground_charge(target_position)
		8: jump_and_crush()
		10:
			summon_cone()
			current_attack = 0
	
	attacking = false
	current_attack += 1

## Makes the boss charge towards the player in the air.
func air_charge(target_position : Vector3) -> void:
	
	$Parryable.emitting = true
	
	damage = MED_DAMAGE
	look_at(target_position)
	
	var magnitude : float = (target_position - global_position).length()
	var new_position : Vector3 = Vector3(0, 0, (-magnitude * 3) + 1.5)
	var new_height : float = magnitude * 6
	
	$AirChargePath/Hitbox.position = new_position
	$AirChargePath/Hitbox.shape.height = new_height
	$AirChargePath/VisibleHitbox.position = new_position
	$AirChargePath/VisibleHitbox.mesh.height = new_height
	
	$Animations.play("air_charge")
	
	await get_tree().create_timer(0.3).timeout
	# ATTACK will now hit PLAYER
	$AirChargePath/Hitbox.set_deferred("disabled", false)
	$Animations.play("RESET")
	
	await get_tree().create_timer(0.05).timeout
	# ATTACK will no longer hit PLAYER
	$AirChargePath/Hitbox.set_deferred("disabled", true)
	
	$Parryable.emitting = false
	SpawnObject.air_shockwave(global_position, global_rotation + Vector3(deg_to_rad(90.0), 0.0, 0.0))
	global_position = target_position
	
	walk_cooldown.start(0.2)
	attack_cd_timer.start(0.25)

## Makes the boss charge towards the player on the ground.
func ground_charge(target_position : Vector3) -> void:
	damage = HIGH_DAMAGE
	
	if is_on_floor():
		look_at_player()
	else:
		look_at(target_position)
	
	var magnitude : float = (target_position - global_position).length()
	
	## Sets the size of the attack directly
	var size : Vector3 = Vector3(12.0, 17.0, magnitude * 4.5)
	var hitbox_pos : Vector3 = Vector3(0, 2.5, (-magnitude * 2.25) + 1.5)
	
	charge_hitbox.shape.size = size
	charge_hitbox.position = hitbox_pos
	
	if is_on_floor():
		# LANDING should be bigger due to jumping down
		charge_visible_hitbox.mesh.size = size - Vector3(0.0, 16.0, 0.0)
		$ChargeLanding/VisibleLandingHitbox.mesh.top_radius = 35.0
		$ChargeLanding/VisibleLandingHitbox.mesh.bottom_radius = 35.0
		$ChargeLanding/LandingHitbox.shape.radius = 35.0
	else:
		charge_visible_hitbox.mesh.size = size - Vector3(0.0, 1.0, 0.0)
		$ChargeLanding/VisibleLandingHitbox.mesh.top_radius = 25.0
		$ChargeLanding/VisibleLandingHitbox.mesh.bottom_radius = 25.0
		$ChargeLanding/LandingHitbox.shape.radius = 25.0
	
	charge_visible_hitbox.position = hitbox_pos - Vector3(0.0, 6.0, 0.0)
	charge_visible_hitbox.visible = true
	
	$ChargeLanding/VisibleLandingHitbox.global_position = Vector3(target_position.x, 0.0, target_position.z)
	$ChargeLanding/VisibleLandingHitbox.global_rotation = Vector3.ZERO
	$ChargeLanding/LandingHitbox.global_position = Vector3(target_position.x, 0.0, target_position.z)
	$ChargeLanding/LandingHitbox.global_rotation = Vector3.ZERO
	
	$Animations.play("charge")
	await get_tree().create_timer(0.6).timeout
	# ATTACK can now hit the PLAYER
	SpawnObject.air_shockwave(global_position, global_rotation + Vector3(deg_to_rad(90.0), 0.0, 0.0))
	charge_hitbox.set_deferred("disabled", false)
	$ChargeLanding/LandingHitbox.set_deferred("disabled", false)
	
	# reset turns hitbox invisible
	$Animations.play("RESET")
	
	await get_tree().create_timer(0.05).timeout
	# ATTACK can no longer hit the PLAYER
	global_position = Vector3(target_position.x, Y_VALUE_FOR_FLOOR, target_position.z)
	charge_hitbox.set_deferred("disabled", true)
	$ChargeLanding/LandingHitbox.set_deferred("disabled", true)
	
	walk_cooldown.start(0.4)
	attack_cd_timer.start(0.45)
	SpawnObject.ground_shockwave(target_position)

## Makes the boss throw his right arm/fist towards the player.
# Constantly chases them until it hits, gets parried, or runs out of time to hit.
func throw_fist() -> void:
	
	$Parryable.emitting = true
	$Animations.play("throw_arm")
	should_look_at_player = true
	
	await get_tree().create_timer(1.0).timeout
	
	$Torso/RightArm.visible = false
	SpawnObject.right_arm(global_position + Vector3(0.56, 0, 0))
	
	$Animations.play("RESET")
	$Parryable.emitting = false
	
	walk_cooldown.start(0.35)
	attack_cd_timer.start(1.3)
	respawn_right_arm(1.0) # Await is asynchronous
	
	should_look_at_player = false

func clap() -> void:
	damage = HIGH_DAMAGE
	should_look_at_player = true
	SpawnObject.air_shockwave(global_position, global_rotation + Vector3(deg_to_rad(90), 0.0, 0.0))
	global_position = Global.boss_to_player
	
	$Animations.play("clap")
	
	await get_tree().create_timer(0.45).timeout
	$Clap/Hitbox.set_deferred("disabled", false)
	SpawnObject.colliding_shockwave($Clap/Hitbox.global_position, global_rotation + Vector3(0.0, 0.0, deg_to_rad(90.0)))
	
	await get_tree().create_timer(0.1).timeout
	$Clap/Hitbox.set_deferred("disabled", true)
	
	should_look_at_player = false
	walk_cooldown.start(0.1)
	attack_cd_timer.start(0.15)

func jump_and_crush() -> void:
	damage = HIGH_DAMAGE
	SpawnObject.air_shockwave(global_position, Vector3.ZERO)
	global_position.y += 30.0
	
	$ChargeLanding/VisibleLandingHitbox.mesh.top_radius = 85.0
	$ChargeLanding/VisibleLandingHitbox.mesh.bottom_radius = 85.0
	$ChargeLanding/LandingHitbox.shape.radius = 85.0
	
	$ChargeLanding/VisibleLandingHitbox.global_position = Vector3(global_position.x, 0.0, global_position.z)
	$ChargeLanding/VisibleLandingHitbox.global_rotation = Vector3.ZERO
	$ChargeLanding/LandingHitbox.global_position = Vector3(global_position.x, 0.0, global_position.z)
	$ChargeLanding/LandingHitbox.global_rotation = Vector3.ZERO
	$ChargePath/VisibleHitbox.visible = false
	
	$Animations.play("crush")
	await get_tree().create_timer(1.0).timeout
	
	$ChargeLanding/LandingHitbox.set_deferred("disabled", false)
	SpawnObject.air_shockwave(global_position, Vector3.ZERO)
	
	await get_tree().create_timer(0.05).timeout
	
	global_position.y = Y_VALUE_FOR_FLOOR
	SpawnObject.ground_shockwave(global_position)
	SpawnObject.air_shockwave(global_position, Vector3.ZERO)
	SpawnObject.colliding_shockwave(global_position, Vector3.ZERO)
	
	await get_tree().create_timer(0.05).timeout
	
	$ChargeLanding/LandingHitbox.set_deferred("disabled", true)
	$ChargePath/VisibleHitbox.visible = true
	
	reset_anim()
	walk_cooldown.start(0.4)
	attack_cd_timer.start(0.45)

func summon_cone() -> void:
	$Aura.emitting = true
	$Animations.play("summon_cone")
	await get_tree().create_timer(1.0).timeout
	
	SpawnObject.ice_cream_cone(global_position + Vector3(0.0, 4.0, 0.0))
	await get_tree().create_timer(0.8).timeout
	reset_anim()
	$Aura.emitting = false
	
	walk_cooldown.start(0.1)
	attack_cd_timer.start(0.75)

func walk_towards_player() -> void:
	var vector2_pos = Vector3(global_position.x, 0.0, global_position.z)
	var vector2_player_pos = Vector3(Global.player_position.x, 0.0, Global.player_position.z)
	
	var direction : Vector3 = vector2_pos.direction_to(vector2_player_pos)
	
	velocity = direction * WALK_SPEED
	
	look_at_player()
	move_and_slide()

## Rotates the boss' body to look at the player.
# Only rotates the y-axis.
func look_at_player() -> void:
	if global_position.cross(Global.player_position).is_zero_approx():
		return
	look_at(Global.player_position)
	rotation.x = 0
	rotation.z = 0

func respawn_right_arm(wait_time : float) -> void:
	await get_tree().create_timer(wait_time).timeout
	$Torso/RightArm.visible = true

func reset_anim_in(seconds : float) -> void:
	await get_tree().create_timer(seconds).timeout
	$Animations.play("RESET")

func reset_anim() -> void:
	$Animations.play("RESET")

func reset_cooldown() -> void:
	attack_cooldown = false

func can_walk_again() -> void:
	can_walk = true
