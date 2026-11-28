extends Area3D
class_name FuelStation

signal player_entered_station
signal player_left_station
signal refueling_started
signal refueling_progress(amount: float)
signal refueling_finished(total_cost: float)

@export_group("Fuel System")
@export var fuel_system: Node
@export var fuel_price_per_liter := 125.0

@export_group("Refueling")
@export var liters_per_second := 5.0
@export var automatic_refueling := false

var vehicle_nearby := false
var is_refueling := false
var total_cost := 0.0
var total_liters := 0.0


func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)


func _process(delta):
    if not is_refueling:
        return

    if not vehicle_nearby:
        stop_refueling()
        return

    perform_refueling(delta)


func _on_body_entered(body: Node3D):
    if body is VehicleBody3D:
        vehicle_nearby = true
        player_entered_station.emit()

        if automatic_refueling:
            start_refueling()


func _on_body_exited(body: Node3D):
    if body is VehicleBody3D:
        vehicle_nearby = false
        player_left_station.emit()
        stop_refueling()


func start_refueling():
    if not vehicle_nearby:
        return

    if not is_instance_valid(fuel_system):
        return

    if is_refueling:
        return

    if fuel_system.get_fuel_percentage() >= 100.0:
        return

    is_refueling = true
    total_cost = 0.0
    total_liters = 0.0
    refueling_started.emit()


func perform_refueling(delta: float):
    var amount := liters_per_second * delta
    var before := fuel_system.get_fuel_level()

    fuel_system.refuel(amount)

    var after := fuel_system.get_fuel_level()
    var added := after - before

    if added <= 0.0:
        stop_refueling()
        return

    total_liters += added
    total_cost += added * fuel_price_per_liter

    refueling_progress.emit(total_liters)

    if fuel_system.get_fuel_percentage() >= 100.0:
        stop_refueling()


func stop_refueling():
    if not is_refueling:
        return

    is_refueling = false
    refueling_finished.emit(total_cost)


func get_total_cost() -> float:
    return total_cost


func get_total_liters() -> float:
    return total_liters


func can_refuel() -> bool:
    return vehicle_nearby and is_instance_valid(fuel_system)
