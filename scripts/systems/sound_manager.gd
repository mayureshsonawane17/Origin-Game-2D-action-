extends Node

## SoundManager: Central audio engine for ORIGIN.
## Generates and plays procedural retro 8-bit/16-bit sound effects and era BGM themes.
## 100% self-contained with zero external audio assets required.

signal sfx_played(sfx_name: String)
signal bgm_changed(track_name: String)

const SAMPLE_RATE: int = 22050
const SFX_POOL_SIZE: int = 10

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var bgm_volume: float = 0.8
var is_muted: bool = false

var _sfx_cache: Dictionary = {}
var _bgm_cache: Dictionary = {}

var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_player_a: AudioStreamPlayer
var _bgm_player_b: AudioStreamPlayer
var _active_bgm_player: AudioStreamPlayer
var _current_bgm_name: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Initialize SFX player pool
	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

	# Initialize dual BGM players for crossfading
	_bgm_player_a = AudioStreamPlayer.new()
	_bgm_player_b = AudioStreamPlayer.new()
	_bgm_player_a.bus = "Master"
	_bgm_player_b.bus = "Master"
	add_child(_bgm_player_a)
	add_child(_bgm_player_b)
	_active_bgm_player = _bgm_player_a

	# Pre-synthesize core combat sound effects
	_preload_common_sfx()
	print("[SoundManager] Initialized. Procedural audio engine ready.")

func _preload_common_sfx() -> void:
	var common: Array[String] = [
		"slash_1", "slash_2", "slash_finisher",
		"parry", "block", "dodge", "jump",
		"hurt", "heal", "magic_cast", "switch_weapon",
		"enemy_hit", "enemy_die", "ui_select", "ui_confirm",
		"checkpoint", "loop_glitch", "boss_roar", "boss_phase"
	]
	for sfx in common:
		_get_or_create_sfx(sfx)

# -------------------------------------------------------------------------
# Sound Effects API
# -------------------------------------------------------------------------

func play_sfx(sfx_name: String, pitch_scale: float = 1.0, volume_offset_db: float = 0.0) -> void:
	if is_muted or sfx_volume <= 0.001:
		return

	var stream = _get_or_create_sfx(sfx_name)
	if not stream:
		return

	# Find idle player
	var player: AudioStreamPlayer = null
	for p in _sfx_players:
		if not p.playing:
			player = p
			break
	if not player:
		player = _sfx_players[0] # Steal oldest

	player.stream = stream
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	var final_db = linear_to_db(sfx_volume * master_volume) + volume_offset_db
	player.volume_db = clampf(final_db, -60.0, 6.0)
	player.play()
	sfx_played.emit(sfx_name)

func _get_or_create_sfx(sfx_name: String) -> AudioStreamWAV:
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]

	var stream: AudioStreamWAV = null
	match sfx_name:
		"slash_1":
			stream = _synth_swipe(0.08, 480.0, 180.0, 0.4)
		"slash_2":
			stream = _synth_swipe(0.09, 520.0, 160.0, 0.5)
		"slash_finisher":
			stream = _synth_finisher(0.18)
		"parry":
			stream = _synth_parry(0.25)
		"block":
			stream = _synth_block(0.12)
		"dodge":
			stream = _synth_whoosh(0.14)
		"jump":
			stream = _synth_jump(0.12)
		"hurt":
			stream = _synth_crunch(0.14, 220.0, 70.0)
		"heal":
			stream = _synth_chime_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.32)
		"magic_cast":
			stream = _synth_magic_laser(0.20)
		"switch_weapon":
			stream = _synth_ratchet(0.09)
		"enemy_hit":
			stream = _synth_crunch(0.09, 340.0, 120.0)
		"enemy_die":
			stream = _synth_downward_rumble(0.24)
		"boss_roar":
			stream = _synth_boss_roar(0.55)
		"boss_phase":
			stream = _synth_alarm_sweep(0.40)
		"ui_select":
			stream = _synth_beep(0.04, 880.0)
		"ui_confirm":
			stream = _synth_chime_arpeggio([587.33, 880.0], 0.12)
		"checkpoint":
			stream = _synth_chime_arpeggio([440.0, 554.37, 659.25, 880.0], 0.45)
		"loop_glitch":
			stream = _synth_glitch_screech(0.35)
		_:
			stream = _synth_beep(0.05, 440.0)

	if stream:
		_sfx_cache[sfx_name] = stream
	return stream

# -------------------------------------------------------------------------
# BGM Music API
# -------------------------------------------------------------------------

func play_bgm(track_name: String, fade_duration: float = 0.8) -> void:
	if _current_bgm_name == track_name and _active_bgm_player.playing:
		return

	_current_bgm_name = track_name
	if is_muted or bgm_volume <= 0.001:
		return

	var stream = _get_or_create_bgm(track_name)
	if not stream:
		return

	var outgoing = _active_bgm_player
	var incoming = _bgm_player_b if _active_bgm_player == _bgm_player_a else _bgm_player_a
	_active_bgm_player = incoming

	incoming.stream = stream
	incoming.volume_db = -60.0
	incoming.play()

	var target_db = linear_to_db(bgm_volume * master_volume)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(incoming, "volume_db", target_db, fade_duration)
	if outgoing.playing:
		tween.tween_property(outgoing, "volume_db", -60.0, fade_duration)
		tween.chain().tween_callback(outgoing.stop)

	bgm_changed.emit(track_name)

func stop_bgm(fade_duration: float = 0.6) -> void:
	_current_bgm_name = ""
	if _active_bgm_player and _active_bgm_player.playing:
		var tween = create_tween()
		tween.tween_property(_active_bgm_player, "volume_db", -60.0, fade_duration)
		tween.tween_callback(_active_bgm_player.stop)

func is_bgm_playing() -> bool:
	return _active_bgm_player != null and _active_bgm_player.playing

func get_current_bgm_name() -> String:
	return _current_bgm_name

func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)

func set_bgm_volume(val: float) -> void:
	bgm_volume = clampf(val, 0.0, 1.0)
	if _active_bgm_player and _active_bgm_player.playing:
		_active_bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)

func set_muted(mute: bool) -> void:
	is_muted = mute
	if is_muted and _active_bgm_player:
		_active_bgm_player.volume_db = -60.0
	elif not is_muted and _active_bgm_player and _active_bgm_player.playing:
		_active_bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)

# -------------------------------------------------------------------------
# Procedural Audio Synthesizers (Pure Math & Buffers)
# -------------------------------------------------------------------------

func _synth_swipe(dur: float, start_f: float, end_f: float, gain: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var progress = t / dur
		var freq = lerpf(start_f, end_f, progress)
		var env = sin(progress * PI)
		var noise = randf_range(-0.35, 0.35)
		var wave = sin(t * freq * TAU) + noise
		var s = wave * env * gain
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_finisher(dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var progress = t / dur
		var freq = lerpf(260.0, 50.0, progress)
		var env = exp(-progress * 5.0)
		var wave = sin(t * freq * TAU) * 0.7 + randf_range(-0.4, 0.4)
		var s = wave * env * 0.75
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_parry(dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var env = exp(-t * 14.0)
		var bell = sin(t * 1760.0 * TAU) * 0.5 + sin(t * 2640.0 * TAU) * 0.3 + sin(t * 3520.0 * TAU) * 0.2
		var s = bell * env * 0.8
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_block(dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var env = exp(-t * 22.0)
		var freq = lerpf(140.0, 60.0, t / dur)
		var wave = (1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0) * 0.6 + randf_range(-0.3, 0.3)
		var s = wave * env * 0.6
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_whoosh(dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var env = sin((t / dur) * PI)
		var noise = randf_range(-0.8, 0.8) * env * 0.45
		bytes.encode_s16(i * 2, clampi(int(noise * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_jump(dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var progress = t / dur
		var freq = lerpf(150.0, 420.0, progress)
		var env = 1.0 - progress
		var wave = 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
		var s = wave * env * 0.45
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_crunch(dur: float, start_f: float, end_f: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var progress = t / dur
		var freq = lerpf(start_f, end_f, progress)
		var env = exp(-progress * 8.0)
		var wave = randf_range(-0.6, 0.6) + sin(t * freq * TAU) * 0.4
		var s = wave * env * 0.6
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_chime_arpeggio(notes: Array, dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	var note_dur = dur / float(notes.size())
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var note_idx = clampi(int(t / note_dur), 0, notes.size() - 1)
		var freq = float(notes[note_idx])
		var local_t = fmod(t, note_dur)
		var env = exp(-local_t * 9.0)
		var wave = sin(t * freq * TAU) * 0.6 + sin(t * freq * 2.0 * TAU) * 0.25
		var s = wave * env * 0.55
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_magic_laser(dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var progress = t / dur
		var freq = lerpf(280.0, 1100.0, progress * progress)
		var env = 1.0 - progress
		var wave = sin(t * freq * TAU) * 0.5 + (1.0 if fmod(t * freq * 0.5, 1.0) < 0.5 else -1.0) * 0.2
		var s = wave * env * 0.5
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_ratchet(dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var click1 = exp(-t * 60.0) * randf_range(-0.7, 0.7)
		var click2 = (exp(-(t - 0.04) * 60.0) * randf_range(-0.7, 0.7)) if t > 0.04 else 0.0
		var s = (click1 + click2) * 0.6
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_downward_rumble(dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var progress = t / dur
		var freq = lerpf(240.0, 35.0, progress)
		var env = exp(-progress * 4.0)
		var wave = (1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0) * 0.6 + randf_range(-0.3, 0.3)
		var s = wave * env * 0.55
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_boss_roar(dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var progress = t / dur
		var lfo = sin(t * 12.0 * TAU) * 18.0
		var freq = 85.0 + lfo
		var env = sin(progress * PI)
		var saw = (fmod(t * freq, 1.0) * 2.0 - 1.0) * 0.6
		var noise = randf_range(-0.35, 0.35)
		var s = (saw + noise) * env * 0.7
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_alarm_sweep(dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var progress = t / dur
		var freq = lerpf(330.0, 990.0, progress)
		var env = 1.0 - progress * 0.3
		var wave = (1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0) * 0.5
		var s = wave * env * 0.5
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_beep(dur: float, freq: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var env = 1.0 - (t / dur)
		var wave = sin(t * freq * TAU)
		var s = wave * env * 0.4
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

func _synth_glitch_screech(dur: float) -> AudioStreamWAV:
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var env = exp(-t * 4.0)
		var mod_freq = 600.0 + sin(t * 120.0 * TAU) * 450.0
		var s = (1.0 if fmod(t * mod_freq, 1.0) < 0.5 else -1.0) * 0.5 + randf_range(-0.5, 0.5)
		s = s * env * 0.65
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, false)

# -------------------------------------------------------------------------
# BGM Loop Synthesis
# -------------------------------------------------------------------------

func _get_or_create_bgm(era: String) -> AudioStreamWAV:
	if _bgm_cache.has(era):
		return _bgm_cache[era]

	var stream: AudioStreamWAV = null
	match era:
		"title":
			stream = _synth_title_bgm()
		"prehistoric":
			stream = _synth_prehistoric_bgm()
		"medieval":
			stream = _synth_medieval_bgm()
		"historical":
			stream = _synth_historical_bgm()
		"industrial":
			stream = _synth_industrial_bgm()
		"modern":
			stream = _synth_modern_bgm()
		"futuristic":
			stream = _synth_futuristic_bgm()
		"fortress":
			stream = _synth_fortress_bgm()
		"epilogue":
			stream = _synth_epilogue_bgm()
		_:
			stream = _synth_title_bgm()

	if stream:
		_bgm_cache[era] = stream
	return stream

func _synth_title_bgm() -> AudioStreamWAV:
	# 4-second looping ambient theme: A minor arpeggio with warm sub-bass
	var dur = 4.0
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	var notes: Array[float] = [220.0, 261.63, 329.63, 440.0, 523.25, 440.0, 329.63, 261.63]
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var note_idx = int(t * 2.0) % notes.size()
		var freq = notes[note_idx]
		var local_t = fmod(t, 0.5)
		var env = exp(-local_t * 4.5)
		var lead = sin(t * freq * TAU) * env * 0.35
		var bass = sin(t * 110.0 * TAU) * 0.25
		var pulse = (sin(t * 0.5 * TAU) + 1.0) * 0.5
		var s = (lead + bass * pulse) * 0.55
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, true)

func _synth_prehistoric_bgm() -> AudioStreamWAV:
	# 4-second heavy tribal rhythm: Low drum thump + primal drone
	var dur = 4.0
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var beat = fmod(t, 0.5)
		var kick_env = exp(-beat * 18.0)
		var kick = sin(beat * (130.0 - beat * 220.0) * TAU) * kick_env * 0.6
		var bass_freq = 73.42 if t < 2.0 else 82.41
		var bass = sin(t * bass_freq * TAU) * 0.3
		var shaker = (randf_range(-0.15, 0.15)) if fmod(t, 0.25) < 0.08 else 0.0
		var s = (kick + bass + shaker) * 0.55
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, true)

func _synth_medieval_bgm() -> AudioStreamWAV:
	# 4-second gothic castle march in D minor
	var dur = 4.0
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	var melody: Array[float] = [293.66, 329.63, 349.23, 440.0, 392.00, 349.23, 329.63, 293.66]
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var note_idx = int(t * 2.0) % melody.size()
		var freq = melody[note_idx]
		var local_t = fmod(t, 0.5)
		var env = exp(-local_t * 5.0)
		var organ = (sin(t * freq * TAU) + sin(t * freq * 2.0 * TAU) * 0.4) * env * 0.35
		var bass = (1.0 if fmod(t * 73.42, 1.0) < 0.5 else -1.0) * 0.15
		var s = (organ + bass) * 0.55
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, true)

func _synth_historical_bgm() -> AudioStreamWAV:
	# 4-second Japanese in-sen pentatonic bells (D, Eb, G, A, Bb)
	var dur = 4.0
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	var notes: Array[float] = [293.66, 311.13, 392.0, 440.0, 466.16, 440.0, 392.0, 311.13]
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var note_idx = int(t * 2.0) % notes.size()
		var freq = notes[note_idx]
		var local_t = fmod(t, 0.5)
		var env = exp(-local_t * 6.5)
		var bell = sin(t * freq * TAU) * 0.4 + sin(t * freq * 3.0 * TAU) * 0.2
		var s = bell * env * 0.55
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, true)

func _synth_industrial_bgm() -> AudioStreamWAV:
	# 4-second driving mechanical rhythm: steam pulse + piston clank
	var dur = 4.0
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var beat = fmod(t, 0.25)
		var piston_env = exp(-beat * 24.0)
		var piston = (sin(beat * 90.0 * TAU) * 0.6 + randf_range(-0.3, 0.3)) * piston_env
		var bass = (1.0 if fmod(t * 55.0, 1.0) < 0.5 else -1.0) * 0.25
		var s = (piston + bass) * 0.5
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, true)

func _synth_modern_bgm() -> AudioStreamWAV:
	# 4-second fast synthwave driving bassline (130 BPM groove)
	var dur = 4.0
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	var bass_notes: Array[float] = [110.0, 110.0, 130.81, 110.0, 146.83, 110.0, 130.81, 98.0]
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var step = int(t * 4.0) % bass_notes.size()
		var freq = bass_notes[step]
		var local_t = fmod(t, 0.25)
		var env = exp(-local_t * 12.0)
		var synth_saw = (fmod(t * freq, 1.0) * 2.0 - 1.0) * env * 0.45
		var beat = fmod(t, 0.5)
		var kick = sin(beat * 120.0 * TAU) * exp(-beat * 22.0) * 0.5
		var s = (synth_saw + kick) * 0.55
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, true)

func _synth_futuristic_bgm() -> AudioStreamWAV:
	# 4-second high-speed quantum cyber arpeggiator (16th notes)
	var dur = 4.0
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	var arp: Array[float] = [440.0, 554.37, 659.25, 880.0, 1108.73, 880.0, 659.25, 554.37]
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var step = int(t * 8.0) % arp.size()
		var freq = arp[step]
		var local_t = fmod(t, 0.125)
		var env = exp(-local_t * 16.0)
		var lead = sin(t * freq * TAU) * env * 0.4
		var sub = sin(t * 55.0 * TAU) * 0.3
		var s = (lead + sub) * 0.55
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, true)

func _synth_fortress_bgm() -> AudioStreamWAV:
	# 4-second ominous reality-bending tension pulse
	var dur = 4.0
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var lfo = sin(t * 1.5 * TAU) * 15.0
		var drone = sin(t * (65.41 + lfo) * TAU) * 0.4
		var dissonant = sin(t * 92.5 * TAU) * 0.25 # Tritone dissonance
		var pulse = (sin(t * 4.0 * TAU) + 1.0) * 0.5
		var s = (drone + dissonant * pulse) * 0.5
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, true)

func _synth_epilogue_bgm() -> AudioStreamWAV:
	# 4-second gentle uplifting sunrise chords (C -> G -> Am -> F)
	var dur = 4.0
	var samples = int(SAMPLE_RATE * dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	var chords: Array = [
		[261.63, 329.63, 392.00], # C Major
		[196.00, 246.94, 293.66], # G Major
		[220.00, 261.63, 329.63], # A Minor
		[174.61, 220.00, 261.63]  # F Major
	]
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var chord_idx = clampi(int(t), 0, chords.size() - 1)
		var c = chords[chord_idx]
		var local_t = fmod(t, 1.0)
		var env = exp(-local_t * 1.8)
		var s_chord = (sin(t * c[0] * TAU) + sin(t * c[1] * TAU) + sin(t * c[2] * TAU)) * 0.25 * env
		var s = s_chord * 0.55
		bytes.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	return _make_wav(bytes, true)

func _make_wav(bytes: PackedByteArray, loop: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = bytes.size() / 2
	else:
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav
