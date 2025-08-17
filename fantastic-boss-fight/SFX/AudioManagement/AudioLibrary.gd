extends Resource

class_name AudioLibrary

## String: name / key for the stream
@export var sounds : Dictionary[String, AudioStream]

func get_stream(name : String):
	
	# Name (key in sounds) must exist
	assert(not name == null, "'name' cannot be null in AudioLibrary.get_stream()!")
	assert(sounds.has(name), "'name'" + name + "does not exist in AudioLibrary.get_stream()!")
	
	return sounds.get(name)
