extends Node
class_name TruckEngineAudio

@export_group("Audio")
@export var engine_audio: AudioStreamPlayer3D
@export var turbo_audio: AudioStreamPlayer3D

@export_group("Engine")
@export var gearbox: Node
@export var min_pitch := 0.75
@export var max_pitch := 1.8
@export var pitch_smoothness := 4.0

@export_group("Turbo")
@export var turbo_enabled := true
@export var turbo_start_rpm := 1800.0

var current_rpm := 700.0
var target_pitch := 1.0


func _ready():
    if is_instance_valid(engine_audio):
        if not engine_audio.playing:
            engine_audio.play()

    if is_instance_valid(turbo_audio):
        if not turbo_audio.playing:
            turbo_audio.play()


func _process(delta):
    read_engine_rpm()
    update_engine_sound(delta)
    update_turbo_sound(delta)


func read_engine_rpm():
    if is_instance_valid(gearbox):
        if gearbox.has_method("get_engine_rpm"):
            current_rpm = gearbox.get_engine_rpm()


func update_engine_sound(delta):
    if not is_instance_valid(engine_audio):
        return

    var rpm_ratio := clampf(
        current_rpm / 3000.0, 0.0, 1.0
    )

    target_pitch = lerpf(
        min_pitch, max_pitch, rpm_ratio
    )

    engine_audio.pitch_scale = lerpf(
        engine_audio.pitch_scale,
        target_pitch,
        delta * pitch_smoothness
    )


func update_turbo_sound(delta):
    if not turbo_enabled:
        return

    if not is_instance_valid(turbo_audio):
        return

    var turbo_volume := 0.0

    if current_rpm >= turbo_start_rpm:
        turbo_volume = clampf(
            (current_rpm - turbo_start_rpm) / 1000.0,
            0.0, 1.0
        )

    turbo_audio.volume_db = lerpf(
        turbo_audio.volume_db,
        linear_to_db(maxf(turbo_volume, 0.001)),
        delta * 3.0
    )


func set_engine_rpm(value: float):
    current_rpm = clampf(value, 0.0, 3000.0)


func stop_engine_sound():
    if is_instance_valid(engine_audio):
        engine_audio.stop()

    if is_instance_valid(turbo_audio):
        turbo_audio.stop()


func start_engine_sound():
    if is_instance_valid(engine_audio):
        if not engine_audio.playing:
            engine_audio.play()
