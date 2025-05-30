extends CharacterBody3D

var damage : float = 50.0
var toward_player : bool = true
var already_hit : bool = false
var shockwave_cooldown : bool = false

var target_direction : Vector3

func _physics_process(_delta: float) -> void:
	if toward_player:
		velocity = (Global.player_position - global_position) * 5.5
		velocity.y += 0.8 # Add 0.8 because that's where the CAMERA of the player is
		look_at(Global.player_position)
	else:
		velocity = target_direction * 50.0
	
	if not shockwave_cooldown:
		shockwave_cooldown = true
		spawn_shockwave()
	move_and_slide()

func spawn_shockwave() -> void:
	SpawnObject.air_shockwave(global_position, $RightArmMesh.global_rotation)

func hit(area: Area3D) -> void:
	$GPUParticles3D.emitting = false
	
	if already_hit:
		return
	
	already_hit = true
	
	if area.get_parent().parrying:
		spawn_shockwave()
		toward_player = false
		target_direction = Global.front_of_player - Global.player_position
		look_at(target_direction)
	else:
		explode(Node3D.new()) # Node3D doesn't actually do anything, it's only because of the signal used

func explode(_body : Node3D) -> void:
	if not already_hit:
		return
	$RightArmMesh.visible = false
	$Explosion.visible = true
	set_physics_process(false)
	$Animation.play("explosion")

func destroy_self(_anim_name : StringName) -> void:
	queue_free()
