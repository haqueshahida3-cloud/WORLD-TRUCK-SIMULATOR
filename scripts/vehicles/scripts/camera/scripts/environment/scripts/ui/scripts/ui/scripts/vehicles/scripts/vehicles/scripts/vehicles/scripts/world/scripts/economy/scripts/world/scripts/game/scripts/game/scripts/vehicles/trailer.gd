extends RigidBody3D
class_name TruckTrailer

signal trailer_attached(truck: Node3D)
signal trailer_detached

@export_group("Trailer Settings")
@export var trailer_name: String = "Heavy Cargo Trailer"
@export var trailer_mass: float = 4000.0
@export var cargo_capacity: float = 30000.0

@export_group("Coupling")
@export var coupling_offset: Vector3 = Vector3(0.0, 0.0, 4.0)
@export var coupling_distance: float = 2.0

@export_group("Trailer Physics")
@export var linear_damping_value: float = 0.05
@export var angular_damping_value: float = 1.0

var attached_truck: VehicleBody3D
var hitch_joint: PinJoint3D

var attached: bool = false
var current_cargo_weight: float = 0.0


func _ready() -> void:
    mass = trailer_mass
    linear_damp = linear_damping_value
    angular_damp = angular_damping_value


# ============================================================
# ATTACH TRAILER
# ============================================================

func attach_to_truck(truck: VehicleBody3D) -> bool:

    if attached:
        return false

    if not is_instance_valid(truck):
        return false

    var distance := global_position.distance_to(
        truck.global_position
    )

    if distance > coupling_distance:
        return false

    attached_truck = truck

    hitch_joint = PinJoint3D.new()
    hitch_joint.name = "TrailerHitch"

    truck.add_child(hitch_joint)

    var hitch_position := (
        truck.global_position +
        truck.global_transform.basis * coupling_offset
    )

    hitch_joint.global_position = hitch_position

    hitch_joint.node_a = truck.get_path()
    hitch_joint.node_b = get_path()

    attached = true

    trailer_attached.emit(truck)

    return true


# ============================================================
# DETACH TRAILER
# ============================================================

func detach_from_truck() -> void:

    if not attached:
        return

    if is_instance_valid(hitch_joint):
        hitch_joint.queue_free()

    hitch_joint = null
    attached_truck = null
    attached = false

    trailer_detached.emit()


# ============================================================
# CARGO WEIGHT
# ============================================================

func load_cargo(weight: float) -> bool:

    if weight <= 0.0:
        return false

    if current_cargo_weight + weight > cargo_capacity:
        return false

    current_cargo_weight += weight
    mass = trailer_mass + current_cargo_weight

    return true


func unload_cargo() -> void:

    current_cargo_weight = 0.0
    mass = trailer_mass


# ============================================================
# INFORMATION
# ============================================================

func is_attached() -> bool:
    return attached


func get_cargo_weight() -> float:
    return current_cargo_weight


func get_remaining_capacity() -> float:
    return cargo_capacity - current_cargo_weight


func get_trailer_name() -> String:
    return trailer_name


func get_total_mass() -> float:
    return mass


func _exit_tree() -> void:
    if is_instance_valid(hitch_joint):
        hitch_joint.queue_free()
