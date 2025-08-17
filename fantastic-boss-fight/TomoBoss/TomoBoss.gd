extends Boss

enum attacks {CHOP}

var previous_attack : attacks
var current_attack : attacks

func _ready() -> void:
	$Aura.visible = true # Particles annoying in editor
	$AnimationPlayer.play("Walking")
	set_atk_cooldown_in_seconds(2.0)

func _physics_process(_delta: float) -> void:
	super(_delta)

func choose_attack() -> void:
	$Aura.amount = 32
	await attack_combo()
	
	set_atk_cooldown_in_seconds(2.0)

func attack_combo() -> void:
	can_walk = false
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
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	
	await seconds(0.4)
	
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

func can_walk_again_in_seconds(seconds_to_wait : float) -> void:
	await super(seconds_to_wait)
	$AnimationPlayer.play("Walking")
	$Aura.amount = 16
