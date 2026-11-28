extends Node
class_name LaneChangeGuard

signal lane_change_allowed
signal lane_change_blocked(reason: String)

@export_group("Vehicle")
@export var vehicle: CharacterBody3D
@export var detection_area: Area3D

@export_group("Safety")
@export var front_safe_distance := 12.0
@export var rear_safe_distance := 15.0
@export var lane_width := 3.5
@export var minimum_rear_speed_margin := 5.0

var last_block_reason := ""


func can_change_lane(lane_offset: Vector3) -> bool:
    if not is_instance_valid(vehicle):
        return false

    if not is_instance_valid(detection_area):
        return false

    var forward := -vehicle.global_basis.z
    forward.y = 0.0
    forward = forward.normalized()

    var target_center := vehicle.global_position + lane_offset
    var my_speed := vehicle.velocity.dot(forward)

    for body in detection_area.get_overlapping_bodies():
        if body == vehicle:
            continue

        if not body.is_in_group("traffic_vehicles"):
            continue

        if not body is CharacterBody3D:
            continue

        var offset := body.global_position - target_center
        offset.y = 0.0

        var longitudinal := offset.dot(forward)
        var lateral := (offset - forward * longitudinal).length()

        if lateral > lane_width * 0.5:
            continue

        var other_speed := body.velocity.dot(forward)

        if longitudinal > 0.0:
            if longitudinal < front_safe_distance:
                return block_lane_change("Vehicle ahead is too close")

        elif longitudinal < 0.0:
            var rear_distance := absf(longitudinal)
            var closing_speed := other_speed - my_speed

            if rear_distance < rear_safe_distance:
                return block_lane_change("Vehicle behind is too close")

            if closing_speed > minimum_rear_speed_margin:
                return block_lane_change("Fast vehicle approaching from behind")

    last_block_reason = ""
    lane_change_allowed.emit()
    return true


func block_lane_change(reason: String) -> bool:
    last_block_reason = reason
    lane_change_blocked.emit(reason)
    return false


func get_block_reason() -> String:
    return last_block_reason
