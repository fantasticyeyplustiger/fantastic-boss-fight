extends Control

## A float constant that just means "ignore."
const IGNORE_F : float = -1.0

@export var has_two_health_bars : bool = false
@export var health_bar_name : String = "INSERT BOSS NAME HERE IN ALL CAPS"

var tween : Tween

var max_health : float
var current_health : float

var default_hp_bar_size


func _ready() -> void:
	$MarginContainer2/HBoxContainer/Label.text = health_bar_name
	
	if has_two_health_bars:
		$HealthBar2.visible = true
		$TransitionHealth2.visible = true

func set_max_hp(new_health : float) -> void:
	max_health = new_health
	current_health = new_health

## This function assumes that 'new_health' is lower than 'current_health'.
## May not work properly otherwise.
func lower_hp(new_health : float) -> void:
	
	assert(new_health <= max_health, "hey buddy why is the new health BIGGER THAN THE MAX HEALTH")
	assert(current_health > new_health, "how does this even happen vro")
	
	var old_health := current_health
	
	current_health = new_health
	
	var health_difference := old_health - current_health
	
	var change_health_percent := health_difference / max_health
	var old_health_percent := old_health / max_health
	var current_health_percent := current_health / max_health
	
	# If enough damage was dealt for first health bar to transition to second,
	# both health bars have to be lowered and tweened accordingly.
	var check_hp_should_transition : bool = old_health_percent - change_health_percent <= 0.5
	var check_hp_high_enough : bool = old_health_percent > 0.5
	
	var change_other_health_bar_percent : float = IGNORE_F
	
	# Only for the scenario that boss gets damaged enough to transition to second hp bar.
	if check_hp_should_transition and check_hp_high_enough and has_two_health_bars:
		var transition_hp : float = old_health_percent - 0.5
		change_other_health_bar_percent = 1.0 - (change_health_percent - transition_hp)
	
	var health_bar_to_change : ProgressBar
	var transition_bar : ProgressBar
	var lower_both_bars : bool = (not change_other_health_bar_percent == IGNORE_F)
	
	var new_value : float
	
	if lower_both_bars:
		
		# If both bars are being lowered, automatically means this one has to be eliminated
		tween = get_tree().create_tween()
		tween.tween_property(
			$TransitionHealth2,
			"value",
			0.0,
			0.1
		)
		
		await tween.finished
		$HealthBar2.value = 0.0
		$HealthBar2.visible = false
		$TransitionHealth2.visible = false
		
		new_value = change_other_health_bar_percent * 100.0
		
		tween = get_tree().create_tween()
		tween.tween_property(
			$TransitionHealth1,
			"value",
			new_value,
			health_difference / 15.0
		)
		
		$HealthBar1.value = new_value
		
		return
	
	# If there's only one health bar, just use this one.
	elif not has_two_health_bars:
		transition_bar = $TransitionHealth1
		health_bar_to_change = $HealthBar1
		
	# If there's two health bars, the health for each bar is divided by 2.
	elif (current_health > max_health / 2.0):
		transition_bar = $TransitionHealth2
		health_bar_to_change = $HealthBar2
	
	# If boss hp is already under half, second health bar has to change
	else:
		transition_bar = $TransitionHealth1
		health_bar_to_change = $HealthBar1
	
	# Check twice because if previous call had 'lower_both_bars' true it will make two tweens
	if not tween == null:
		if tween.is_running():
			await tween.finished
		if tween.is_running():
			await tween.finished
	
	new_value = current_health_percent
	
	new_value *= 100.0 # Because its a percentage.
	
	# Two health bars are two separate halves of hp
	if has_two_health_bars and current_health_percent <= 0.5:
		new_value *= 2.0
	elif has_two_health_bars and current_health_percent > 0.5:
		new_value = (current_health_percent - 0.5) / 0.5
		new_value *= 100.0 # Because its a percentage.
	
	tween = get_tree().create_tween()
	tween.tween_property(
		transition_bar,
		"value",
		new_value,
		0.2
	)
	
	health_bar_to_change.value = new_value
