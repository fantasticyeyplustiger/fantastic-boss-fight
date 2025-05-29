extends CharacterBody3D

var damage : float = 50.0
var toward_player : bool = true
var already_hit : bool = false

var target_direction : Vector3

func _physics_process(_delta: float) -> void:
	if toward_player:
		velocity = (Global.player_position - global_position) * 4.0
		velocity.y += 0.8
		look_at(Global.player_position)
	else:
		velocity = target_direction * 50.0
		
		
	
	move_and_slide()

func hit(area: Area3D) -> void:
	$GPUParticles3D.emitting = false
	
	if already_hit:
		return
	
	already_hit = true
	
	if area.get_parent().parrying:
		toward_player = false
		target_direction = Global.front_of_player - Global.player_position
		look_at(target_direction)
	else:
		explode(Node3D.new())

func explode(_body : Node3D) -> void:
	if not already_hit:
		return
	$RightArmMesh.visible = false
	$Explosion.visible = true
	set_physics_process(false)
	$Animation.play("explosion")
	print("exploding")

func destroy_self(_anim_name : StringName) -> void:
	print("destroying self")
	queue_free()
