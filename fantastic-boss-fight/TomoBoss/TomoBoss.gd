extends Boss

enum attacks {CHOP, COMBO, FACE_KICK, CLAP, DESTROY}

var previous_attack : attacks
var current_attack : attacks

func _ready() -> void:
	$Aura.visible = false # Particles annoying in editor
	$AnimationPlayer.play("Walking")
	set_atk_cooldown_in_seconds(2.0)

func _physics_process(_delta: float) -> void:
	super(_delta)

func choose_attack() -> void:
	$Aura.amount = 32
	previous_attack = current_attack
	
	var _distance_to_player = get_distance_to_player()
	
	
	
	await attack_combo()
	await seconds(0.5)
	await clap()
	await seconds(0.5)
	await face_kick()
	
	set_atk_cooldown_in_seconds(1.0)

func stop_walk_animation() -> void:
	$AnimationPlayer.stop(true)

#region attack combo
func attack_combo() -> void:
	can_walk = false
	current_attack = attacks.COMBO
	$AnimationPlayer.play("KarateComboStart")
	look_at_player()
	$Voicelines.play_sfx("YouCantEscape1")
	
	await seconds(1.0)
	
	await karate_punch()
	await knee()
	await combo_kick()
	await ground_stomp()
	await grab(true)
	
	can_walk_again_in_seconds(0.5)

func karate_punch() -> void:
	damage = 30.0
	
	$AttackSFX.play_sfx("BossDash")
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	go_to_predicted_position_at_seconds(0.35)
	look_at_player()
	global_position.y = 0.0 # Stay on ground
	
	await seconds(0.2)
	
	$AttackSFX.play_sfx("BloodyDash")
	$AnimationPlayer.play("LeftStraight")
	look_at_player()
	dash_towards_on_ground(Global.player_position)
	dashing = true
	
	await seconds(0.1)
	
	dashing = false
	toggle_hitbox($LeftStraight/CollisionShape3D)
	
	await seconds(0.1)
	
	toggle_hitbox($LeftStraight/CollisionShape3D)

func knee() -> void:
	damage = 25.0
	
	await seconds(0.25)
	
	$AttackSFX.play_sfx("BloodyDash")
	$AnimationPlayer.play("RightKnee")
	dashing = true
	look_at_player()
	dash_towards_on_ground(Global.predict_player_position_at_seconds(0.2))
	
	toggle_hitbox($RightKnee/CollisionShape3D)
	toggle_all_trails_in($KneeTrails)
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	
	await seconds(0.4)
	
	toggle_all_trails_in($KneeTrails)
	toggle_hitbox($RightKnee/CollisionShape3D)
	dashing = false

func combo_kick() -> void:
	damage = 30.0
	
	await seconds(0.15)
	
	$AttackSFX.play_sfx("BossDash")
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	global_position = Global.boss_to_player
	$AnimationPlayer.play("LeftRoundhouse") # Technically not but whatever
	await seconds(0.15)
	
	$AttackSFX.play_sfx("BloodyDash")
	dashing = true
	dash_towards(Global.player_position)
	toggle_hitbox($LeftRoundhouse/CollisionShape3D)
	
	await seconds(0.25)
	
	toggle_hitbox($LeftRoundhouse/CollisionShape3D)
	dashing = false

func ground_stomp() -> void:
	damage = 35.0
	
	await seconds(0.1)
	
	$AttackSFX.play_sfx("BossDash")
	$AnimationPlayer.speed_scale = 0.5
	$AnimationPlayer.play("GroundStomp")
	global_position = Global.boss_to_player
	global_position.y = 0.0
	should_look_at_player = true
	
	await seconds(0.6)
	
	$AttackSFX.play_sfx("BloodyDash")
	should_look_at_player = false
	$AnimationPlayer.speed_scale = 1.0
	dashing = true
	dash_towards_on_ground(Global.player_position)
	toggle_hitbox($GroundStomp/CollisionShape3D)
	
	await seconds(0.2)
	
	SpawnObject.colliding_shockwave(global_position, Vector3.ZERO)
	toggle_hitbox($GroundStomp/CollisionShape3D)
	dashing = false
#endregion

func grab(from_combo : bool) -> void:
	
	if from_combo:
		await seconds(0.3)
	
	damage = 50.0
	global_position = Global.boss_to_player
	global_position.y = 0.0
	look_at_player()
	
	$AttackSFX.play_sfx("BossDash")
	$AnimationPlayer.play("Grab")
	
	await seconds(0.6)
	
	$AttackSFX.play_sfx("BloodyDash")
	look_at_player()
	dashing = true
	dash_towards_on_ground(Global.player_position)
	toggle_hitbox_on_for_seconds($Grab/CollisionShape3D, 0.15)
	
	await seconds(0.15)
	
	dashing = false

func face_kick() -> void:
	#voiceline
	damage = 50.0
	can_walk = false
	should_fall = true
	current_attack = attacks.FACE_KICK
	$AnimationPlayer.play("FaceKick")
	
	look_at_player()
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	global_position = Global.boss_to_player
	$AttackSFX.play_sfx("BossDash")
	look_at_player()
	
	dashing = true
	dash_towards(Global.player_position)
	
	await seconds(0.1)
	dashing = false
	
	await seconds(0.3)
	
	look_at_player()
	$Explosion.play()
	SpawnObject.explosion_detailed(global_position + Vector3(0.0, 1.0, 0.0), "#FF0000", 0.8)
	toggle_hitbox_on_for_seconds($FaceKick/CollisionShape3D, 0.1)

func clap() -> void:
	current_attack = attacks.CLAP
	damage = 40.0
	can_walk = false
	
	$Voicelines.play_sfx("Begone1")
	$AnimationPlayer.play("Clap")
	$AnimationPlayer.speed_scale = 1.5
	$AttackSFX.play_sfx("BossDash")
	SpawnObject.air_shockwave(global_position, Vector3.ZERO)
	global_position = Global.predict_player_position_at_seconds_for_boss(0.1)
	should_look_at_player = true
	
	await seconds(0.45)
	
	$AnimationPlayer.speed_scale = 1.0
	should_look_at_player = false
	dashing = true
	dash_towards(Global.player_position)
	
	await seconds(0.15)
	
	$AttackSFX.play_sfx("BloodyDash")
	dashing = false
	toggle_hitbox_on_for_seconds($Clap/CollisionShape3D, 0.15)
	
	var spawn_position := global_position
	spawn_position.y += 3
	
	var spawn_rotation := global_rotation + RIGHT_X_ANGLE + RIGHT_Y_ANGLE
	
	SpawnObject.colliding_shockwave(spawn_position, spawn_rotation)
	
	await seconds(0.15)

func destroy() -> void:
	$Voicelines.play_sfx("Destroy1")
	current_attack = attacks.DESTROY
	
	await uppercut()
	await mini_explosion()

func uppercut() -> void:
	damage = 30.0
	can_walk = false
	
	$AnimationPlayer.play("Uppercut")
	$AttackSFX.play_sfx("BossDash")
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	
	global_position = Global.boss_to_player
	global_position.y = 0.0
	should_look_at_player = true
	
	await seconds(0.4)
	
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	should_look_at_player = false
	$AttackSFX.play_sfx("BloodyDash")
	dashing = true
	var predicted_position := Global.predict_player_position_at_seconds_for_boss(0.3)
	dash_towards_on_ground(predicted_position)
	toggle_hitbox_on_for_seconds($Uppercut/CollisionShape3D, 0.4)
	
	await seconds(0.4)
	
	dashing = false
	
	await seconds(0.1)

func mini_explosion() -> void:
	damage = 20.0
	can_walk = false
	$AnimationPlayer.play("MiniExplosion")
	should_look_at_player = true
	
	await seconds(0.4)
	
	$AttackSFX.play_sfx("BossDash")
	should_look_at_player = false
	dashing = true
	dash_towards_on_ground(Global.player_position)
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	toggle_hitbox_on_for_seconds($Dash/CollisionShape3D, 0.4)
	
	await seconds(0.75)
	
	dashing = false
	
	await seconds(0.12)
	
	damage = 60.0
	SpawnObject.explosion(global_position)
	toggle_hitbox_on_for_seconds($MiniExplosion/CollisionShape3D, 0.2)
	
	await seconds(0.6)

func taunt() -> void:
	$AnimationPlayer.play("Taunt")

func can_walk_again_in_seconds(seconds_to_wait : float) -> void:
	await super(seconds_to_wait)
	$AnimationPlayer.play("Walking")
	$Aura.amount = 16

## Toggles all of the trails in the parent node.
## Ignores any children nodes that aren't trails.
func toggle_all_trails_in(parent_node : Node3D) -> void:
	
	var children := parent_node.get_children()
	
	for child in children:
		if not child is GPUTrail3D:
			continue
		
		toggle_trail(child)
	
