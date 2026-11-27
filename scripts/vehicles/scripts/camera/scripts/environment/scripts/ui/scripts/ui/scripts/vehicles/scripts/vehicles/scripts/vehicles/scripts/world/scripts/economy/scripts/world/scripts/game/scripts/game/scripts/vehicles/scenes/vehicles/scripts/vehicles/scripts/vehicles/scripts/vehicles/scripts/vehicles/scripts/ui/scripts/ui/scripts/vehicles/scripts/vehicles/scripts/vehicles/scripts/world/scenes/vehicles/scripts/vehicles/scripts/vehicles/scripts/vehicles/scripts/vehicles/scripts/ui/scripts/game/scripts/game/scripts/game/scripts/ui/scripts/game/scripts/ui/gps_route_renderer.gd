extends Node3D
class_name GPSRouteRenderer

signal navigation_instruction_changed(instruction: String)

@export_group("References")
@export var truck: VehicleBody3D
@export var route_planner: RoadRoutePlanner

@export_group("Route Display")
@export var line_height: float = 0.5
@export var route_color: Color = Color(0.1, 0.9, 1.0)
@export var update_interval: float = 0.25
@export var arrival_distance: float = 15.0

var route_mesh_instance: MeshInstance3D
var route_mesh: ImmediateMesh
var route_material: StandardMaterial3D

var instruction_label: Label
var distance_label: Label

var route_points: Array[Vector3] = []
var current_segment: int = 0
var update_timer: float = 0.0
var navigation_active: bool = false


func _ready() -> void:
    _find_references()
    _create_route_renderer()
    _create_navigation_ui()

    if is_instance_valid(route_planner):
        if not route_planner.route_calculated.is_connected(
            _on_route_calculated
        ):
            route_planner.route_calculated.connect(
                _on_route_calculated
            )


func _process(delta: float) -> void:

    update_timer += delta

    if update_timer < update_interval:
        return

    update_timer = 0.0

    _find_references()

    if not navigation_active:
        return

    _update_navigation()


func _find_references() -> void:

    if not is_instance_valid(truck):
        truck = get_tree().get_first_node_in_group(
            "tow_truck"
        ) as VehicleBody3D

    if not is_instance_valid(route_planner):
        route_planner = get_tree().get_first_node_in_group(
            "road_route_planner"
        ) as RoadRoutePlanner


# ============================================================
# CREATE 3D ROUTE RENDERER
# ============================================================

func _create_route_renderer() -> void:

    route_mesh_instance = MeshInstance3D.new()
    route_mesh_instance.name = "GPSRouteLine"

    route_mesh = ImmediateMesh.new()
    route_mesh_instance.mesh = route_mesh

    route_material = StandardMaterial3D.new()
    route_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    route_material.albedo_color = route_color
    route_material.no_depth_test = false

    route_mesh_instance.material_override = route_material

    add_child(route_mesh_instance)


# ============================================================
# CREATE NAVIGATION UI
# ============================================================

func _create_navigation_ui() -> void:

    var canvas := CanvasLayer.new()
    canvas.name = "NavigationUI"
    add_child(canvas)

    var panel := PanelContainer.new()
    panel.position = Vector2(20, 260)
    panel.custom_minimum_size = Vector2(230, 85)
    canvas.add_child(panel)

    var layout := VBoxContainer.new()
    panel.add_child(layout)

    instruction_label = Label.new()
    instruction_label.text = "GPS: Waiting..."
    instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(instruction_label)

    distance_label = Label.new()
    distance_label.text = "Distance: --"
    distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(distance_label)


# ============================================================
# RECEIVE ROUTE
# ============================================================

func _on_route_calculated(
    new_route: Array,
    total_distance: float
) -> void:

    route_points.clear()

    for point in new_route:

        if point is Vector3:
            route_points.append(point)

    if route_points.size() < 2:
        clear_navigation()
        return

    current_segment = 0
    navigation_active = true

    _draw_route()

    instruction_label.text = "Route calculated"
    _update_distance(total_distance)


# ============================================================
# DRAW 3D ROUTE
# ============================================================

func _draw_route() -> void:

    route_mesh.clear_surfaces()

    if route_points.size() < 2:
        return

    route_mesh.surface_begin(
        Mesh.PRIMITIVE_LINE_STRIP,
        route_material
    )

    for point in route_points:

        var world_point := point + Vector3(
            0.0,
            line_height,
            0.0
        )

        var local_point := to_local(world_point)

        route_mesh.surface_add_vertex(local_point)

    route_mesh.surface_end()


# ============================================================
# UPDATE NAVIGATION
# ============================================================

func _update_navigation() -> void:

    if not is_instance_valid(truck):
        return

    if route_points.size() < 2:
        return

    var truck_position := truck.global_position

    current_segment = _find_nearest_segment(
        truck_position
    )

    var target_position: Vector3 = route_points[
        min(current_segment + 1, route_points.size() - 1)
    ]

    var distance := truck_position.distance_to(
        target_position
    )

    _update_distance(distance)

    if current_segment >= route_points.size() - 2:
        if distance <= arrival_distance:
            instruction_label.text = "You have arrived!"
            navigation_instruction_changed.emit(
                "You have arrived!"
            )
            clear_navigation()
            return

    _update_turn_instruction()


# ============================================================
# FIND NEAREST ROUTE SEGMENT
# ============================================================

func _find_nearest_segment(position: Vector3) -> int:

    var nearest_index := 0
    var nearest_distance := INF

    for i in range(route_points.size() - 1):

        var distance := position.distance_to(
            route_points[i]
        )

        if distance < nearest_distance:
            nearest_distance = distance
            nearest_index = i

    return nearest_index


# ============================================================
# TURN BY TURN INSTRUCTIONS
# ============================================================

func _update_turn_instruction() -> void:

    if route_points.size() < 3:
        return

    var next_index := current_segment + 1

    if next_index >= route_points.size() - 1:
        instruction_label.text = "Continue to destination"
        return

    var first_direction := (
        route_points[next_index] -
        route_points[current_segment]
    )

    var second_direction := (
        route_points[next_index + 1] -
        route_points[next_index]
    )

    first_direction.y = 0.0
    second_direction.y = 0.0

    if first_direction.length_squared() < 0.001:
        return

    if second_direction.length_squared() < 0.001:
        return

    first_direction = first_direction.normalized()
    second_direction = second_direction.normalized()

    var cross_value := (
        first_direction.x * second_direction.z -
        first_direction.z * second_direction.x
    )

    var dot_value := first_direction.dot(
        second_direction
    )

    var instruction := "Continue straight"

    if dot_value < -0.7:
        instruction = "Turn around"

    elif cross_value > 0.25:
        instruction = "Turn left"

    elif cross_value < -0.25:
        instruction = "Turn right"

    instruction_label.text = instruction

    navigation_instruction_changed.emit(instruction)


# ============================================================
# DISTANCE
# ============================================================

func _update_distance(distance: float) -> void:

    if distance >= 1000.0:
        distance_label.text = "Distance: %.2f km" % (
            distance / 1000.0
        )
    else:
        distance_label.text = "Distance: %.0f m" % distance


# ============================================================
# PUBLIC FUNCTIONS
# ============================================================

func start_navigation(
    start_position: Vector3,
    destination_position: Vector3
) -> bool:

    _find_references()

    if not is_instance_valid(route_planner):
        return false

    return route_planner.calculate_route(
        start_position,
        destination_position
    )


func clear_navigation() -> void:

    navigation_active = false
    route_points.clear()

    if is_instance_valid(route_mesh):
        route_mesh.clear_surfaces()

    if is_instance_valid(instruction_label):
        instruction_label.text = "GPS: Inactive"

    if is_instance_valid(distance_label):
        distance_label.text = "Distance: --"


func is_navigation_active() -> bool:
    return navigation_active
