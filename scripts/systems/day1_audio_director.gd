extends Node3D

# A short, deterministic wood-like impact, generated once per tone.
const SAMPLE_RATE := 22050
const KNOCK_DURATION := 0.085

var _player: AudioStreamPlayer3D
var _tones: Array[AudioStreamWAV] = []
var _playing := false


func _ready() -> void:
	_player = AudioStreamPlayer3D.new()
	_player.name = "KnockPlayer"
	# Keep ordinary room-scale distances audible without close-range amplification.
	_player.unit_size = 5.0
	_player.max_db = 0.0
	_player.max_distance = 25.0
	add_child(_player)
	_tones = [_make_knock(false), _make_knock(true)]


# position is in world coordinates. Concurrent requests are ignored until the
# last impact has finished, so repeated interactions cannot stack loud sounds.
func play_knocks(count: int, position: Vector3, interval: float = 0.38, volume_db: float = -12.0, tone_variant: int = 0) -> void:
	if _playing or count <= 0 or not is_inside_tree() or _player == null:
		return
	_playing = true
	_player.global_position = position
	_player.volume_db = minf(volume_db, -6.0)
	_player.stream = _tones[0 if tone_variant == 0 else 1]
	for i in range(count):
		_player.play()
		if i < count - 1:
			await get_tree().create_timer(maxf(interval, 0.01)).timeout
	await get_tree().create_timer(KNOCK_DURATION).timeout
	_playing = false


func _make_knock(reply: bool) -> AudioStreamWAV:
	var samples := int(SAMPLE_RATE * KNOCK_DURATION)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var noise_state := 104729
	var fundamental := 245.0 if reply else 270.0
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		# Fixed integer noise adds a little attack without any random asset state.
		noise_state = (noise_state * 16807) % 2147483647
		var noise := float(noise_state) / 1073741823.5 - 1.0
		var attack := minf(t / 0.002, 1.0)
		var body := sin(TAU * fundamental * t) * exp(-t * 48.0)
		var overtone := sin(TAU * fundamental * 2.37 * t) * exp(-t * 70.0)
		var transient := noise * exp(-t * 150.0)
		var end_fade := minf((KNOCK_DURATION - t) / 0.005, 1.0)
		var sample := attack * end_fade * (0.28 * body + 0.12 * overtone + 0.06 * transient)
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
