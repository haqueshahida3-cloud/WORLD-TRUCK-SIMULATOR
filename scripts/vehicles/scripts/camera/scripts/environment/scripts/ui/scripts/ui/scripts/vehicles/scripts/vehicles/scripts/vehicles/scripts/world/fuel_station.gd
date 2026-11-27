extends Area3D
class_name FuelStation

@export_group("Fuel Station")
@export var fuel_price_per_liter: float = 120.0
@export var station_name: String = "Highway Fuel Station"
@export var refuel_rate: float = 20.0

@export_group("Interaction")
@export var interaction_distance: float = 5.0
@export var auto_refuel: bool = false

var truck: VehicleBody3D
var fuel_system: TruckFuelSystem

var player_nearby: bool = false
var is_refueling: bool = false
var refuel_amount: float = 0.0
var total_cost: float = 0.0


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
    if not is_instance_valid(truck):
        return

    if not player_nearby:
        return

    if Input.is_action_just_pressed("interact"):
        start_refueling()

    if is_refueling:
        _process_refueling(delta)


# ============================================================
# TRUCK DETECTION
# ============================================================

func _on_body_entered(body: Node3D) -> void:

    if body is VehicleBody3D:
        truck = body as VehicleBody3D
        player_nearby = true

        _find_fuel_system()


func _on_body_exited(body: Node3D) -> void:

    if body == truck:
        player_nearby = false
        is_refueling = false


func _find_fuel_system() -> void:

    fuel_system = null

    if not is_instance_valid(truck):
        return

    var systems := get_tree().get_nodes_in_group("fuel_system")

    for system in systems:
        if system is TruckFuelSystem:
            fuel_system = system as TruckFuelSystem
            return


# ============================================================
# REFUELING
# ============================================================

func start_refueling() -> void:

    if not player_nearby:
        return

    if not is_instance_valid(fuel_system):
        _find_fuel_system()

    if not is_instance_valid(fuel_system):
        return

    if fuel_system.get_fuel_percentage() >= 100.0:
        return

    is_refueling = true
    refuel_amount = 0.0
    total_cost = 0.0


func _process_refueling(delta: float) -> void:

    if not is_instance_valid(fuel_system):
        is_refueling = false
        return

    if not is_instance_valid(truck):
        is_refueling = false
        return

    if truck.linear_velocity.length() > 0.5:
        is_refueling = false
        return

    var requested_fuel := refuel_rate * delta

    var added_fuel := fuel_system.refuel(requested_fuel)

    if added_fuel <= 0.0:
        is_refueling = false
        return

    refuel_amount += added_fuel
    total_cost = refuel_amount * fuel_price_per_liter


func stop_refueling() -> void:
    is_refueling = false


# ============================================================
# INFORMATION
# ============================================================

func get_station_name() -> String:
    return station_name


func get_fuel_added() -> float:
    return refuel_amount


func get_total_cost() -> float:
    return total_cost


func get_fuel_price() -> float:
    return fuel_price_per_liter


func is_station_active() -> bool:
    return player_nearby
