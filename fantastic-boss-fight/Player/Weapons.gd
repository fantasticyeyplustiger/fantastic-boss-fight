extends Node3D

enum weapons {PISTOL, SHOTGUN, SAW, RAILGUN, ORB}

const LMB_DAMAGES : Dictionary[weapons, float] = {
	weapons.PISTOL : 1.5,
	weapons.SHOTGUN : 0.5, # Per pellet, Total DMG = 5.0 (10 pellets)
	weapons.SAW : 1.0,
	weapons.RAILGUN : 10.0
	# Orb has its own damage logic
}

const RMB_DAMAGES : Dictionary[weapons, float] = {
	weapons.PISTOL : 2.5, # Base damage
	weapons.SHOTGUN : 3.0, # Base damage
	# Saw's RMB does something else
	weapons.RAILGUN : 10.0
	# Orb's RMB does something else
}

# In seconds.
const LMB_COOLDOWNS : Dictionary[weapons, float] = {
	weapons.PISTOL : 0.65,
	weapons.SHOTGUN : 1.75,
	weapons.SAW : 0.25,
	weapons.RAILGUN : 1.0, # Railgun has a separate cooldown
	weapons.ORB : 1.0
}

# In seconds.
const RMB_COOLDOWNS : Dictionary[weapons, float] = {
	weapons.PISTOL : 1.5,
	weapons.SHOTGUN : 1.0,
	weapons.SAW : 0.5,
	weapons.RAILGUN : 1.0, # Railgun has a separate cooldown
	weapons.ORB : 0.5
}

# In seconds.
const RAILGUN_MAX_COOLDOWN : float = 2.0

@onready var finger_tip : Node3D = $Armature/Skeleton3D/IndexFingerEnd/FingerTip
@onready var railgun_pos : Node3D = $RailgunPosition

var pistol_trail_LMB = load("res://Player/WeaponProjectiles/PistolTrailLMB.tscn")
var pistol_trail_RMB = load("res://Player/WeaponProjectiles/PistolTrailRMB.tscn")
var railgun_trail = load("res://Player/WeaponProjectiles/RailgunTrail.tscn")

var sawblade = load("res://Player/WeaponProjectiles/SawBlade.tscn")

var weapon_size : int = weapons.size()
var current_weapon : weapons = weapons.PISTOL
var attack_cooldown : float = 0.0
var railgun_cooldown : float = 0.0
var saw_orbit_time : float = 0.0

var was_orbiting : bool = false

func _ready() -> void:
	attack_cooldown = LMB_COOLDOWNS[weapons.PISTOL]

## Weapon switching logic
func _input(event: InputEvent) -> void:
	@warning_ignore_start("int_as_enum_without_cast")
	
	if event.is_action_pressed("scroll_up"):
		current_weapon = (current_weapon + 1) % weapon_size
		switch_weapon()
	
	elif event.is_action_pressed("scroll_down"):
		current_weapon = current_weapon - 1
		
		if current_weapon < 0:
			current_weapon = weapons.ORB
		
		switch_weapon()
	
	
	if event.is_action_pressed("pistol"):    switch_weapon_to(weapons.PISTOL)
	elif event.is_action_pressed("shotgun"): switch_weapon_to(weapons.SHOTGUN)
	elif event.is_action_pressed("saw"):     switch_weapon_to(weapons.SAW)
	elif event.is_action_pressed("railgun"): switch_weapon_to(weapons.RAILGUN)
	elif event.is_action_pressed("orb"):     switch_weapon_to(weapons.ORB)
	
	
	@warning_ignore_restore("int_as_enum_without_cast")

func _physics_process(delta: float) -> void:
	
	if was_orbiting and saw_orbit_time == 0.0:
		$Animations.speed_scale = 1.0
		$Animations.play("RMBSawShoot")
		was_orbiting = false
	
	if Input.is_action_pressed("RMB"): # RMB attacks should take priority over LMB
		if attack_cooldown < 0.0:
			$Animations.speed_scale = 1.0 # Reset in case it was changed while shooting
			
			if not current_weapon == weapons.SAW:
				saw_orbit_time = 0.0
				Global.sawblades_orbiting = false
			
			match current_weapon:
				weapons.PISTOL: RMB_pistol()
				weapons.SHOTGUN: pass
				weapons.SAW: RMB_saw(delta)
				weapons.RAILGUN: pass
				weapons.ORB: pass
			
			set_attack_cooldown(false)
	
	
	elif Input.is_action_pressed("LMB"):
		if attack_cooldown < 0.0:
			$Animations.speed_scale = 1.0 # Reset in case it was changed while shooting
			
			saw_orbit_time = 0.0
			Global.sawblades_orbiting = false
			
			match current_weapon:
				weapons.PISTOL:  LMB_pistol()
				weapons.SHOTGUN: pass
				weapons.SAW:     LMB_saw()
				weapons.RAILGUN: LMB_railgun()
				weapons.ORB: pass
			
			set_attack_cooldown(true)
	
	else:
		saw_orbit_time = 0.0
		Global.sawblades_orbiting = false
	
	if attack_cooldown >= 0.0:
		attack_cooldown -= delta
	
	if railgun_cooldown >= 0.0:
		railgun_cooldown -= delta

func LMB_pistol() -> void:
	spawn_hitscan_trail(pistol_trail_LMB, finger_tip.global_position)
	$Animations.play("LMBGunShoot")
	Global.emit_signal("hitscan", LMB_DAMAGES[weapons.PISTOL])

func RMB_pistol() -> void:
	spawn_hitscan_trail(pistol_trail_RMB, finger_tip.global_position)
	$Animations.play("RMBGunShoot")
	Global.emit_signal("hitscan", RMB_DAMAGES[weapons.PISTOL])
	
	SpawnObject.pistol_explosion()


func LMB_saw() -> void:
	var new_sawblade = sawblade.instantiate()
	new_sawblade.initialize(
		Global.front_of_player + Vector3(0.0, 0.5, 0.0),
		LMB_DAMAGES[weapons.SAW]
	)
	SpawnObject.add_child(new_sawblade)
	
	$Animations.play("LMBSawShoot")

func RMB_saw(delta : float) -> void:
	Global.sawblades_orbiting = true
	
	if saw_orbit_time == 0.0:
		$Animations.play("LMBtoRMBSaw")
		was_orbiting = true
	
	saw_orbit_time += delta

func LMB_railgun() -> void:
	
	if railgun_cooldown > 0.0:
		return # Play fail sound effect (?)
	else:
		railgun_cooldown = RAILGUN_MAX_COOLDOWN
	
	spawn_hitscan_trail(railgun_trail, railgun_pos.global_position)
	$Animations.speed_scale = 2.0
	$Animations.play("LMBRailgunShoot")
	Global.emit_signal("hitscan", LMB_DAMAGES[weapons.RAILGUN])

## Switches the current weapon and plays swap animation.
## Assumes current weapon has already been switched.
func switch_weapon() -> void:
	
	var swap_anim : String = "LMB"
	
	match current_weapon:
		weapons.PISTOL:  swap_anim += "Gun"
		weapons.SHOTGUN: swap_anim += "Shotgun"
		weapons.SAW:     swap_anim += "Saw"
		weapons.RAILGUN: swap_anim += "Railgun"
		weapons.ORB:     swap_anim += "Orb"
	
	attack_cooldown = LMB_COOLDOWNS[current_weapon] / 5.0
	
	$SwapWeapon.play("swap")
	$Animations.play(swap_anim)

## Switches the current weapon to the new weapon inputted.
## See switch_weapon() for further detail.
func switch_weapon_to(new_weapon : weapons) -> void:
	current_weapon = new_weapon
	switch_weapon()

## Spawns a HitscanTrail.
## position_on_hand : where the HitscanTrail's first side should start.
func spawn_hitscan_trail(trail_type, position_on_hand : Vector3) -> void:
	var trail = trail_type.instantiate()
	trail.initialize(position_on_hand, Global.player_target_position)
	SpawnObject.add_child(trail)

## Sets the attack cooldown according to the weapon fired.
## LMB_fired true sets attack_cooldown to LMB_COOLDOWNS, RMB_COOLDOWNS otherwise
func set_attack_cooldown(LMB_fired : bool) -> void:
	if LMB_fired:
		attack_cooldown = LMB_COOLDOWNS[current_weapon]
	else:
		attack_cooldown = RMB_COOLDOWNS[current_weapon]
