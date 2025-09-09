extends Area3D

var top_node : Node3D = null

func get_hitscanned(damage : float) -> void:
	assert(not top_node == null, "Top node of this Area3D is null!")
	
	if not top_node.has_method(Global.HITSCAN_THE_ENEMY_METHOD):
		printerr("Top node does not have get_hitscanned() method!")
		return
	
	top_node.call(Global.HITSCAN_THE_ENEMY_METHOD, damage)

func get_punched() -> void:
	assert(not top_node == null, "Top node of this Area3D is null!")
	
	if not top_node.has_method(Global.PUNCH_THE_ENEMY_METHOD):
		printerr("Top node does not have get_punched() method!")
		return
	
	top_node.call(Global.PUNCH_THE_ENEMY_METHOD)

func find_top_node() -> void:
	recursion_find(self)

## Use 'find_top_node' if intending to start this recursion function.
func recursion_find(child_node : Node3D) -> void:
	var parent : Node3D = child_node.get_parent()
	
	if parent == null:
		return
	
	var check_one : bool = parent.has_method(Global.HITSCAN_THE_ENEMY_METHOD)
	var check_two : bool = parent.has_method(Global.PUNCH_THE_ENEMY_METHOD)
	
	if check_one and check_two:
		top_node = parent
	else:
		recursion_find(parent)
		
