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
var walking_time : float = 0.0
var running_time : float = 0.0


var prev_i : int = 0

func _ready() -> void:
	
	attacking = false
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
	
	for parry_flash in $ParrySparkles.get_children():
		if not parry_flash == GPUParticles3D:
			continue
		parry_flash.speed_scale /= Global.difficulty_speed
	
	rainbow_trail_color()
	
	set_atk_cooldown_in_seconds(0.5)

func _physics_process(_delta: float) -> void:
	super(_delta)
	
	# prevent constant function calls
	var velocity_length := velocity.length()
	
	if not attacking:
		
		if velocity_length < 15.0 and can_walk: 
			$AnimationPlayer.play("Walking")
			$AnimationPlayer.speed_scale = 1.0
		elif velocity_length > 15.0 and can_walk:
			$AnimationPlayer.play("Running")
			$AnimationPlayer.speed_scale = 1.5
	

func choose_attack() -> void:
	previous_attack = current_attack
	
	$AnimationPlayer.speed_scale /= Global.difficulty_speed
	$ExplosionPrepare.speed_scale /= Global.difficulty_speed
	
	var _distance_to_player = get_distance_to_player()
	
	var i : int = randi_range(0, 7)
	
	while i == prev_i:
		i = randi_range(0, 7)
	
	prev_i = i
	
	#match i:
		#0: await attack_combo()
		#1: await clap()
		#2: await face_kick()
		#3: await grab()
		#4: await stomp()
		#5: await chop()
		#6: await low_kick()
		#7: await large_explosion()
	
	await attack_combo()
	#await clap()
	#await face_kick()
	#await grab()
	#await stomp()
	#await chop()
	#await large_explosion()
	#await low_kick()
	#await taunt()
	
	set_atk_cooldown_in_seconds(0.5)
	can_walk_again_in_seconds(0.25)

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
	
	global_position.y = 0.0
	
	await seconds(0.75)
	
	await karate_punch()
	await knee()
	await combo_kick()
	
	if Global.player_position.y > 15.0:
		await chop()
		await seconds(0.1)
	
	await ground_stomp()
	await seconds(0.5)
	#await grab(true)

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
	$AnimationPlayer.speed_scale = 1.25 / Global.difficulty_speed
	look_at_player()
	dash_towards_on_ground(Global.player_position)
	toggle_all_trails_in($Armature/Skeleton3D/LeftStraight)
	
	await seconds(0.1)
	
	dashing = false
	toggle_hitbox_on_for_seconds($Hitbox/LeftStraight, 0.1)
	
	await seconds(0.35)
	
	toggle_all_trails_in($Armature/Skeleton3D/LeftStraight)

func knee() -> void:
	damage = 25.0
	
	$AnimationPlayer.play("RightKnee")
	should_look_at_player_2D = true
	
	await seconds(0.1)
	
	$AttackSFX.play_sfx("BloodyDash")
	
	should_look_at_player_2D = false
	dash_towards_on_ground(Global.player_position, 55.0)
	set_dash_acceleration(0.94)
	
	$RockSpawnPositions/RightKnee.spawn_rocks_for(0.35)
	toggle_hitbox_on_for_seconds($Hitbox/RightKnee, 0.3)
	toggle_trail($Armature/Skeleton3D/Knee/Trail)
	
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	
	await seconds(0.35)
	
	toggle_trail($Armature/Skeleton3D/Knee/Trail)
	dashing = false

func combo_kick() -> void:
	damage = 30.0
	
	# Trail should toggle BEFORE switching positions so player knows where boss went
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails, 25)
	
	await seconds(0.15)
	
	$AttackSFX.play_sfx("BossDash")
	
	if global_position.y > 1.5:
		should_look_at_player = true
	else:
		should_look_at_player_2D = true
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	
	set_new_position_with_trail(global_position, Global.boss_to_player)
	
	$AnimationPlayer.play("LeftRoundhouse")
	$AnimationPlayer.speed_scale = 1.4 / Global.difficulty_speed
	await seconds(0.15)
	
	if global_position.y > 1.5:
		should_look_at_player = false
	else:
		should_look_at_player_2D = false
		
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	
	$AttackSFX.play_sfx("BloodyDash")
	toggle_all_trails_in($Armature/Skeleton3D/ComboKick)
	
	dash_towards(Global.player_position, 30.0)
	set_dash_acceleration(0.95)
	
	toggle_hitbox_on_for_seconds($Hitbox/LeftRoundhouse, 0.25)
	
	if not Global.player_in_air:
		$RockSpawnPositions/Center.spawn_rocks_for(0.25)
	
	await seconds(0.25)
	
	dashing = false
	
	await seconds(0.17)
	
	toggle_all_trails_in($Armature/Skeleton3D/ComboKick)

func ground_stomp() -> void:
	damage = 35.0
	
	# Trail should toggle BEFORE switching positions so player knows where boss went
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails, 25)
	
	await seconds(0.1)
	
	$AttackSFX.play_sfx("BossDash")
	$AnimationPlayer.speed_scale = 1.1 / Global.difficulty_speed
	$AnimationPlayer.play("GroundStomp")
	
	set_new_position_with_trail(global_position, Global.boss_to_player)
	
	global_position.y = 0.0
	should_look_at_player_2D = true
	
	await seconds(0.1)
	$ParrySparkles/GroundStomp.emitting = true
	can_be_parried = true
	
	await seconds(0.2)
	
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
	SpawnObject.colliding_shockwave($GroundStompShockwavePosition.global_position)
	SpawnObject.explosion_detailed(
		$GroundStompShockwavePosition.global_position,
		"#FFFFFF64",
		0.45,
		true
	)
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
	$ParrySparkles/FaceKick.emitting = true
	
	await seconds(0.1)
	
	dashing = false
	should_look_at_player_2D = true
	
	await seconds(0.2)
	
	toggle_all_trails_in($Armature/Skeleton3D/ComboKick)
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	should_look_at_player_2D = false
	
	await seconds(0.17)
	
	$Explosion.play()
	SpawnObject.particle_shockwave($FaceKickShockwavePosition.global_position,)
	SpawnObject.explosion_detailed($FaceKickShockwavePosition.global_position, "#FF0000", 0.5, true)
	SpawnObject.explosion_detailed($FaceKickShockwavePosition.global_position, "#FFFFC5", 0.45, true)
	SpawnObject.explosion_detailed($FaceKickShockwavePosition.global_position, "#FFFFFF", 0.11, true)
	
	toggle_hitbox_on_for_seconds($Hitbox/FaceKick, 0.1)
	toggle_all_trails_in($Armature/Skeleton3D/ComboKick)
	
	can_be_parried = false
	
	if parried:
		parried = false
		$AnimationPlayer.play("FaceKickRecoil")
		recoil_against($FaceKickShockwavePosition.global_position, 50.0)
		should_fall = true
		
		$RockSpawnPositions/Center.spawn_rocks_for(1.2)
		
		if global_position.y < 1.5:
			set_dash_acceleration(0.95)
		else:
			set_dash_acceleration(0.99)
		
		await seconds(1.2)
		
		dashing = false
	
	await seconds(0.3)
	
	should_fall = false

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
	$ParrySparkles/Clap.emitting = true
	
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
	SpawnObject.explosion_detailed(
		spawn_position,
		"#FFFFFF64",
		0.4,
		true
	)
	
	if parried:
		parried = false
		await seconds(0.25)
	
	await seconds(0.15)
	
	toggle_trail($Armature/Skeleton3D/ClapRightHand/Trail)
	toggle_trail($Armature/Skeleton3D/ClapLeftHand/Trail)

func destroy() -> void:
	$Voicelines.play_sfx("Destroy1")
	current_attack = attacks.DESTROY
	

func taunt() -> void:
	
	should_fall = true
	can_walk = false
	should_look_at_player_2D = true
	
	if global_position.y > 0.25:
		$AnimationPlayer.play("Falling")
	
	while true:
		await seconds(0.25) # Allow her time to fall
		
		if global_position.y <= 0.25:
			break
	
	global_position.y = 0.0
	
	await seconds(0.25)
	$AnimationPlayer.play("Taunt")
	$Voicelines.play_sfx("NiceTry1")
	await seconds(2.0)
	
	should_fall = false
	should_look_at_player_2D = false
	

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
	
	should_look_at_player_2D = true
	
	SpawnObject.particle_shockwave(global_position)
	
	$UnparriableSFX.play()
	$ParrySparkles/Chop.emitting = true
	$AttackSFX.play_sfx("BossDash")
	$AnimationPlayer.play("Chop")
	global_position = Global.predict_player_position_at_seconds_for_boss(0.15)
	
	await seconds(0.5)
	
	$AttackSFX.play_sfx("BloodyDash")
	
	should_look_at_player_2D = false
	
	dash_towards(Global.player_position)
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	
	toggle_trail($Armature/Skeleton3D/Chop/Trail)
	toggle_hitbox_on_for_seconds($Hitbox/Chop, 0.1)
	
	await seconds(0.2)
	
	stop_dashing()
	
	await seconds(0.2)
	
	toggle_trail($Armature/Skeleton3D/Chop/Trail)
	
func low_kick() -> void:
	
	can_walk = false
	damage = 30
	
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	
	await seconds(0.1)
	
	set_new_position_with_trail(global_position, Global.boss_to_player)
	
	if Global.boss_to_player.y < 0.0:
		global_position = Vector3(Global.boss_to_player.x, 0.0, Global.boss_to_player.z)
	else:
		global_position = Global.boss_to_player
	
	$AttackSFX.play_sfx("BossDash")
	$AnimationPlayer.play("LowKick")
	$AnimationPlayer.advance(0.2 / Global.difficulty_speed)
	$AnimationPlayer.speed_scale = -0.3 / Global.difficulty_speed
	
	#if global_position.y > 5.0:
		#should_look_at_player = true
	#else:
	look_at_player()
	
	var wait_time : float = 0.35
	
	if Global.difficulty_speed > 1.0:
		wait_time *= Global.difficulty_speed
	
	await seconds(wait_time, false) # Should always be at least this much or else impossible to dodge
	
	toggle_all_trails_in($Armature/Skeleton3D/AirTrails)
	
	#if global_position.y > 5.0:
		#dash_towards(Global.player_position, 10.0)
	
	#if global_position.y < 0.5:
		#SpawnObject.colliding_shockwave(global_position, Vector3.ZERO, 1.0, true)
	
	toggle_all_trails_in($Armature/Skeleton3D/LowKick)
	$AnimationPlayer.play()
	$AnimationPlayer.speed_scale = 3.5 / Global.difficulty_speed
	
	await seconds(0.1)
	
	$AttackSFX.play_sfx("BloodyDash")
	toggle_hitbox_on_for_seconds($Hitbox/LowKick, 0.15)
	$AnimationPlayer.speed_scale = 1.0 / Global.difficulty_speed
	dashing = false
	
	await seconds(0.15)
	
	toggle_all_trails_in($Armature/Skeleton3D/LowKick)


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
		should_look_at_player_2D = false
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
	
	should_fall = false
	
#endregion

func can_walk_again_in_seconds(seconds_to_wait : float) -> void:
	await super(seconds_to_wait)
	can_walk = true
	attacking = false
	
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
	TomoTrailHead.material_hue = new_color.h
	

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
