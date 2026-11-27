extends Area3D
class_name TruckGarage

signal repair_started
signal repair_completed(total_cost: float)
signal repair_failed(reason: String)

@export_group("Garage")
@export var garage_name: String = "Premium Truck Garage"
@export var repair_cost_multiplier: float = 100.0

@export_group("Repair Settings")
@export var repair_duration: float = 5.0
@export var require_stopped_truck: bool = true

var truck: VehicleBody3D
var damage_system: TruckDamageSystem
var wallet: WalletSystem

var player_nearby: bool = false
var repairing: bool = false
var repair_timer: float = 0.0
var pending_cost: float = 0.0


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
    if not player_nearby:
        return

    if Input.is_action_just_pressed("interact"):
        start_repair()

    if repairing:
        _process_repair(delta)


# ============================================================
# DETECTION
# ============================================================

func _on_body_entered(body: Node3D) -> void:
    if body is VehicleBody3D:
        truck = body as VehicleBody3D
        player_nearby = true
        _find_systems()


func _on_body_exited(body: Node3D) -> void:
    if body == truck:
        player_nearby = false
        repairing = false
        repair_timer = 0.0


func _find_systems() -> void:
    if not is_instance_valid(truck):
        return

    for node in get_tree().get_nodes_in_group("damage_system"):
        if node is TruckDamageSystem:
            damage_system = node as TruckDamageSystem
            break

    for node in get_tree().get_nodes_in_group("wallet_system"):
        if node is WalletSystem:
            wallet = node as WalletSystem
            break


# ============================================================
# START REPAIR
# ============================================================

func start_repair() -> void:
    if repairing:
        return

    if not is_instance_valid(truck):
        repair_failed.emit("Truck not found")
        return

    _find_systems()

    if not is_instance_valid(damage_system):
        repair_failed.emit("Damage system unavailable")
        return

    if not is_instance_valid(wallet):
        repair_failed.emit("Wallet unavailable")
        return

    if require_stopped_truck and truck.linear_velocity.length() > 0.5:
        repair_failed.emit("Stop the truck first")
        return

    pending_cost = _calculate_repair_cost()

    if pending_cost <= 0.0:
        repair_failed.emit("Truck does not need repair")
        return

    if not wallet.can_afford(pending_cost):
        repair_failed.emit("Not enough money")
        return

    repairing = true
    repair_timer = 0.0
    repair_started.emit()


# ============================================================
# REPAIR PROCESS
# ============================================================

func _process_repair(delta: float) -> void:
    if not player_nearby:
        repairing = false
        return

    repair_timer += delta

    if repair_timer >= repair_duration:
        _finish_repair()


func _finish_repair() -> void:
    if not is_instance_valid(wallet):
        repairing = false
        return

    if not is_instance_valid(damage_system):
        repairing = false
        return

    if not wallet.spend_money(pending_cost, "Truck Repair"):
        repairing = false
        repair_failed.emit("Payment failed")
        return

    damage_system.repair_all()

    repairing = false
    repair_timer = 0.0

    repair_completed.emit(pending_cost)


# ============================================================
# COST CALCULATION
# ============================================================

func _calculate_repair_cost() -> float:
    if not is_instance_valid(damage_system):
        return 0.0

    return (
        damage_system.get_damage_percentage() *
        repair_cost_multiplier
    )


# ============================================================
# INFORMATION
# ============================================================

func get_garage_name() -> String:
    return garage_name


func get_repair_progress() -> float:
    if repair_duration <= 0.0:
        return 1.0 if repairing else 0.0

    return clampf(repair_timer / repair_duration, 0.0, 1.0)


func is_repairing() -> bool:
    return repairing
