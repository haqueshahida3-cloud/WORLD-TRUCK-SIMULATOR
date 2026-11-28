extends Node3D
class_name RoadMarkingGenerator

@export_group("Road System")
@export var road_system: RoadLaneSystem

@export_group("Line Settings")
@export var line_width: float = 0.12
@export var line_height: float = 0.025
@export var edge_line_width: float = 0.18

@export_group("Dashed Line Settings")
@export var dash_length: float = 3.0
@export var dash_gap: float = 5.0

@export_group("Colors")
@export var white_color: Color = Color.WHITE
@export var yellow_color: Color = Color.YELLOW

@export_group("Generation")
@export var generate_on_ready: bool = true


func _ready() -> void:

    if generate_on_ready:
        generate_markings()


# ============================================================
# MAIN GENERATOR
# ============================================================

func generate_markings() -> void:

    if not is_instance_valid(road_system):
        push_warning("RoadMarkingGenerator: Road System is not assigned.")
        return

    clear_markings()

    var lane_count := road_system.get_lane_count()

    if lane_count < 1:
        push_warning("RoadMarkingGenerator: No lanes found.")
        return

    var direction := road_system.road_direction.normalized()

    if direction.length_squared() < 0.001:
        push_warning("Road direction is invalid.")
        return

    var lane_positions: Array[Vector3] = []

    for i in range(lane_count):
        lane_positions.append(
            road_system.get_lane_position(i)
        )

    _create_edge_lines(
        lane_positions,
        direction
    )

    _create_lane_dividers(
        lane_positions,
        direction
    )


# ============================================================
# EDGE LINES
# ============================================================

func _create_edge_lines(
    lane_positions: Array[Vector3],
    direction: Vector3
) -> void:

    var lane_count := lane_positions.size()

    var side := Vector3.UP.cross(direction).normalized()

    var half_width := road_system.lane_width * 0.5

    var left_edge := lane_positions[0] - side * half_width
    var right_edge := lane_positions[lane_count - 1] + side * half_width

    var length := road_system.road_length

    _create_solid_line(
        left_edge,
        left_edge + direction * length,
        edge_line_width,
        white_color
    )

    _create_solid_line(
        right_edge,
        right_edge + direction * length,
        edge_line_width,
        white_color
    )


# ============================================================
# LANE DIVIDERS
# ============================================================

func _create_lane_dividers(
    lane_positions: Array[Vector3],
    direction: Vector3
) -> void:

    var lane_count := lane_positions.size()

    var length := road_system.road_length

    for i in range(lane_count - 1):

        var divider_position := (
            lane_positions[i] + lane_positions[i + 1]
        ) * 0.5

        var start := divider_position
        var finish := divider_position + direction * length

        var is_center_divider := (
            lane_count % 2 == 0
            and i == lane_count / 2 - 1
        )

        if is_center_divider:

            _create_solid_line(
                start,
                finish,
                line_width,
                yellow_color
            )

        else:

            _create_dashed_line(
                start,
                finish,
                line_width,
                white_color
            )


# ============================================================
# SOLID LINE
# ============================================================

func _create_solid_line(
    start: Vector3,
    finish: Vector3,
    width: float,
    color: Color
) -> void:

    _create_segment(
        start,
        finish,
        width,
        color
    )


# ============================================================
# DASHED LINE
# ============================================================

func _create_dashed_line(
    start: Vector3,
    finish: Vector3,
    width: float,
    color: Color
) -> void:

    var distance := start.distance_to(finish)

    if distance <= 0.01:
        return

    var direction := (finish - start).normalized()

    var pattern_length := dash_length + dash_gap

    if pattern_length <= 0.01:
        return

    var current_distance := 0.0

    while current_distance < distance:

        var segment_end := minf(
            current_distance + dash_length,
            distance
        )

        var segment_start_position := (
            start + direction * current_distance
        )

        var segment_end_position := (
            start + direction * segment_end
        )

        _create_segment(
            segment_start_position,
            segment_end_position,
            width,
            color
        )

        current_distance += pattern_length


# ============================================================
# MESH CREATION
# ============================================================

func _create_segment(
    start: Vector3,
    finish: Vector3,
    width: float,
    color: Color
) -> void:

    var length := start.distance_to(finish)

    if length <= 0.01:
        return

    var mesh_instance := MeshInstance3D.new()

    var box := BoxMesh.new()

    box.size = Vector3(
        width,
        line_height,
        length
    )

    mesh_instance.mesh = box

    var material := StandardMaterial3D.new()

    material.albedo_color = color
    material.roughness = 1.0

    mesh_instance.material_override = material

    add_child(mesh_instance)

    var midpoint := (start + finish) * 0.5

    mesh_instance.global_position = midpoint
    mesh_instance.look_at(
        midpoint + (finish - start).normalized(),
        Vector3.UP
    )


# ============================================================
# CLEAR GENERATED MARKINGS
# ============================================================

func clear_markings() -> void:

    for child in get_children():
        child.queue_free()


# ============================================================
# PUBLIC CONTROLS
# ============================================================

func rebuild_markings() -> void:
    generate_markings()


func set_marking_visibility(enabled: bool) -> void:
    visible = enabled
