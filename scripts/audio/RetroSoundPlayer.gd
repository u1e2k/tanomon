extends Node

## N64/PS1時代のUI操作音・レトロSEをプロシージャルに生成・再生するマネージャー

var _sample_hz: float = 22050.0 # レトロなサンプリングレート

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## カーソル移動音 (チッ / ピッ)
func play_cursor() -> void:
	_play_synth_tone(880.0, 0.04, 0.2, "sine")

## 決定音 (ピロリン)
func play_confirm() -> void:
	_play_synth_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.05, 0.25)

## キャンセル音 (ブッ)
func play_cancel() -> void:
	_play_synth_tone(220.0, 0.08, 0.2, "saw")

## モンスター切り替え音 (シュッ)
func play_switch() -> void:
	_play_synth_noise(0.06, 0.15)

## 単音シンセ生成
func _play_synth_tone(freq: float, duration: float, volume: float, waveform: String = "sine") -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = _sample_hz
	gen.buffer_length = duration + 0.05
	player.stream = gen
	player.volume_db = linear_to_db(volume)
	player.play()
	
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	var total_frames := int(_sample_hz * duration)
	var phase := 0.0
	var phase_step := freq / _sample_hz
	
	for i in range(total_frames):
		var t := float(i) / float(total_frames)
		var envelope := 1.0 - t # 簡易ディケイ
		var sample := 0.0
		
		if waveform == "sine":
			sample = sin(phase * TAU) * envelope
		elif waveform == "saw":
			sample = ((phase * 2.0) - 1.0) * envelope
		elif waveform == "square":
			sample = (1.0 if phase < 0.5 else -1.0) * envelope
		
		phase = fmod(phase + phase_step, 1.0)
		playback.push_frame(Vector2(sample, sample))
	
	get_tree().create_timer(duration + 0.1).timeout.connect(func():
		player.stop()
		player.queue_free()
	)

## アルペジオ（複数音連続）
func _play_synth_arpeggio(freqs: Array, note_duration: float, volume: float) -> void:
	var total_dur := note_duration * freqs.size()
	var player := AudioStreamPlayer.new()
	add_child(player)
	
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = _sample_hz
	gen.buffer_length = total_dur + 0.05
	player.stream = gen
	player.volume_db = linear_to_db(volume)
	player.play()
	
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	
	for freq in freqs:
		var frames := int(_sample_hz * note_duration)
		var phase := 0.0
		var phase_step := float(freq) / _sample_hz
		for i in range(frames):
			var t := float(i) / float(frames)
			var env := (1.0 - t)
			var sample := sin(phase * TAU) * env
			phase = fmod(phase + phase_step, 1.0)
			playback.push_frame(Vector2(sample, sample))
			
	get_tree().create_timer(total_dur + 0.1).timeout.connect(func():
		player.stop()
		player.queue_free()
	)

## ノイズ音
func _play_synth_noise(duration: float, volume: float) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = _sample_hz
	gen.buffer_length = duration + 0.05
	player.stream = gen
	player.volume_db = linear_to_db(volume)
	player.play()
	
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	var total_frames := int(_sample_hz * duration)
	
	for i in range(total_frames):
		var t := float(i) / float(total_frames)
		var env := (1.0 - t) * (1.0 - t)
		var sample := randf_range(-1.0, 1.0) * env
		playback.push_frame(Vector2(sample, sample))
		
	get_tree().create_timer(duration + 0.1).timeout.connect(func():
		player.stop()
		player.queue_free()
	)
