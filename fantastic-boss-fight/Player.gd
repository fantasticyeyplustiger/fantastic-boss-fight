extends CharacterBody3D

const JUMP_VELOCITY : float = 16.0
const GRAVITY : float = 23.5
const WALK_SPEED : float = 15.0
const DASH_SPEED : float = 50.0

const SLIDE_JUMP_SPEED_LIMIT : float = 50.0

## In seconds.
const DASH_TIME : float = 0.2
const SLIDE_JUMP_TIME_WINDOW : float = 0.3

const PLAYER_HEAD_POSITION : Vector3 = Vector3(0.0, 0.8, 0.0)
const SLIDING_HEAD_POSITION : Vector3 = Vector3(0.0, 0.4, 0.0)
const FORWARD_DIRECTION : Vector3 = Vector3(0.0, 0.0, -1.0)

const MAX_STAMINA : float = 3.0

var dash_direction : Vector3 = Vector3.ZERO
var slide_velocity : Vector3 = Vector3.ZERO

var CAMERA_SENSITIVITY : float = 0.003

var speed : float = 15.0
var jump : float = 16.0
var dash_multiplier : float = 1.0
var slide_jump_time : float = 0.0
var slam_time : float = 0.0

var health : float = 1000.0
var stamina : float = 30.0

var can_move : bool = true
var parrying : bool = false
var parry_cooldown : bool = false
var sliding : bool = false
var slide_jumped : bool = false
var slam_jump : bool = false

var dashing : bool = false
var dash_jumped : bool = false
var was_on_floor : bool = false
var should_fall : bool = true
var crushing : bool = false

@onready var head : Node3D = $Head
@onready var camera : Camera3D = $Head/Camera3D
@onready var aim : RayCast3D = $Head/Camera3D/AimRay
@onready var punch_ray : RayCast3D = $Head/Camera3D/PunchRay

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$PlayerGUI.hp.text = "HP: " + str(int(roundf(health)))
	
	## Whenever any hitscan weapon is shot with, hitscan() gets called.
	Global.connect("hitscan", hitscan)
	## Whenever any player fist punches, punch() is called.
	Global.connect("punch", punch)

## Handles camera rotation from player.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * CAMERA_SENSITIVITY)
		camera.rotate_x(-event.relative.y * CAMERA_SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-90), deg_to_rad(85))
		
		$FrontOfBodyPivot.rotation.y = head.rotation.y
		$FrontOfBodyPivot/SecondPivot.rotation.x = camera.rotation.x

## Movement logic
func _physics_process(delta: float) -> void:
	
	# Just so it doesn't have to repeat the same call over and over
	var on_floor = is_on_floor()
	
	#region Jump logic
	## Can't hold jump in Ultrakill so you can't in here
	## This is for a higher skill ceiling
	
	# Dash Jump - Jump while dashing for heavy increased speed. Uses a stamina bar, however.
	if Input.is_action_just_pressed("jump") and dashing and was_on_floor:
		if stamina > 1.0:
			stamina -= 1.0
			dash_multiplier = 1.1
			dash_jumped = true
			$JumpSFX.play()
			velocity.y = jump
		else:
			pass # Play stamina fail SFX
	# Slide Jump - Jump right after starting a slide to keep the increased momentum the slide gives.
	elif Input.is_action_just_pressed("jump") and on_floor and sliding:
		$JumpSFX.play()
		$ResetSlideJump.stop()
		velocity.y = jump / 1.2
		slide_jumped = true
	# Slam Jump - Jump right after slamming the ground for extra height.
	elif Input.is_action_just_pressed("jump") and on_floor and slam_jump:
		$JumpSFX.play()
		velocity.y = jump * (1.5 + slam_time)
		slam_jump = false
	# Regular Jump
	elif Input.is_action_just_pressed("jump") and on_floor:
		$JumpSFX.play()
		velocity.y = jump
	#endregion
	
	#region Dash logic
	if Input.is_action_just_pressed("dash") and not dashing:
		
		if stamina < 1.0:
			pass # Play stamina fail SFX
		else:
			stamina -= 1.0
			
			$DashSFX.play()
			
			was_on_floor = is_on_floor()
			
			dash_direction = get_movement_direction()
		
			# Must dash even if no movement input
			if dash_direction == Vector3.ZERO:
				dash_direction = (head.transform.basis * FORWARD_DIRECTION).normalized()
			
			dashing = true
			can_move = false
			
			# Because player will collide with the floor otherwise and slow down dramatically
			velocity.y = 0.2
			
			# Resets after DASH_TIME seconds.
			reset_dash()
	
	if dashing:
		dash()
	#endregion
	
	#region Slide and Crush/Slam logic
	if on_floor and Input.is_action_just_pressed("crush"):
		begin_slide()
		sliding = true
	elif not Input.is_action_pressed("crush") or not on_floor:
		sliding = false
		$SlideSFX.stop()
		$Head/Camera3D.position = PLAYER_HEAD_POSITION
		switch_hurtboxes(true)
	
	# Prevents player from always being in slide_jump state
	if on_floor and slide_jumped:
		slide_jump_time += delta
		
		if slide_jump_time >= SLIDE_JUMP_TIME_WINDOW:
			slide_jumped = false
			slide_jump_time = 0
	
	# Can't be on floor, otherwise LandingSFX can be spammed
	if not on_floor and Input.is_action_just_pressed("crush"):
		velocity.y = -70.0
		slam_time += delta
		crushing = true
		dashing = false # Cancels dash
	if on_floor and crushing:
		SpawnObject.air_shockwave(global_position, Vector3.ZERO)
		$LandingSFX.play()
		crushing = false
		slam_jump = true
		$ResetSlamTime.start()
	
	#endregion
	
	#region Movement Logic
	if not on_floor and should_fall:
		velocity.y -= GRAVITY * delta
	
	if not dashing and not sliding:
		var direction = get_movement_direction()
		
		# Allow player to slightly tilt direction without losing speed boost
		if slide_jumped:
			# Must go forward and keep momentum
			if direction == Vector3.ZERO:
				direction = (head.transform.basis * FORWARD_DIRECTION).normalized()
			
			velocity.x = lerpf(velocity.x, direction.x * velocity.length(), 0.03)
			velocity.z = lerpf(velocity.z, direction.z * velocity.length(), 0.03)
		
		elif on_floor and can_move:
			dash_jumped = false
			
			if direction:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			else:
				velocity.x = 0.0
				velocity.z = 0.0
		
		# Being in mid-air means you have inertia
		elif dash_jumped or sliding:
			# Must conserve momentum
			if not direction == Vector3.ZERO:
				velocity.x = lerpf(velocity.x, direction.x * speed, delta)
				velocity.z = lerpf(velocity.z, direction.z * speed, delta)
			# Air resistance (less compared to elif can_move because dash jump)
			else:
				velocity.x = lerpf(velocity.x, velocity.x * 0.98, delta * 5.0)
				velocity.z = lerpf(velocity.z, velocity.z * 0.98, delta * 5.0)
				
		
		elif can_move:
			# Conserve momentum with air resistance
			if direction == Vector3.ZERO:
				velocity.x = lerpf(velocity.x, velocity.x * 0.9, delta * 5.0)
				velocity.z = lerpf(velocity.z, velocity.z * 0.9, delta * 5.0)
				
			# Player has inertia in the air
			else:
				velocity.x = lerpf(velocity.x, direction.x * speed, delta * 3.0)
				velocity.z = lerpf(velocity.z, direction.z * speed, delta * 3.0)
	#endregion
	
	if stamina < 3.0 and not sliding:
		stamina += delta * 0.5
	
	$PlayerGUI.stamina.text = "STAMINA: " + str(snappedf(stamina, 0.1))
	
	set_global_variables()
	
	move_and_slide()

## Begins sliding.
## If player jumps during SLIDE_JUMP_TIME_WINDOW, velocity increases.
func begin_slide() -> void:
	if sliding: return
	
	$ResetSlideJump.start()
	
	var direction = get_movement_direction()
	
	# Must slide somewhere no matter what
	if direction == Vector3.ZERO:
			direction = (head.transform.basis * FORWARD_DIRECTION).normalized()
	
	if slide_jumped and not velocity.is_equal_approx(Vector3.ZERO):
		
		var angle : float = velocity.normalized().angle_to(direction)
		
		if velocity.length() < SLIDE_JUMP_SPEED_LIMIT:
			velocity = direction * speed
			velocity *= 2.5 + slam_time
		velocity = velocity.rotated(Vector3(0.0, 1.0, 0.0), angle)
	else:
		velocity = direction * speed * (1.6 + slam_time)
	
	velocity.y = 0.0
	
	$SlideSFX.play()
	$Head/Camera3D.position = SLIDING_HEAD_POSITION
	switch_hurtboxes(false) # Because player is on the floor when sliding

## Dashes in the direction the player is moving for 0.2 seconds.
## If not moving, dash forward.
func dash() -> void:
	velocity.x = dash_direction.x * DASH_SPEED * dash_multiplier
	velocity.z = dash_direction.z * DASH_SPEED * dash_multiplier

func reset_dash() -> void:
	await get_tree().create_timer(DASH_TIME).timeout
	
	dash_multiplier = 1.0
	dashing = false
	can_move = true
	
	if not dash_jumped:
		velocity = Vector3.ZERO

## Set global variables for general use
func set_global_variables() -> void:
	
	Global.player_in_air = not is_on_floor()
	Global.player_position = global_position
	Global.front_of_player = $FrontOfBodyPivot/FrontOfBody.global_position
	Global.player_rotation = camera.global_rotation
	Global.boss_to_player = $FrontOfBodyPivot/FrontOfBody2.global_position - Vector3(0.0, 0.3, 0.0)
	Global.player_velocity = velocity
	
	if aim.is_colliding():
		Global.player_target_position = aim.get_collision_point()
	else:
		Global.player_target_position = aim.target_position

## Gets the movement direction from the player. Calculates from both input and camera rotation.
func get_movement_direction() -> Vector3:
	var input_direction : Vector2 = Input.get_vector("left", "right", "up", "down")
	var direction : Vector3 = (head.transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	return direction

## Hits the enemy with a hitscan.
## Should be called when shooting the pistol or railgun in Weapons.gd.
func hitscan(damage : float) -> void:
	if aim.is_colliding():
		if not aim.get_collider().is_in_group("background"):
			# If it can be hit by AimRay and isn't the background,
			# it's an enemy's hitbox.
			var area := aim.get_collider()
			
			if area.has_method(Global.HITSCAN_THE_ENEMY_METHOD):
				area.call(Global.HITSCAN_THE_ENEMY_METHOD, damage)
			
			Global.emit_signal("hitscan_enemy_particles")
			
		else:
			Global.emit_signal("hitscan_environment_particles")

func punch() -> void:
	if punch_ray.is_colliding():
		if not punch_ray.get_collider().is_in_group("background"):
			# If it can be hit by PunchRay and isn't the background,
			# it's an enemy's hitbox.
			var area := punch_ray.get_collider()
			
			if area.has_method(Global.PUNCH_THE_ENEMY_METHOD):
				area.call(Global.PUNCH_THE_ENEMY_METHOD)
			if area.has_method(Global.GET_TOP_NODE_METHOD):
				
				var enemy = area.call(Global.GET_TOP_NODE_METHOD)
				
				if not "parried" in enemy:
					return
				
				if enemy.parried and Global.current_fist == Global.fists.PARRY_FIST:
					$Head/Camera3D/LeftHand.hit_parry()
					stamina = 3.0
					health = 100.0
					$PlayerGUI.hp.text = "HP: " + str(int(roundf(health)))

## Damages the player if possible.
func get_hit(area: Area3D) -> void:
	if not dashing:
		
		health -= area.get_parent().damage
		$PlayerGUI.hp.text = "HP: " + str(int(roundf(health)))
		
		get_knockbacked(area.global_position, area.launch_power, area.knockback_power)
	else:
		$PlayerGUI.parry.text = "I-FRAMED!"
		reset_parry_text()
	
	if health <= 0.0:
		can_move = false

## Knocks the player back / up depending on parameters given.
## Position of knockback should always the other hitbox's global position.
func get_knockbacked(position_of_kb : Vector3, launch_power : float, knockback_power : float) -> void:
	velocity -= (position_of_kb - global_position).normalized() * knockback_power
	velocity.y = launch_power
	move_and_slide()

func reset_parry_text() -> void:
	await get_tree().create_timer(1.0).timeout
	$PlayerGUI.parry.text = ""

## For swapping between standing and sliding hitboxes.
func switch_hurtboxes(standing : bool) -> void:
	$Hurtbox/Standing.set_deferred("disabled", standing)
	$Hurtbox/Sliding.set_deferred("disabled", not standing)

## Sets slide jump to false. Not actually needed, just more convenient with Timer node
func reset_slide_jump() -> void:
	slide_jumped = false

func reset_slam_time() -> void:
	slam_time = 0.0
