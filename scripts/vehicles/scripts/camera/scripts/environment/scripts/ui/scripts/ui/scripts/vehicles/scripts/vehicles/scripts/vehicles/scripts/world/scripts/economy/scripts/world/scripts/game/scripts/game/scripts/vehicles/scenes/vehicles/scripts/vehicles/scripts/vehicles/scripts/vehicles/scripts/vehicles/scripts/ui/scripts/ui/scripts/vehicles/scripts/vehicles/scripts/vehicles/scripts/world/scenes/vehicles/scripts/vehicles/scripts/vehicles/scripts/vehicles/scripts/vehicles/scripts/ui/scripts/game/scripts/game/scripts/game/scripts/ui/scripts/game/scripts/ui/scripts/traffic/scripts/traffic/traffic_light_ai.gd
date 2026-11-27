extends Node3D
class_name TrafficLightAI

signal light_changed(new_state: String)

enum LightState {
    RED,
    YELLOW,
    GREEN
}

@export_group("Traffic Light Settings")
@export var green_duration: float = 20.0
@export var yellow_duration: float = 3.0
@export var red_duration: float = 20.0

@export_group("Light Visuals")
@export var red_light: MeshInstance3D
@export var yellow_light: MeshInstance3D
@export var green_light: MeshInstance3D

@export_group("Control")
@export var auto_cycle: bool = true
@export var starting_state: LightState = LightState.GREEN

var current_state: LightState
var state_timer: float = 0.0

var traffic_vehicles: Array[TrafficVehicleAI] = []


func _ready() -> void:

    add_to_group("traffic_lights")

    current_state = starting_state

    _update_light_visuals()
    _update_traffic_vehicles()


func _process(delta: float) -> void:

    if not auto_cycle:
        return

    state_timer += delta

    match current_state:

        LightState.GREEN:
            if state_timer >= green_duration:
                set_light_state(LightState.YELLOW)

        LightState.YELLOW:
            if state_timer >= yellow_duration:
                set_light_state(LightState.RED)

        LightState.RED:
            if state_timer >= red_duration:
                set_light_state(LightState.GREEN)


# ============================================================
# CHANGE LIGHT STATE
# ============================================================

func set_light_state(new_state: LightState) -> void:

    if current_state == new_state:
        return

    current_state = new_state
    state_timer = 0.0

    _update_light_visuals()
    _update_traffic_vehicles()

    light_changed.emit(get_state_name())


# ============================================================
# LIGHT VISUALS
# ============================================================

func _update_light_visuals() -> void:

    _set_light(red_light, current_state == LightState.RED)

    _set_light(
        yellow_light,
        current_state == LightState.YELLOW
    )

    _set_light(
        green_light,
        current_state == LightState.GREEN
    )


func _set_light(
    light: MeshInstance3D,
    enabled: bool
) -> void:

    if not is_instance_valid(light):
        return

    light.visible = enabled


# ============================================================
# CONNECT TRAFFIC VEHICLES
# ============================================================

func _update_traffic_vehicles() -> void:

    traffic_vehicles.clear()

    var vehicles := get_tree().get_nodes_in_group(
        "traffic_vehicles"
    )

    for vehicle in vehicles:

        if vehicle is TrafficVehicleAI:

            traffic_vehicles.append(vehicle)

            vehicle.set_traffic_light_state(
                current_state
            )


func register_vehicle(vehicle: TrafficVehicleAI) -> void:

    if not is_instance_valid(vehicle):
        return

    if not traffic_vehicles.has(vehicle):

        traffic_vehicles.append(vehicle)

        vehicle.set_traffic_light_state(
            current_state
        )


func unregister_vehicle(vehicle: TrafficVehicleAI) -> void:

    traffic_vehicles.erase(vehicle)


# ============================================================
# MANUAL CONTROLS
# ============================================================

func turn_red() -> void:
    set_light_state(LightState.RED)


func turn_yellow() -> void:
    set_light_state(LightState.YELLOW)


func turn_green() -> void:
    set_light_state(LightState.GREEN)


func get_state_name() -> String:

    match current_state:

        LightState.RED:
            return "RED"

        LightState.YELLOW:
            return "YELLOW"

        LightState.GREEN:
            return "GREEN"

    return "UNKNOWN"


func get_remaining_time() -> float:

    var duration := 0.0

    match current_state:

        LightState.GREEN:
            duration = green_duration

        LightState.YELLOW:
            duration = yellow_duration

        LightState.RED:
            duration = red_duration

    return maxf(duration - state_timer, 0.0)
