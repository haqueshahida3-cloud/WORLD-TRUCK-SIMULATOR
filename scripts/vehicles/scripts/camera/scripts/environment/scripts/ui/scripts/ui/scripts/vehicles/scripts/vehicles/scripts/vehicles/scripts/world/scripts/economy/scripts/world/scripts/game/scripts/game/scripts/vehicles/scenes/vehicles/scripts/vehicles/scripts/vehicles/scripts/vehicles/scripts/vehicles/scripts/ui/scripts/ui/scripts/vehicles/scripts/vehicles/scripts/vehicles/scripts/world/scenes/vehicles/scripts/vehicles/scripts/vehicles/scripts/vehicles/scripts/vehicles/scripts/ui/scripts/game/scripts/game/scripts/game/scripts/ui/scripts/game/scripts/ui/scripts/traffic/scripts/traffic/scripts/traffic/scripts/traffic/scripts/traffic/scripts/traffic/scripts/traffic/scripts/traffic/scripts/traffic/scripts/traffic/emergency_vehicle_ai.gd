extends Node3D
class_name EmergencyVehicleAI

signal emergency_mode_activated
signal emergency_mode_deactivated
signal siren_changed(is_active: bool)

@export_group("Vehicle")
@export_enum("Ambulance", "Police", "Fire Truck")
var vehicle_type: String = "Ambulance"

@export var maximum_speed_kmh: float = 110.0

@export_group("Emergency Lights")
@export var red_light: OmniLight3D
@export var blue_light: OmniLight3D
@export var white_light: OmniLight3D

@export var light_flash_speed: float = 0.15

@export_group("Siren")
@export var siren_audio: AudioStreamPlayer3D
@export var siren_enabled: bool = true

@export_group("Controls")
@export var toggle_action: String = "emergency_siren"

var emergency_mode: bool = false
var siren_active: bool = false

var flash_timer: float = 0.0
var flash_state: bool = false


func _ready() -> void:

    add_to_group("emergency_vehicles")

    _setup_lights()

    if not InputMap.has_action(toggle_action):
        InputMap.add_action(toggle_action)


func _process(delta: float) -> void:

    if Input.is_action_just_pressed(toggle_action):
        toggle_emergency_mode()

    if emergency_mode:
        _update_emergency_lights(delta)


# ============================================================
# SETUP LIGHTS
# ============================================================

func _setup_lights() -> void:

    if is_instance_valid(red_light):
        red_light.visible = false

    if is_instance_valid(blue_light):
        blue_light.visible = false

    if is_instance_valid(white_light):
        white_light.visible = false


# ============================================================
# TOGGLE EMERGENCY MODE
# ============================================================

func toggle_emergency_mode() -> void:

    set_emergency_mode(not emergency_mode)


func set_emergency_mode(enabled: bool) -> void:

    if emergency_mode == enabled:
        return

    emergency_mode = enabled

    if emergency_mode:

        emergency_mode_activated.emit()

        if siren_enabled:
            start_siren()

    else:

        emergency_mode_deactivated.emit()

        stop_siren()
        _turn_off_lights()


# ============================================================
# SIREN
# ============================================================

func start_siren() -> void:

    if not siren_enabled:
        return

    siren_active = true

    if is_instance_valid(siren_audio):
        if not siren_audio.playing:
            siren_audio.play()

    siren_changed.emit(true)


func stop_siren() -> void:

    siren_active = false

    if is_instance_valid(siren_audio):
        siren_audio.stop()

    siren_changed.emit(false)


func set_siren_enabled(enabled: bool) -> void:

    siren_enabled = enabled

    if not enabled:
        stop_siren()

    elif emergency_mode:
        start_siren()


# ============================================================
# FLASHING LIGHTS
# ============================================================

func _update_emergency_lights(delta: float) -> void:

    flash_timer += delta

    if flash_timer < light_flash_speed:
        return

    flash_timer = 0.0

    flash_state = not flash_state

    if is_instance_valid(red_light):
        red_light.visible = flash_state

    if is_instance_valid(blue_light):
        blue_light.visible = not flash_state

    if is_instance_valid(white_light):
        white_light.visible = flash_state


func _turn_off_lights() -> void:

    flash_state = false
    flash_timer = 0.0

    if is_instance_valid(red_light):
        red_light.visible = false

    if is_instance_valid(blue_light):
        blue_light.visible = false

    if is_instance_valid(white_light):
        white_light.visible = false


# ============================================================
# EMERGENCY INFORMATION
# ============================================================

func is_emergency_active() -> bool:
    return emergency_mode


func is_siren_active() -> bool:
    return siren_active


func get_vehicle_type() -> String:
    return vehicle_type


func get_emergency_speed_limit() -> float:
    return maximum_speed_kmh


func activate_emergency() -> void:
    set_emergency_mode(true)


func deactivate_emergency() -> void:
    set_emergency_mode(false)
