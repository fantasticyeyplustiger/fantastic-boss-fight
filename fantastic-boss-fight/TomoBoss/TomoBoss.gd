extends Boss

enum attacks {CHOP, COMBO, FACE_KICK, CLAP, DESTROY}

var gradient : Gradient
var colors : PackedColorArray
var magic_hands_mat : Material
var magic_legs_mat : Material
var magic_shoes_mat : Material

var previous_attack : attacks
var current_attack : attacks

var first_phase : bool = true

var prev_i : int = 0

func _ready() -> void:
	
	gradient = $Armature/Skeleton3D/ComboKick/Trail.color_ramp.gradient
	colors = gradient.colors
	magic_hands_mat = $Armature/Skeleton3D/Body.get_surface_override_material(11)
	magic_legs_mat = $Armature/Skeleton3D/Outfit.get_surface_override_material(4)
	magic_shoes_mat = $Armature/Skeleton3D/Outfit.get_surface_override_material(5)
	
	health = 200.0
	$BossHealthBar.set_max_hp(health)
	
	connect_areas_to_hurt_func()
	
	$AnimationPlayer.play("Walking")
	$AnimationPlayer.speed_scale /= Global.difficulty_speed
	$ExplosionPrepare.speed_scale /= Global.difficulty_speed
	
	rainbow_trail_color()
	
	set_atk_cooldown_in_seconds(1.5)

func _physics_process(_delta: float) -> void:
	super(_delta)

func choose_attack() -> void:
	previous_attack = current_attack
	
	var _distance_to_player = get_distance_to_player()
	
	var i : int = randi_range(0, 6)
	
	while i == prev_i:
		i = randi_range(0, 6)
	
	prev_i = i
	
	match i:
		0: await attack_combo()
		1: await clap()
		2: await face_kick()
		3: await grab()
		4: await stomp()
		5: await chop()
		6: await large_explosion()
	
	#await attack_combo()
	#await clap()
	#await face_kick()
	#await grab()
	#await stomp()
	#await chop()
	#await large_explosion()
	
	set_atk_cooldown_in_seconds(0.5)

#region all attacks

#region attack combo
## Does karate_punch(), knee(), combo_kick(), and ground_stomp() in a row.[br]
## Additionally does grab() if hardest difficulty is on.
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
	
	if Global.player_position.y > 15.0:
		await chop()
		await seconds(0.1)
	
	await ground_stomp()
	await grab(true)

func karate_punch() -> void:
	damage = 30.0
	
	# Trail should toggle BEFORE switching positions so player knows where boss went
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails, 25)
	
	await seconds(0.05) # Because it needs time to toggle apparently idk why
	
	$AttackSFX.play_sfx("BossDash")
	global_position.y = 0.0
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	
	var old_position : Vector3 = global_position
	
	go_to_predicted_position_at_seconds(0.35)
	look_at_player()
	global_position.y = 0.0 # Stay on ground
	SpawnObject.rock_trail(old_position, global_position)
	
	await seconds(0.2)
	
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	
	$AttackSFX.play_sfx("BloodyDash")
	$AnimationPlayer.play("LeftStraight")
	$AnimationPlayer.advance(0) # So the trail isn't bugged by going from end_pos to start_pos
	look_at_player()
	dash_towards_on_ground(Global.player_position)
	toggle_trail($LeftStraightTrail)
	
	await seconds(0.1)
	
	dashing = false
	toggle_hitbox_on_for_seconds($Hitbox/LeftStraight, 0.1)
	
	await seconds(0.065)
	
	SpawnObject.particle_shockwave(
		$LeftStraightShockwavePosition.global_position,
	 	global_rotation + RIGHT_X_ANGLE,
		"#FFFFFF",
		1.2,
		true
	)
	SpawnObject.particle_shockwave(
		$LeftStraightShockwavePosition.global_position,
	 	global_rotation + RIGHT_X_ANGLE,
		"#FFFFFF",
		0.4,
		true
	)
	SpawnObject.particle_shockwave(
		$LeftStraightShockwavePosition.global_position,
	 	global_rotation + RIGHT_X_ANGLE,
		"#FFFFFF",
		0.2,
		true
	)
	
	await seconds(0.035)
	
	toggle_trail($LeftStraightTrail)

func knee() -> void:
	damage = 25.0
	
	await seconds(0.25)
	
	$AttackSFX.play_sfx("BloodyDash")
	$AnimationPlayer.play("RightKnee")
	
	look_at_player()
	dash_towards_on_ground(Global.player_position, 45.0)
	
	$RockSpawnPositions/RightKnee.spawn_rocks_for(0.35)
	toggle_hitbox_on_for_seconds($Hitbox/RightKnee, 0.3)
	toggle_all_trails_in($KneeTrails)
	
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	
	await seconds(0.35)
	
	toggle_all_trails_in($KneeTrails)
	dashing = false

func combo_kick() -> void:
	damage = 30.0
	
	# Trail should toggle BEFORE switching positions so player knows where boss went
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails, 25)
	
	await seconds(0.15)
	
	$AttackSFX.play_sfx("BossDash")
	
	look_at_player()
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	
	set_new_position_with_trail(global_position, Global.boss_to_player)
	
	$AnimationPlayer.play("LeftRoundhouse") # Technically not but whatever
	await seconds(0.15)
	
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	
	$AttackSFX.play_sfx("BloodyDash")
	
	dash_towards(Global.player_position, 20.0)
	toggle_all_trails_in($Armature/Skeleton3D/ComboKick)
	toggle_hitbox_on_for_seconds($Hitbox/LeftRoundhouse, 0.25)
	
	if not Global.player_in_air:
		$RockSpawnPositions/Center.spawn_rocks_for(0.3)
	
	await seconds(0.32)
	
	toggle_all_trails_in($Armature/Skeleton3D/ComboKick)
	dashing = false

func ground_stomp() -> void:
	damage = 35.0
	
	# Trail should toggle BEFORE switching positions so player knows where boss went
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails, 25)
	
	await seconds(0.1)
	
	$AttackSFX.play_sfx("BossDash")
	$AnimationPlayer.speed_scale = 0.75 / Global.difficulty_speed
	$AnimationPlayer.play("GroundStomp")
	
	set_new_position_with_trail(global_position, Global.boss_to_player)
	
	global_position.y = 0.0
	should_look_at_player_2D = true
	
	await seconds(0.1)
	can_be_parried = true
	
	await seconds(0.3)
	
	should_look_at_player_2D = false
	can_be_parried = false
	
	if parried:
		parried = false
		$AnimationPlayer.pause()
		await seconds(0.25)
		$AnimationPlayer.play()
	
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	$AttackSFX.play_sfx("BloodyDash")
	$AnimationPlayer.speed_scale = 1.0 / Global.difficulty_speed
	
	dash_towards_on_ground(Global.player_position, 25.0)
	toggle_all_trails_in($Armature/Skeleton3D/GroundStomp)
	$RockSpawnPositions/Center.spawn_rocks_for(0.2)
	
	await seconds(0.1)
	
	toggle_hitbox_on_for_seconds($Hitbox/GroundStomp, 0.1)
	
	await seconds(0.1)
	
	toggle_all_trails_in($Armature/Skeleton3D/GroundStomp)
	SpawnObject.colliding_shockwave(global_position, Vector3.ZERO)
	dashing = false
#endregion

func grab(from_combo : bool = false) -> void:
	
	if from_combo:
		pass
	# else: play voiceline
	
	# Trail should toggle BEFORE switching positions so player knows where boss went
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails, 25)
	await seconds(0.1)
	
	can_walk = false
	damage = 50.0
	
	set_new_position_with_trail(global_position, Global.boss_to_player)
	global_position.y = 0.0
	should_look_at_player_2D = true
	
	$UnparriableSFX.play()
	$ParrySparkles/Grab.emitting = true
	$AttackSFX.play_sfx("BossDash")
	$AnimationPlayer.play("Grab")
	
	await seconds(0.6)
	
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	$AttackSFX.play_sfx("BloodyDash")
	should_look_at_player_2D = false
	
	dash_towards_on_ground(Global.player_position, 18.0)
	set_dash_acceleration(0.99)
	toggle_hitbox_on_for_seconds($Hitbox/Grab, 0.2)
	toggle_all_trails_in($Armature/Skeleton3D/Grab)
	$RockSpawnPositions/Center.spawn_rocks_for(0.2)
	
	await seconds(0.2)
	
	dashing = false
	
	await seconds(0.1)
	
	toggle_all_trails_in($Armature/Skeleton3D/Grab)

func face_kick() -> void:
	#voiceline
	damage = 50.0
	can_walk = false
	should_fall = true
	current_attack = attacks.FACE_KICK
	
	# Trail should toggle BEFORE switching positions so player knows where boss went
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails, 5)
	await seconds(0.05)
	
	$AnimationPlayer.play("FaceKick")
	
	look_at_player()
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	set_new_position_with_trail(global_position, Global.boss_to_player)
	$AttackSFX.play_sfx("BossDash")
	look_at_player()
	
	dash_towards(Global.player_position)
	
	can_be_parried = true
	
	await seconds(0.1)
	
	dashing = false
	should_look_at_player_2D = true
	
	await seconds(0.2)
	
	toggle_trail($FaceKickTrail)
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	should_look_at_player_2D = false
	
	await seconds(0.17)
	
	$Explosion.play()
	SpawnObject.particle_shockwave($FaceKickShockwavePosition.global_position,)
	SpawnObject.explosion_detailed($FaceKickShockwavePosition.global_position, "#FF0000", 0.5, true)
	SpawnObject.explosion_detailed($FaceKickShockwavePosition.global_position, "#FFFFC5", 0.45, true)
	SpawnObject.explosion_detailed($FaceKickShockwavePosition.global_position, "#FFFFFF", 0.11, true)
	
	toggle_hitbox_on_for_seconds($Hitbox/FaceKick, 0.1)
	toggle_trail($FaceKickTrail)
	
	can_be_parried = false
	
	if parried:
		parried = false
		await seconds(0.25)
	
	await seconds(0.3)

func clap() -> void:
	current_attack = attacks.CLAP
	damage = 40.0
	can_walk = false
	
	# Trail should toggle BEFORE switching positions so player knows where boss went
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails, 15)
	
	await seconds(0.1) # Because it needs time to toggle apparently idk why
	
	$Voicelines.play_sfx("Begone1")
	$AnimationPlayer.play("Clap")
	$AnimationPlayer.speed_scale = 1.5 / Global.difficulty_speed
	$AttackSFX.play_sfx("BossDash")
	SpawnObject.air_shockwave(global_position, Vector3.ZERO)
	global_position = Global.predict_player_position_at_seconds_for_boss(0.1)
	should_look_at_player = true
	can_be_parried = true
	
	await seconds(0.35)
	
	toggle_trail($Armature/Skeleton3D/ClapRightHand/Trail)
	toggle_trail($Armature/Skeleton3D/ClapLeftHand/Trail)
	
	await seconds(0.1)
	
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	$AnimationPlayer.speed_scale = 1.0 / Global.difficulty_speed
	should_look_at_player = false
	dash_towards(Global.player_position)
	
	await seconds(0.05)
	
	$AttackSFX.play_sfx("BloodyDash")
	
	await seconds(0.1)
	
	can_be_parried = false
	dashing = false
		
	toggle_hitbox_on_for_seconds($Hitbox/Clap, 0.15)
	
	var spawn_position : Vector3 = $ClapShockwavePosition.global_position
	var spawn_rotation := global_rotation + RIGHT_X_ANGLE + RIGHT_Y_ANGLE
	
	SpawnObject.colliding_shockwave(spawn_position, spawn_rotation, 1.2)
	
	if parried:
		parried = false
		await seconds(0.25)
	
	await seconds(0.15)
	
	toggle_trail($Armature/Skeleton3D/ClapRightHand/Trail)
	toggle_trail($Armature/Skeleton3D/ClapLeftHand/Trail)

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
	toggle_hitbox_on_for_seconds($Hitbox/Uppercut, 0.4)
	
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
	toggle_hitbox_on_for_seconds($Hitbox/MiniExplosion, 0.4)
	
	await seconds(0.75)
	
	dashing = false
	
	await seconds(0.12)
	
	damage = 60.0
	SpawnObject.explosion(global_position)
	toggle_hitbox_on_for_seconds($Hitbox/MiniExplosion, 0.2)
	
	await seconds(0.6)

func taunt() -> void:
	$AnimationPlayer.play("Taunt")

func stomp() -> void:
	damage = 50
	can_walk = false
	
	# Trail should toggle BEFORE switching positions so player knows where boss went
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails, 30)
	
	await seconds(0.1) # Because it needs time to toggle apparently idk why
	
	$UnparriableSFX.play()
	$AttackSFX.play_sfx("BossDash")
	$AnimationPlayer.play("Stomp")
	
	SpawnObject.air_shockwave(global_position)
	SpawnObject.particle_shockwave(global_position, Vector3.ZERO, "#FFFFFF", 1.0, true)
	
	global_position = Global.predict_player_position_at_seconds(0.5)
	global_position.y += 15.0
	
	var target_position := global_position
	target_position.y = 0.5
	
	SpawnObject.blue_flash(target_position, RIGHT_X_ANGLE, 6.0)
	
	await seconds(0.7)
	
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	
	var height : float = global_position.y
	
	SpawnObject.air_shockwave(global_position)
	SpawnObject.particle_shockwave(global_position, Vector3.ZERO, "#FFFFFF", 1.0, true)
	SpawnObject.particle_shockwave(global_position)
	
	global_position.y = 0.0
	$Hitbox/AirStomp.shape.height = height * 2 # Multiply by 2 because "center" of shape is on floor
	toggle_hitbox_on_for_seconds($Hitbox/AirStomp, 0.1) 
	
	SpawnObject.spiky_rock_group(global_position)
	SpawnObject.ground_shockwave(global_position)
	SpawnObject.air_shockwave(global_position)
	SpawnObject.particle_shockwave(global_position)
	SpawnObject.colliding_shockwave(global_position)
	
	$Explosion.play()
	
	await seconds(0.5)
	
	$AnimationPlayer.speed_scale = 0.5 / Global.difficulty_speed
	$AnimationPlayer.play("StompEnd")
	
	await seconds(0.5)
	
	$AnimationPlayer.speed_scale = 1.0 / Global.difficulty_speed

func chop() -> void:
	
	can_walk = false
	damage = 35
	
	# Trail should toggle BEFORE switching positions so player knows where boss went
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails, 45)
	
	await seconds(0.1) # Because it needs time to toggle apparently idk why
	
	should_look_at_player = true
	
	SpawnObject.particle_shockwave(global_position)
	
	$UnparriableSFX.play()
	$ParrySparkles/Chop.emitting = true
	$AttackSFX.play_sfx("BossDash")
	$AnimationPlayer.play("Chop")
	global_position = Global.predict_player_position_at_seconds_for_boss(0.41)
	
	await seconds(0.4)
	
	$AttackSFX.play_sfx("BloodyDash")
	
	should_look_at_player = false
	
	dash_towards(Global.player_position)
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	
	toggle_trail($Armature/Skeleton3D/Chop/Trail)
	toggle_hitbox_on_for_seconds($Hitbox/Chop, 0.1)
	
	await seconds(0.2)
	
	stop_dashing()
	toggle_trail($Armature/Skeleton3D/Chop/Trail)
	
	await seconds(0.1)
	
func large_explosion() -> void:
	damage = 60.0
	can_walk = false
	
	$Voicelines.play_sfx("ThisWillHurt1")
	$AttackSFX.play_sfx("BossDash")
	$AnimationPlayer.play("LargeExplosion")
	global_position = Global.boss_to_player
	should_look_at_player_2D = true
	
	glow_for(1.6, 0.4, 0.4)
	
	$ExplosionPrepare.emitting = true
	
	await seconds(1.5)
	
	$ExplosionPrepare.emitting = false
	
	await seconds(0.3)
	
	can_be_parried = true
	
	await seconds(0.2)
	
	can_be_parried = false
	
	if parried:
		$AnimationPlayer.stop()
		parried = false
		await seconds(0.25)
		return
	
	var explosion_position := global_position + Vector3(0.0, 1.5, 0.0)
	
	toggle_hitbox_on_for_seconds($Hitbox/LargeExplosion, 0.1)
	SpawnObject.explosion_detailed(explosion_position, "#FF0000", 2.0, true)
	SpawnObject.explosion_detailed(explosion_position, "#FFFFC5", 1.7, true)
	SpawnObject.explosion_detailed(explosion_position, "#FFFFFF", 0.55, true)
	SpawnObject.explosion_detailed(explosion_position, "#FFFFFF", 0.5)
	$Explosion.play()
	
	await seconds(0.85)
	
	should_look_at_player_2D = false
	should_fall = true
	
	await seconds(0.6)
	
#endregion

func can_walk_again_in_seconds(seconds_to_wait : float) -> void:
	await super(seconds_to_wait)
	$AnimationPlayer.play("Walking")
	$Aura.amount = 16
	
func stop_walk_animation() -> void:
	$AnimationPlayer.stop(true)

## Sets global_position to 'new_position' and spawns a rock trail between the
## old position and new position if both relatively close to the ground.
func set_new_position_with_trail(old_position : Vector3, new_position : Vector3) -> void:
	if old_position.y <= 1.5 and new_position.y <= 1.5:
		SpawnObject.rock_trail(old_position, new_position)
	global_position = new_position

## This tweens the color gradients of all trails (except air ones) through the color of the rainbow.
func rainbow_trail_color() -> void:
	
	const RAINBOW : PackedColorArray = [
		Color.RED, Color.ORANGE,
		Color.YELLOW, Color.GREEN,
		Color.SKY_BLUE, Color.VIOLET,
		Color.PURPLE]
	
	var iterator : int = 0
	
	while true:
		
		var color_one = RAINBOW[iterator]
		
		iterator += 1
		
		if iterator >= RAINBOW.size():
			iterator = 0
		
		var color_two = RAINBOW[iterator]
		
		var tween : Tween = get_tree().create_tween()
		
		tween.tween_method(
			set_trail_color,
			color_one,
			color_two,
			3.0
		)
		
		await tween.finished
	
## Sets the color of all non-air trails and any included meshes with those trails to [param new_color].
func set_trail_color(new_color : Color) -> void:
	gradient.set_color(1, new_color)
	magic_hands_mat.emission = new_color
	magic_legs_mat.emission = new_color
	magic_shoes_mat.emission = new_color
	

## Makes the boss' materials transition into pure glowing white.[br][br]
## 'transition_seconds': transition time to pure glow[br]
## 'stay_seconds': stays in pure glow for this time[br]
## 'end_transition_seconds': transition time to invisible[br]
func glow_for(transition_seconds : float, stay_seconds : float, end_transition_seconds) -> void:
	
	## Affects outfit and hair materials too because all of their material overlays
	## are from the same material.
	var material : StandardMaterial3D = $Armature/Skeleton3D/Body.material_overlay
	var tween : Tween = get_tree().create_tween()
	
	tween.tween_property(
		material,
		"albedo_color",
		Color("FFFFFFFF"),
		transition_seconds * Global.difficulty_speed
	)
	
	await tween.finished
	
	await seconds(stay_seconds)
	
	tween = get_tree().create_tween()
	
	tween.tween_property(
		material,
		"albedo_color",
		Color("FFFFFF00"),
		end_transition_seconds * Global.difficulty_speed
	)
	
	await tween.finished

func get_punched() -> void:
	
	var punch_damage = Global.FIST_DAMAGE[Global.current_fist]
	
	if Global.current_fist == Global.fists.PARRY_FIST and can_be_parried:
		can_be_parried = false
		parried = true
		punch_damage *= 5.0
	
	health -= punch_damage
	$BossHealthBar.lower_hp(health)

func get_hitscanned(hitscan_damage : float) -> void:
	health -= hitscan_damage
	$BossHealthBar.lower_hp(health)

func get_hurt(area : Area3D) -> void:
	health -= area.get_parent().damage
	$BossHealthBar.lower_hp(health)
	

func connect_areas_to_hurt_func() -> void:
	var hitboxes : Node3D = $BossHitbox
	var script = load("res://DamageEnemy.gd")
	
	for bone in hitboxes.get_children():
		
		var area := bone.get_child(0)
		
		if not area is Area3D:
			continue
		
		area.script = script
		area.area_entered.connect(get_hurt)
		area.top_node = self
