extends Node3D

enum weapons {PISTOL, SHOTGUN, SAW, RAILGUN, ORB}

const LMB_DAMAGES : Dictionary[weapons, float] = {
	weapons.PISTOL : 1.5,
	weapons.SHOTGUN : 0.25, # Per pellet, Total DMG = 4.0 (12 pellets)
	weapons.SAW : 1.0,
	weapons.RAILGUN : 10.0
	# Orb has its own damage logic
}

const RMB_DAMAGES : Dictionary[weapons, float] = {
	weapons.PISTOL : 3.0, # Base damage
	weapons.SHOTGUN : 3.0, # Base damage
	# Saw's RMB does something else
	weapons.RAILGUN : 10.0
	# Orb's RMB does something else
}

# In seconds.
const LMB_COOLDOWNS : Dictionary[weapons, float] = {
	weapons.PISTOL : 0.65,
	weapons.SHOTGUN : 1.25,
	weapons.SAW : 0.25,
	weapons.RAILGUN : 1.0, # Railgun has a separate cooldown
	weapons.ORB : 1.0
}

# In seconds.
const RMB_COOLDOWNS : Dictionary[weapons, float] = {
	weapons.PISTOL : 0.5,
	weapons.SHOTGUN : 1.0,
	weapons.SAW : 0.5,
	weapons.RAILGUN : 1.0, # Railgun has a separate cooldown
	weapons.ORB : 0.5
}

# In seconds.
const RAILGUN_MAX_COOLDOWN : float = 16.0

var pistol_trail = load("res://Player/WeaponProjectiles/PistolTrail.tscn")

var weapon_size : int = weapons.size()
var current_weapon : weapons = weapons.PISTOL
var attack_cooldown : float = 0.0
var railgun_cooldown : float = 0.0

## Weapon switching logic
func _input(event: InputEvent) -> void:
	@warning_ignore_start("int_as_enum_without_cast")
	
	if event.is_action_pressed("scroll_up"):
		current_weapon = (current_weapon + 1) % weapon_size
	
	if event.is_action_pressed("scroll_down"):
		
		current_weapon = current_weapon - 1
		
		if current_weapon < 0:
			current_weapon = weapons.ORB
			
	@warning_ignore_restore("int_as_enum_without_cast")

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("RMB"): # RMB attacks should take priority over LMB
		if attack_cooldown < 0.0:
			
			match current_weapon:
				weapons.PISTOL: pass
				weapons.SHOTGUN: pass
				weapons.SAW: pass
				weapons.RAILGUN: pass
				weapons.ORB: pass
			
			set_attack_cooldown(false)
	
	
	elif Input.is_action_pressed("LMB"):
		if attack_cooldown < 0.0:
		
			match current_weapon:
				weapons.PISTOL: LMB_pistol()
				weapons.SHOTGUN: pass
				weapons.SAW: pass
				weapons.RAILGUN: pass
				weapons.ORB: pass
			
			set_attack_cooldown(true)
	
	if attack_cooldown >= 0.0:
		attack_cooldown -= delta

func LMB_pistol() -> void:
	
	var trail = pistol_trail.instantiate()
	trail.initialize($Armature/Skeleton3D/IndexFingerEnd.global_position,
				Global.player_target_position)
	
	SpawnObject.add_child(trail)
	$Animations.play("LMBGunShoot")
	Global.emit_signal("hitscan", LMB_DAMAGES[weapons.PISTOL])


## Sets the attack cooldown according to the weapon fired.
# LMB_fired true sets attack_cooldown to LMB_COOLDOWNS, RMB_COOLDOWNS otherwise
func set_attack_cooldown(LMB_fired : bool) -> void:
	if LMB_fired:
		attack_cooldown = LMB_COOLDOWNS[current_weapon]
	else:
		attack_cooldown = RMB_COOLDOWNS[current_weapon]
