extends Node
class_name TrailerLightController

@export_group("Vehicle References")
@export var truck: VehicleBody3D
@export var trailer_lights: TrailerLightingSystem

@export_group("Automatic Controls")
@export var automatic_brake_lights: bool = true
@export var automatic_reverse_lights: bool = true
@export var automatic_indicators: bool = true
@export var automatic_tail_lights: bool = true

@export_group("Reverse Detection")
@export var reverse_speed_threshold: float = -0.5

var previous_brake_state: bool = false
var previous_reverse_state: bool = false


func _ready() -> void:
    add_to_group("trailer_light_controller")
    _find_references()


func _find_references() -> void:

    if not is_instance_valid(truck):
        var trucks := get_tree().get_nodes_in_group("player")

        if not trucks.is_empty():
            truck = trucks[0] as VehicleBody3D

    if not is_instance_valid(trailer_lights):
        var lights := get_tree().get_nodes_in_group("trailer_lighting")

        if not lights.is_empty():
            trailer_lights = lights[0] as TrailerLightingSystem


func _physics_process(_delta: float) -> void:

    if not is_instance_valid(truck):
        _find_references()
        return

    if not is_instance_valid(trailer_lights):
        _find_references()
        return

    _update_brake_lights()
    _update_reverse_lights()


# ============================================================
# BRAKE DETECTION
# ============================================================

func _update_brake_lights() -> void:

    if not automatic_brake_lights:
        return

    var braking := false

    if Input.is_action_pressed("brake"):
        braking = true

    if Input.is_action_pressed("handbrake"):
        braking = true

    if braking != previous_brake_state:
        trailer_lights.set_brake_lights(braking)
        previous_brake_state = braking


# ============================================================
# REVERSE DETECTION
# ============================================================

func _update_reverse_lights() -> void:

    if not automatic_reverse_lights:
        return

    var reverse := false

    if truck.has_method("get_gear_name"):
        reverse = truck.get_gear_name() == "R"

    if reverse != previous_reverse_state:
        trailer_lights.set_reverse_lights(reverse)
        previous_reverse_state = reverse


# ============================================================
# MANUAL INDICATORS
# ============================================================

func activate_left_indicator() -> void:

    if not is_instance_valid(trailer_lights):
        _find_references()

    if is_instance_valid(trailer_lights):
        trailer_lights.set_left_indicator(true)


func activate_right_indicator() -> void:

    if not is_instance_valid(trailer_lights):
        _find_references()

    if is_instance_valid(trailer_lights):
        trailer_lights.set_right_indicator(true)


func activate_hazard_lights() -> void:

    if not is_instance_valid(trailer_lights):
        _find_references()

    if is_instance_valid(trailer_lights):
        trailer_lights.set_hazard_lights(true)


func disable_indicators() -> void:

    if is_instance_valid(trailer_lights):
        trailer_lights.turn_off_indicators()


# ============================================================
# TAIL LIGHTS
# ============================================================

func set_night_lights(enabled: bool) -> void:

    if is_instance_valid(trailer_lights):
        trailer_lights.set_tail_lights(enabled)
