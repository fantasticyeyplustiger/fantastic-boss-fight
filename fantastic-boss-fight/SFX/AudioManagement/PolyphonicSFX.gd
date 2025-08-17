extends AudioStreamPlayer3D

class_name PolyphonicSFX

@export var audio_library : AudioLibrary
@export var custom_max_polyphony : int = 8

var has_readied : bool = false

func _ready() -> void:
	stream.polyphony = custom_max_polyphony
	has_readied = true

## Plays the given SFX name if possible.
func play_sfx(sfx_name : String) -> void:
	
	assert(has_readied, "PolyphonicSFX must be 'ready' before playing SFX!")
	assert(not sfx_name == null, "'sfx_name' cannot be null in PolyphonicSFX!")
	
	var audio_stream : AudioStream = audio_library.get_stream(sfx_name)
	
	if not playing:
		self.play()
	
	var polyphonic_stream_playback := self.get_stream_playback()
	polyphonic_stream_playback.play_stream(audio_stream)
