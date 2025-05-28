extends CharacterBody3D

const LOW_DAMAGE : float = 25.0
const MED_DAMAGE : float = 50.0
const HIGH_DAMAGE : float = 100.0

const WALK_SPEED : float = 7.5
const SPRINT_SPEED : float = 35.0

const GRAVITY : float = 19.6

@onready var attack_cd_timer = $AttackCooldown
@onready var walk_cooldown = $CanWalkCooldown

@onready var charge_hitbox = $ChargePath/Hitbox
@onready var charge_visible_hitbox = $ChargePath/VisibleHitbox

var health : float = 1_000_000

var attacking : bool = false
var jump_attacking : bool = false
var attack_cooldown : bool = true
var can_walk : bool = true

var current_attack : int = 1

func _ready() -> void:
	attack_cd_timer.start(3.0)

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
		1: charge(target_position)
		2: pass
		3: pass
		4: pass # RESET
	
	attacking = false

func charge(target_position : Vector3) -> void:
	look_at_player()
	var magnitude = (target_position - global_position).length()
	print(magnitude)
	
	var size : Vector3 = Vector3(12.0, 14.0, magnitude * 5.0)
	var hitbox_pos : Vector3 = Vector3(0, 2.5, (-magnitude * 2.5) + 1.5)
	
	charge_hitbox.shape.size = size
	charge_hitbox.position = hitbox_pos
	
	charge_visible_hitbox.mesh.size = size - Vector3(0.0, 13.0, 0.0)
	charge_visible_hitbox.position = hitbox_pos - Vector3(0.0, 6.0, 0.0)
	charge_visible_hitbox.visible = true
	
	$Animations.play("charge")
	await get_tree().create_timer(0.35).timeout
	charge_hitbox.set_deferred("disabled", false)
	
	#charge_visible_hitbox.visible = false
	$Animations.play("RESET")
	
	await get_tree().create_timer(0.05).timeout
	global_position = Vector3(target_position.x, global_position.y, target_position.z)
	charge_hitbox.set_deferred("disabled", true)
	
	walk_cooldown.start(1.0)
	attack_cd_timer.start(3.0)


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
	look_at(Global.player_position)
	rotation.x = 0
	rotation.z = 0

func reset_cooldown() -> void:
	attack_cooldown = false

func can_walk_again() -> void:
	can_walk = true
