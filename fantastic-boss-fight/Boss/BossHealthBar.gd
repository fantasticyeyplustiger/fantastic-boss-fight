extends Control

const HEALTH_BAR_MAX_SIZE : Vector2 = Vector2(1720.0, 60.0)
## A float constant that just means "ignore."
const IGNORE_F : float = -1.0

@export var has_two_health_bars : bool = false

var tween : Tween

var max_health : float
var current_health : float

var default_hp_bar_size


func _ready() -> void:
	if has_two_health_bars:
		$HealthBar2.visible = true

func set_max_hp(new_health : float) -> void:
	max_health = new_health

## This function assumes that 'new_health' is lower than 'current_health'. 
func lower_hp(new_health : float) -> void:
	
	assert(new_health <= max_health, "hey buddy why is the new health BIGGER THAN THE MAX HEALTH")
	
	var old_health := current_health
	
	current_health = new_health
	
	var health_difference := absf(old_health - current_health)
	var change_health_percent := max_health / health_difference
	var current_health_percent := max_health / current_health
	
	var check_hp_should_transition : bool = current_health_percent - change_health_percent <= 0.5
	var check_hp_high_enough : bool = current_health_percent > 0.5
	
	var change_first_health_bar_percent : float = IGNORE_F
	var change_other_health_bar_percent : float = IGNORE_F
	
	# Only for the scenario that boss gets damaged enough to transition to second hp bar.
	if check_hp_should_transition and check_hp_high_enough and has_two_health_bars:
		change_first_health_bar_percent = current_health_percent - 0.5
		change_other_health_bar_percent = change_health_percent - change_first_health_bar_percent
	
	var health_bar_to_lower : ColorRect
	var lower_both_bars : bool = (not change_first_health_bar_percent == IGNORE_F)
	
	var new_x := HEALTH_BAR_MAX_SIZE.x
	
	if lower_both_bars:
		
		# If both bars are being lowered, this one is automatically eliminated
		tween = get_tree().create_tween()
		tween.tween_property(
			$HealthBar1,
			"size",
			Vector2(0.0, HEALTH_BAR_MAX_SIZE.y),
			0.25
		)
		
		await tween.finished
		$HealthBar1.visible = false
		
		new_x *= change_other_health_bar_percent
		
		tween = get_tree().create_tween()
		tween.tween_property(
			$HealthBar2,
			"size",
			Vector2(new_x, HEALTH_BAR_MAX_SIZE.y),
			0.25
		)
		
		return
	
	# If there's only one health bar, just use this one.
	elif not has_two_health_bars:
		health_bar_to_lower = $HealthBar1
		
	# If there's two health bars, the health for each bar is divided by 2.
	elif (current_health > max_health / 2.0):
		health_bar_to_lower = $HealthBar1
	
	# If boss hp is already under half, second health bar has to change
	else:
		health_bar_to_lower = $HealthBar2
	
	if tween.is_running():
		await tween.finished
	
	new_x *= current_health_percent - change_health_percent
	
	tween = get_tree().create_tween()
	tween.tween_property(
		health_bar_to_lower,
		"size",
		Vector2(new_x, HEALTH_BAR_MAX_SIZE.y),
		0.5
	)
	
