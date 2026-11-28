extends Node3D
class_name UnifiedTrafficSignalController

signal signal_changed(state: int)
signal vehicle_allowed(vehicle: Node3D)
signal vehicle_stopped(vehicle: Node3D)

enum SignalState {
    RED,
    YELLOW,
    GREEN
}

@export_group("Signal Timing")
@export var green_duration: float = 20.0
@export var yellow_duration: float = 3.0
@export var red_duration: float = 20.0

@export_group("Signal State")
@export var start_state: SignalState = SignalState.GREEN
@export var automatic_cycle: bool = true

@export_group("Traffic Detection")
@export var detection_radius: float = 35.0
@export var stop_line_distance: float = 12.0

@export_group("Visual Lights")
@export var red_light: OmniLight3D
@export var yellow_light: OmniLight3D
@export var green_light: OmniLight3D

var current_state: SignalState
var state_timer: float = 0.0

var approaching_vehicles: Array[Node3D] = []


func _ready() -> void:

    add_to_group("traffic_lights")

    current_state = start_state

    _update_visuals()
    _update_traffic()


func _process(delta: float) -> void:

    if not automatic_cycle:
        return

    state_timer += delta

    match current_state:

        SignalState.GREEN:
            if state_timer >= green_duration:
                set_signal_state(SignalState.YELLOW)

        SignalState.YELLOW:
            if state_timer >= yellow_duration:
                set_signal_state(SignalState.RED)

        SignalState.RED:
            if state_timer >= red_duration:
                set_signal_state(SignalState.GREEN)


# ============================================================
# SIGNAL STATE
# ============================================================

func set_signal_state(new_state: SignalState) -> void:

    if current_state == new_state:
        return

    current_state = new_state
    state_timer = 0.0

    _update_visuals()
    _update_traffic()

    signal_changed.emit(current_state)


func get_signal_state() -> SignalState:
    return current_state


func is_green() -> bool:
    return current_state == SignalState.GREEN


# ============================================================
# VISUAL LIGHTS
# ============================================================

func _update_visuals() -> void:

    if is_instance_valid(red_light):
        red_light.visible = (
            current_state == SignalState.RED
        )

    if is_instance_valid(yellow_light):
        yellow_light.visible = (
            current_state == SignalState.YELLOW
        )

    if is_instance_valid(green_light):
        green_light.visible = (
            current_state == SignalState.GREEN
        )


# ============================================================
# DETECT TRAFFIC
# ============================================================

func _update_traffic() -> void:

    approaching_vehicles.clear()

    var vehicles := get_tree().get_nodes_in_group(
        "traffic_vehicles"
    )

    for node in vehicles:

        if not node is Node3D:
            continue

        var traffic_vehicle := node as Node3D

        var distance := global_position.distance_to(
            traffic_vehicle.global_position
        )

        if distance > detection_radius:
            continue

        approaching_vehicles.append(traffic_vehicle)

        _control_vehicle(traffic_vehicle)


# ============================================================
# CONTROL VEHICLES
# ============================================================

func _control_vehicle(vehicle: Node3D) -> void:

    if current_state == SignalState.GREEN:

        if vehicle.has_method("set_traffic_light_state"):
            vehicle.set_traffic_light_state(true)

        elif vehicle.has_method("set_traffic_light_permission"):
            vehicle.set_traffic_light_permission(true)

        vehicle_allowed.emit(vehicle)

    else:

        if vehicle.has_method("set_traffic_light_state"):
            vehicle.set_traffic_light_state(false)

        elif vehicle.has_method("set_traffic_light_permission"):
            vehicle.set_traffic_light_permission(false)

        vehicle_stopped.emit(vehicle)


# ============================================================
# UPDATE NEARBY VEHICLES
# ============================================================

func refresh_traffic() -> void:

    _update_traffic()


func force_red() -> void:
    set_signal_state(SignalState.RED)


func force_yellow() -> void:
    set_signal_state(SignalState.YELLOW)


func force_green() -> void:
    set_signal_state(SignalState.GREEN)


# ============================================================
# MANUAL CONTROL
# ============================================================

func enable_automatic_cycle() -> void:
    automatic_cycle = true


func disable_automatic_cycle() -> void:
    automatic_cycle = false


func get_remaining_time() -> float:

    var duration := green_duration

    match current_state:

        SignalState.YELLOW:
            duration = yellow_duration

        SignalState.RED:
            duration = red_duration

    return maxf(duration - state_timer, 0.0)


func get_approaching_vehicle_count() -> int:
    return approaching_vehicles.size()
