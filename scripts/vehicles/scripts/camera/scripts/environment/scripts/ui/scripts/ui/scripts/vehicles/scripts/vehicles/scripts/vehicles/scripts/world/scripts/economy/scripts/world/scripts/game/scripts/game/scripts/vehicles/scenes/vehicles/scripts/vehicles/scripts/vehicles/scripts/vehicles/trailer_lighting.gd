extends Node3D
class_name TrailerLightingSystem

signal indicator_changed(direction: String)
signal hazard_changed(enabled: bool)

@export_group("Light Nodes")
@export var left_brake_light: OmniLight3D
@export var right_brake_light: OmniLight3D
@export var left_reverse_light: OmniLight3D
@export var right_reverse_light: OmniLight3D
@export var left_indicator: OmniLight3D
@export var right_indicator: OmniLight3D
@export var left_tail_light: OmniLight3D
@export var right_tail_light: OmniLight3D

@export_group("Brightness")
@export var brake_brightness: float = 2.0
@export var reverse_brightness: float = 1.2
@export var indicator_brightness: float = 1.5
@export var tail_brightness: float = 0.5

@export_group("Indicator Settings")
@export var indicator_interval: float = 0.5

var brake_active: bool = false
var reverse_active: bool = false
var left_active: bool = false
var right_active: bool = false
var hazard_active: bool = false
var headlights_active: bool = true

var indicator_timer: float = 0.0
var indicator_on: bool = false


func _ready() -> void:
    add_to_group("trailer_lighting")
    _update_all_lights()


func _process(delta: float) -> void:
    _update_indicator_animation(delta)


# ============================================================
# BRAKE LIGHTS
# ============================================================

func set_brake_lights(enabled: bool) -> void:
    brake_active = enabled
    _update_light(left_brake_light, brake_active, brake_brightness)
    _update_light(right_brake_light, brake_active, brake_brightness)


# ============================================================
# REVERSE LIGHTS
# ============================================================

func set_reverse_lights(enabled: bool) -> void:
    reverse_active = enabled
    _update_light(left_reverse_light, reverse_active, reverse_brightness)
    _update_light(right_reverse_light, reverse_active, reverse_brightness)


# ============================================================
# INDICATORS
# ============================================================

func set_left_indicator(enabled: bool) -> void:
    left_active = enabled
    right_active = false
    hazard_active = false
    indicator_timer = 0.0
    indicator_on = false
    _update_indicator_lights()
    indicator_changed.emit("left" if enabled else "off")


func set_right_indicator(enabled: bool) -> void:
    right_active = enabled
    left_active = false
    hazard_active = false
    indicator_timer = 0.0
    indicator_on = false
    _update_indicator_lights()
    indicator_changed.emit("right" if enabled else "off")


func set_hazard_lights(enabled: bool) -> void:
    hazard_active = enabled
    left_active = false
    right_active = false
    indicator_timer = 0.0
    indicator_on = false
    _update_indicator_lights()
    hazard_changed.emit(enabled)


func turn_off_indicators() -> void:
    left_active = false
    right_active = false
    hazard_active = false
    indicator_on = false
    _update_indicator_lights()
    indicator_changed.emit("off")


func _update_indicator_animation(delta: float) -> void:

    if not left_active and not right_active and not hazard_active:
        return

    indicator_timer += delta

    if indicator_timer >= indicator_interval:
        indicator_timer = 0.0
        indicator_on = not indicator_on
        _update_indicator_lights()


func _update_indicator_lights() -> void:

    var left_enabled := indicator_on and (left_active or hazard_active)
    var right_enabled := indicator_on and (right_active or hazard_active)

    _update_light(left_indicator, left_enabled, indicator_brightness)
    _update_light(right_indicator, right_enabled, indicator_brightness)


# ============================================================
# TAIL LIGHTS
# ============================================================

func set_tail_lights(enabled: bool) -> void:
    headlights_active = enabled
    _update_light(left_tail_light, enabled, tail_brightness)
    _update_light(right_tail_light, enabled, tail_brightness)


# ============================================================
# LIGHT CONTROL
# ============================================================

func _update_light(
    light: OmniLight3D,
    enabled: bool,
    brightness: float
) -> void:

    if not is_instance_valid(light):
        return

    light.visible = enabled
    light.light_energy = brightness


func _update_all_lights() -> void:

    set_brake_lights(brake_active)
    set_reverse_lights(reverse_active)
    set_tail_lights(headlights_active)
    _update_indicator_lights()


# ============================================================
# STATUS
# ============================================================

func is_braking() -> bool:
    return brake_active


func is_reversing() -> bool:
    return reverse_active


func is_hazard_active() -> bool:
    return hazard_active


func get_indicator_status() -> String:

    if hazard_active:
        return "HAZARD"

    if left_active:
        return "LEFT"

    if right_active:
        return "RIGHT"

    return "OFF"
