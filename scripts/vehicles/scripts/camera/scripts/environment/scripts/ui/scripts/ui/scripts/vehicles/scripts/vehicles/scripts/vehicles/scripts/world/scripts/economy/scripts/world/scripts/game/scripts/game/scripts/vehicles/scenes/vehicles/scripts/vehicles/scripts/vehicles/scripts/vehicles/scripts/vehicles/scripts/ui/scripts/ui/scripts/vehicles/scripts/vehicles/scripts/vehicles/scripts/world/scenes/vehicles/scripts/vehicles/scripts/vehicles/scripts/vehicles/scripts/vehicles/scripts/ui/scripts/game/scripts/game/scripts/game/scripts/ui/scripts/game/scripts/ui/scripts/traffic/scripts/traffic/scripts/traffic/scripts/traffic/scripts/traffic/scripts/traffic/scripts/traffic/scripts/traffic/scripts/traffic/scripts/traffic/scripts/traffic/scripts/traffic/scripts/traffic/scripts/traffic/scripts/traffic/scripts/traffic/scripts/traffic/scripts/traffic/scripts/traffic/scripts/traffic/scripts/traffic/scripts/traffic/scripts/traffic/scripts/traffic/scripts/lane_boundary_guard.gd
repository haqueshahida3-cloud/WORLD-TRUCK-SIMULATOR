extends Node
class_name LaneBoundaryGuard

signal boundary_warning(distance: float)
signal vehicle_outside_lane
signal lane_position_restored

@export_group("Vehicle")
@export var vehicle: CharacterBody3D

@export_group("Lane")
@export var lane_center: Marker3D
@export var lane_width := 3.5
@export var warning_margin := 0.4

var outside_lane := false
var lateral_offset := 0.0


func _physics_process(_delta):
    if not is_instance_valid(vehicle):
        return

    if not is_instance_valid(lane_center):
        return

    check_lane_position()


func check_lane_position():
    var lane_forward := -lane_center.global_basis.z
    lane_forward.y = 0.0
    lane_forward = lane_forward.normalized()

    var lane_right := lane_center.global_basis.x
    lane_right.y = 0.0
    lane_right = lane_right.normalized()

    var offset := vehicle.global_position - lane_center.global_position

    lateral_offset = offset.dot(lane_right)

    var half_width := lane_width * 0.5
    var distance_to_boundary := half_width - absf(lateral_offset)

    if distance_to_boundary <= 0.0:
        if not outside_lane:
            outside_lane = true
            vehicle_outside_lane.emit()

    elif distance_to_boundary <= warning_margin:
        boundary_warning.emit(distance_to_boundary)

    elif outside_lane:
        outside_lane = false
        lane_position_restored.emit()


func get_lateral_offset() -> float:
    return lateral_offset


func get_distance_to_boundary() -> float:
    return (lane_width * 0.5) - absf(lateral_offset)


func is_outside_lane() -> bool:
    return outside_lane


func get_steering_correction() -> float:
    if not is_instance_valid(vehicle):
        return 0.0

    var correction := -lateral_offset / maxf(lane_width * 0.5, 0.1)
    return clampf(correction, -1.0, 1.0)


func reset_guard():
    outside_lane = false
    lateral_offset = 0.0
