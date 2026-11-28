extends Node3D
class_name RoadEdgeGuard

signal road_edge_warning(direction: String)
signal road_surface_lost
signal road_surface_detected

@export_group("Vehicle")
@export var vehicle: CharacterBody3D

@export_group("Detection")
@export var left_ray: RayCast3D
@export var right_ray: RayCast3D
@export var front_ray: RayCast3D

@export_group("Settings")
@export var check_interval := 0.15

var surface_lost := false
var check_timer := 0.0


func _physics_process(delta):
    if not is_instance_valid(vehicle):
        return

    check_timer += delta

    if check_timer < check_interval:
        return

    check_timer = 0.0
    check_road_edges()


func check_road_edges():
    var left_safe := is_road_detected(left_ray)
    var right_safe := is_road_detected(right_ray)
    var front_safe := is_road_detected(front_ray)

    if not left_safe:
        road_edge_warning.emit("left")

    if not right_safe:
        road_edge_warning.emit("right")

    if not front_safe:
        if not surface_lost:
            surface_lost = true
            road_surface_lost.emit()
    elif surface_lost:
        surface_lost = false
        road_surface_detected.emit()


func is_road_detected(ray: RayCast3D) -> bool:
    if not is_instance_valid(ray):
        return false

    ray.force_raycast_update()
    return ray.is_colliding()


func is_surface_lost() -> bool:
    return surface_lost


func get_safe_direction() -> Vector3:
    var direction := Vector3.ZERO

    if not is_road_detected(left_ray):
        direction += vehicle.global_basis.x

    if not is_road_detected(right_ray):
        direction -= vehicle.global_basis.x

    direction.y = 0.0
    return direction.normalized()


func reset_guard():
    surface_lost = false
    check_timer = 0.0
