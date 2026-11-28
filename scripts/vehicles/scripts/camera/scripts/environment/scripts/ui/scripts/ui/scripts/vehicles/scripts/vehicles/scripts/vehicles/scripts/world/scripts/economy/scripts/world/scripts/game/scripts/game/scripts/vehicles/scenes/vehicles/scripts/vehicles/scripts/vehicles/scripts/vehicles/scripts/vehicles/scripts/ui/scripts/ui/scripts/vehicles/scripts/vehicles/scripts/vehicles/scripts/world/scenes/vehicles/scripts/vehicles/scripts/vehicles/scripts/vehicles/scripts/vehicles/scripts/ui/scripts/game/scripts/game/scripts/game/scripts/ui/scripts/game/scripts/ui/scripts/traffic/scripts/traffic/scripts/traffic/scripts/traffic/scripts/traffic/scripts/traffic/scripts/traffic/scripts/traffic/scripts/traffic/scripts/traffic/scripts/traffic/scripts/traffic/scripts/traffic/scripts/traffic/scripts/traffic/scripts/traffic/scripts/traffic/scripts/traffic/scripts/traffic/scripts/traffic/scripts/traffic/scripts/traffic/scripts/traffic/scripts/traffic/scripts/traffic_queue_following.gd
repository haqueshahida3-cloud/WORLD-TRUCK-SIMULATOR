extends Node
class_name TrafficQueueFollowing

@export_group("References")
@export var vehicle: CharacterBody3D
@export var queue_manager: TrafficQueueManager

@export_group("Movement")
@export var max_speed := 12.0
@export var acceleration := 5.0
@export var braking := 12.0

@export_group("Safety")
@export var safe_distance := 8.0
@export var stop_distance := 2.0

var target_speed := 0.0
var queue_index := -1
var following := false


func _physics_process(delta):
    if not is_instance_valid(vehicle):
        return

    if not is_instance_valid(queue_manager):
        return

    update_queue_target()
    calculate_speed(delta)


func update_queue_target():
    queue_index = queue_manager.get_queue_index(vehicle)
    following = queue_index >= 0

    if not following:
        target_speed = max_speed
        return

    var target = queue_manager.get_queue_position(vehicle)
    var distance = vehicle.global_position.distance_to(target)

    if distance <= stop_distance:
        target_speed = 0.0
    else:
        target_speed = max_speed


func calculate_speed(delta):
    var desired_speed = target_speed

    if following:
        var index = queue_index

        if index > 0:
            var front_vehicle = queue_manager.vehicles[index - 1]

            if is_instance_valid(front_vehicle):
                var gap = vehicle.global_position.distance_to(
                    front_vehicle.global_position
                )

                if gap < safe_distance:
                    desired_speed = minf(
                        desired_speed,
                        max_speed * clampf(
                            gap / safe_distance,
                            0.0,
                            1.0
                        )
                    )

    var rate = acceleration if desired_speed > target_speed else braking

    target_speed = move_toward(
        target_speed,
        desired_speed,
        rate * delta
    )


func get_target_speed() -> float:
    return target_speed


func is_queue_following() -> bool:
    return following


func set_max_speed(value: float):
    max_speed = maxf(value, 0.0)


func stop_following():
    following = false
    target_speed = 0.0
