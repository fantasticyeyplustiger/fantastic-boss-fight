extends CharacterBody3D

const LOW_DAMAGE : float = 25.0
const MED_DAMAGE : float = 50.0
const HIGH_DAMAGE : float = 100.0

const GRAVITY : float = 19.6

var health : float = 1_000_000

var attacking : bool = false
var jump_attacking : bool = false
var attack_cooldown

var current_attack : int

func _physics_process(delta: float) -> void:
	
	if not is_on_floor() or not jump_attacking:
		velocity.y -= GRAVITY * delta
	
	if not attacking and not attack_cooldown:
		attack_loop()
		attacking = true
	

func attack_loop() -> void:
	match current_attack:
		1: pass
		2: pass
		3: pass
		4: pass # RESET
	pass
