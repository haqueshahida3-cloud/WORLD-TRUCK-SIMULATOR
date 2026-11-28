extends Node3D
class_name CurvedRoadMarkingGenerator

@export_group("Road Reference")
@export var road_generator: CurvedRoadGenerator

@export_group("Marking Settings")
@export var lane_count: int = 4
@export var line_width: float = 0.12
@export var edge_line_width: float = 0.18
@export var marking_height: float = 0.04

@export_group("Dashed Lines")
@export var dash_length: float = 3.0
@export var dash_gap: float = 5.0

@export_group("Colors")
@export var white_color: Color = Color.WHITE
@export var yellow_color: Color = Color.YELLOW

var marking_materials: Dictionary = {}


func _ready() -> void:

    if is_instance_valid(road_generator):
        generate_markings()


# ============================================================
# MAIN GENERATOR
# ============================================================

func generate_markings() -> void:

    clear_markings()

    if not is_instance_valid(road_generator):
        push_warning("Curved marking: Road generator is missing.")
        return

    var points := road_generator.get_road_points()

    if points.size() < 2:
        push_warning("Curved marking: Road path is empty.")
        return

    if lane_count < 1:
        return

    var road_width := road_generator.road_width
    var lane_width := road_width / float(lane_count)

    _create_edge_line(points, -1, road_width * 0.5, edge_line_width, white_color)
    _create_edge_line(points, 1, road_width * 0.5, edge_line_width, white_color)

    for lane_index in range(1, lane_count):

        var offset := (
            -road_width * 0.5
            + float(lane_index) * lane_width
        )

        var is_center := (
            lane_count % 2 == 0
            and lane_index == lane_count / 2
        )

        if is_center:
            _create_solid_path(
                points,
                offset,
                line_width,
                yellow_color
            )
        else:
            _create_dashed_path(
                points,
                offset,
                line_width,
                white_color
            )


# ============================================================
# EDGE LINES
# ============================================================

func _create_edge_line(
    points: PackedVector3Array,
    side_sign: int,
    offset: float,
    width: float,
    color: Color
) -> void:

    var signed_offset := float(side_sign) * offset

    _create_solid_path(
        points,
        signed_offset,
        width,
        color
    )


# ============================================================
# SOLID MARKING
# ============================================================

func _create_solid_path(
    points: PackedVector3Array,
    offset: float,
    width: float,
    color: Color
) -> void:

    for i in range(points.size() - 1):

        var start := _get_offset_point(
            points, i, offset
        )

        var finish := _get_offset_point(
            points, i + 1, offset
        )

        _create_segment(
            start,
            finish,
            width,
            color
        )


# ============================================================
# DASHED MARKING
# ============================================================

func _create_dashed_path(
    points: PackedVector3Array,
    offset: float,
    width: float,
    color: Color
) -> void:

    if dash_length <= 0.0 or dash_gap < 0.0:
        return

    var accumulated_distance := 0.0
    var dash_start := 0.0
    var drawing := true

    for i in range(points.size() - 1):

        var start := _get_offset_point(
            points, i, offset
        )

        var finish := _get_offset_point(
            points, i + 1, offset
        )

        var segment_length := start.distance_to(finish)

        if segment_length <= 0.001:
            continue

        var direction := (finish - start).normalized()
        var position := 0.0

        while position < segment_length:

            var remaining := segment_length - position

            var interval := (
                dash_length - (accumulated_distance - dash_start)
                if drawing
                else dash_gap - (accumulated_distance - dash_start)
            )

            var step := minf(remaining, maxf(interval, 0.001))

            if drawing:

                var dash_from := start + direction * position
                var dash_to := start + direction * (position + step)

                _create_segment(
                    dash_from,
                    dash_to,
                    width,
                    color
                )

            position += step
            accumulated_distance += step

            if accumulated_distance - dash_start >= (
                dash_length if drawing else dash_gap
            ) - 0.001:

                drawing = not drawing
                dash_start = accumulated_distance


# ============================================================
# OFFSET CALCULATION
# ============================================================

func _get_offset_point(
    points: PackedVector3Array,
    index: int,
    offset: float
) -> Vector3:

    var previous := points[maxi(index - 1, 0)]
    var next := points[mini(index + 1, points.size() - 1)]

    var forward := next - previous
    forward.y = 0.0

    if forward.length_squared() < 0.0001:
        forward = Vector3(0, 0, -1)

    forward = forward.normalized()

    var side := Vector3.UP.cross(forward).normalized()

    return points[index] + side * offset + Vector3.UP * marking_height


# ============================================================
# CREATE LINE SEGMENT
# ============================================================

func _create_segment(
    start: Vector3,
    finish: Vector3,
    width: float,
    color: Color
) -> void:

    var length := start.distance_to(finish)

    if length < 0.01:
        return

    var mesh_instance := MeshInstance3D.new()
    var box := BoxMesh.new()

    box.size = Vector3(
        width,
        0.025,
        length
    )

    mesh_instance.mesh = box

    var material_key := color.to_html()

    if not marking_materials.has(material_key):

        var material := StandardMaterial3D.new()
        material.albedo_color = color
        material.roughness = 1.0

        marking_materials[material_key] = material

    mesh_instance.material_override = marking_materials[material_key]

    add_child(mesh_instance)

    var midpoint := (start + finish) * 0.5

    mesh_instance.global_position = midpoint

    mesh_instance.look_at(
        midpoint + (finish - start).normalized(),
        Vector3.UP
    )


# ============================================================
# CLEAR AND REBUILD
# ============================================================

func clear_markings() -> void:

    for child in get_children():
        child.queue_free()

    marking_materials.clear()


func rebuild_markings() -> void:
    generate_markings()


func set_markings_visible(enabled: bool) -> void:
    visible = enabled
