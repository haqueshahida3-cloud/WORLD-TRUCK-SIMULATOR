extends Area3D
class_name TruckGarage

signal garage_entered
signal garage_exited
signal repair_started
signal repair_finished(total_cost: float)
signal repair_failed(reason: String)

@export_group("References")
@export var damage_system: Node
@export var wallet: Node

@export_group("Garage Settings")
@export var service_time := 3.0

var truck_nearby := false
var repairing := false
var repair_timer := 0.0
var pending_cost := 0.0
var selected_component := "all"


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
    if body is VehicleBody3D:
        truck_nearby = true
        garage_entered.emit()


func _on_body_exited(body: Node3D) -> void:
    if body is VehicleBody3D:
        truck_nearby = false
        garage_exited.emit()

        if repairing:
            cancel_repair()


func _process(delta: float) -> void:
    if not repairing:
        return

    repair_timer += delta

    if repair_timer >= service_time:
        finish_repair()


func start_repair(component: String = "all") -> bool:
    if not truck_nearby:
        repair_failed.emit("Truck is not inside garage")
        return false

    if repairing:
        return false

    if not is_instance_valid(damage_system):
        repair_failed.emit("Damage system missing")
        return false

    if not is_instance_valid(wallet):
        repair_failed.emit("Wallet missing")
        return false

    var key := component.to_lower()

    if key not in ["engine", "body", "wheel", "all"]:
        repair_failed.emit("Invalid repair component")
        return false

    pending_cost = damage_system.get_repair_cost(key)

    if pending_cost <= 0.0:
        repair_failed.emit("No repair needed")
        return false

    if not wallet.has_method("get_balance"):
        repair_failed.emit("Wallet balance method missing")
        return false

    if wallet.get_balance() < pending_cost:
        repair_failed.emit("Not enough money")
        return false

    selected_component = key
    repairing = true
    repair_timer = 0.0
    repair_started.emit()

    return true


func finish_repair() -> void:
    if not repairing:
        return

    var success := false

    if selected_component == "all":
        if damage_system.has_method("repair_all"):
            success = damage_system.repair_all()
    else:
        if damage_system.has_method("repair_component"):
            success = damage_system.repair_component(selected_component)

    repairing = false

    if success:
        repair_finished.emit(pending_cost)
    else:
        repair_failed.emit("Repair failed or payment unsuccessful")

    _reset_repair()


func cancel_repair() -> void:
    repairing = false
    _reset_repair()


func _reset_repair() -> void:
    pending_cost = 0.0
    repair_timer = 0.0
    selected_component = "all"


func get_repair_progress() -> float:
    if not repairing or service_time <= 0.0:
        return 0.0

    return clampf(repair_timer / service_time, 0.0, 1.0)


func is_truck_nearby() -> bool:
    return truck_nearby
