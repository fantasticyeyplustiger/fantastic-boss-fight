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
var jump_attacking : bool = false
var attack_cooldown : bool = true
var can_walk : bool = true

var current_attack : int = 1

func _ready() -> void:
	attack_cd_timer.start(2.0)

func _physics_process(delta: float) -> void:
	
	if not is_on_floor() or not jump_attacking:
		velocity.y -= GRAVITY * delta
	
	if not attacking and not attack_cooldown:
		attacking = true
		attack_loop()
	elif not attacking and can_walk:
		walk_towards_player()


func attack_loop() -> void:
	
	var target_position : Vector3 = Global.player_position
	attack_cooldown = true
	can_walk = false
	
	match current_attack:
		1, 2, 3, 4, 5: 
			if not Global.player_in_air:
				ground_charge(target_position)
			else:
				air_charge(target_position)
		6: pass
		7: pass
		8: pass # RESET
	
	attacking = false

func air_charge(target_position : Vector3) -> void:
	damage = MED_DAMAGE
	look_at(target_position)
	
	var magnitude : float = (target_position - global_position).length()
	var new_position : Vector3 = Vector3(0, 0, (-magnitude * 2.5) + 1.5)
	var new_height : float = magnitude * 4.5
	
	$AirChargePath/Hitbox.position = new_position
	$AirChargePath/Hitbox.shape.height = new_height
	$AirChargePath/VisibleHitbox.position = new_position
	$AirChargePath/VisibleHitbox.mesh.height = new_height
	
	$Animations.play("air_charge")
	
	await get_tree().create_timer(0.3).timeout
	$AirChargePath/Hitbox.set_deferred("disabled", false)
	$Animations.play("RESET")
	
	await get_tree().create_timer(0.05).timeout
	$AirChargePath/Hitbox.set_deferred("disabled", true)
	
	global_position = target_position
	
	walk_cooldown.start(0.2)
	attack_cd_timer.start(0.25)

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
		charge_visible_hitbox.mesh.size = size - Vector3(0.0, 16.0, 0.0)
		$ChargePath/VisibleLandingHitbox.mesh.top_radius = 35.0
		$ChargePath/VisibleLandingHitbox.mesh.bottom_radius = 35.0
		$ChargePath/LandingHitbox.shape.radius = 35.0
	else:
		charge_visible_hitbox.mesh.size = size - Vector3(0.0, 1.0, 0.0)
	
	charge_visible_hitbox.position = hitbox_pos - Vector3(0.0, 6.0, 0.0)
	charge_visible_hitbox.visible = true
	
	$ChargePath/VisibleLandingHitbox.global_position = Vector3(target_position.x, 0.0, target_position.z)
	$ChargePath/VisibleLandingHitbox.global_rotation = Vector3.ZERO
	$ChargePath/LandingHitbox.global_position = Vector3(target_position.x, 0.0, target_position.z)
	$ChargePath/LandingHitbox.global_rotation = Vector3.ZERO
	
	$Animations.play("charge")
	await get_tree().create_timer(0.6).timeout
	charge_hitbox.set_deferred("disabled", false)
	$ChargePath/LandingHitbox.set_deferred("disabled", false)
	
	# reset turns hitbox invisible
	$Animations.play("RESET")
	
	await get_tree().create_timer(0.05).timeout
	
	global_position = Vector3(target_position.x, Y_VALUE_FOR_FLOOR, target_position.z)
	charge_hitbox.set_deferred("disabled", true)
	$ChargePath/LandingHitbox.set_deferred("disabled", true)
	
	walk_cooldown.start(0.5)
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
	#warning_ignore:unused_argument
	look_at(Global.player_position)
	rotation.x = 0
	rotation.z = 0

func reset_cooldown() -> void:
	attack_cooldown = false

func can_walk_again() -> void:
	can_walk = true
