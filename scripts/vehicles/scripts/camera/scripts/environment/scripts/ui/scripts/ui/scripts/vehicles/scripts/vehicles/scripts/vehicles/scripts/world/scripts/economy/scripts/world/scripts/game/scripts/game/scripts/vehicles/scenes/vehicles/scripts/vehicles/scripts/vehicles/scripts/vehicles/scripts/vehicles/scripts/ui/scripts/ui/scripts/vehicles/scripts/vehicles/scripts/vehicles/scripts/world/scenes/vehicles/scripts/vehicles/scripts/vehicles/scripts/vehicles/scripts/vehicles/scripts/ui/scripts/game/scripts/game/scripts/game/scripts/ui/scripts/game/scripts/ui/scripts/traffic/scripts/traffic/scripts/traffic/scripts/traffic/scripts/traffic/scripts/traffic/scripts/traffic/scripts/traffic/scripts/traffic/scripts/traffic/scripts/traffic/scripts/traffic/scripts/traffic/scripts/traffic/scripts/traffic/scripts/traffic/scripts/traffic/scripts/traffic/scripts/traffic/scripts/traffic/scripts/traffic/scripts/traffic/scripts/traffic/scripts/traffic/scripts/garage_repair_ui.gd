extends Control
class_name GarageRepairUI

@export_group("References")
@export var garage: Node
@export var damage_system: Node
@export var wallet: Node

@export_group("UI Nodes")
@export var engine_button: Button
@export var body_button: Button
@export var wheel_button: Button
@export var all_button: Button
@export var close_button: Button
@export var status_label: Label
@export var money_label: Label
@export var condition_label: Label

var selected_component := "all"


func _ready() -> void:
    visible = false

    engine_button.pressed.connect(_on_engine_pressed)
    body_button.pressed.connect(_on_body_pressed)
    wheel_button.pressed.connect(_on_wheel_pressed)
    all_button.pressed.connect(_on_all_pressed)
    close_button.pressed.connect(_on_close_pressed)

    if is_instance_valid(garage):
        garage.garage_entered.connect(_on_garage_entered)
        garage.garage_exited.connect(_on_garage_exited)
        garage.repair_started.connect(_on_repair_started)
        garage.repair_finished.connect(_on_repair_finished)
        garage.repair_failed.connect(_on_repair_failed)

    update_display()


func _process(_delta: float) -> void:
    if visible:
        update_display()


func _on_engine_pressed() -> void:
    start_selected_repair("engine")


func _on_body_pressed() -> void:
    start_selected_repair("body")


func _on_wheel_pressed() -> void:
    start_selected_repair("wheel")


func _on_all_pressed() -> void:
    start_selected_repair("all")


func start_selected_repair(component: String) -> void:
    if not is_instance_valid(garage):
        status_label.text = "Garage reference missing"
        return

    selected_component = component

    if garage.start_repair(component):
        status_label.text = "Repair started: " + component.capitalize()
    else:
        status_label.text = "Could not start repair"


func _on_garage_entered() -> void:
    visible = true
    status_label.text = "Welcome to Truck Garage"
    update_display()


func _on_garage_exited() -> void:
    visible = false


func _on_repair_started() -> void:
    status_label.text = "Repairing truck..."


func _on_repair_finished(cost: float) -> void:
    status_label.text = "Repair completed! Cost: $" + str(snappedf(cost, 0.01))
    update_display()


func _on_repair_failed(reason: String) -> void:
    status_label.text = reason


func _on_close_pressed() -> void:
    visible = false


func update_display() -> void:
    if is_instance_valid(wallet):
        money_label.text = "Money: $" + str(snappedf(wallet.get_balance(), 0.01))

    if is_instance_valid(damage_system):
        condition_label.text = (
            "Truck Condition: "
            + str(snappedf(damage_system.get_vehicle_condition(), 0.1))
            + "%"
        )


func get_repair_price(component: String) -> float:
    if not is_instance_valid(damage_system):
        return 0.0

    return damage_system.get_repair_cost(component)
