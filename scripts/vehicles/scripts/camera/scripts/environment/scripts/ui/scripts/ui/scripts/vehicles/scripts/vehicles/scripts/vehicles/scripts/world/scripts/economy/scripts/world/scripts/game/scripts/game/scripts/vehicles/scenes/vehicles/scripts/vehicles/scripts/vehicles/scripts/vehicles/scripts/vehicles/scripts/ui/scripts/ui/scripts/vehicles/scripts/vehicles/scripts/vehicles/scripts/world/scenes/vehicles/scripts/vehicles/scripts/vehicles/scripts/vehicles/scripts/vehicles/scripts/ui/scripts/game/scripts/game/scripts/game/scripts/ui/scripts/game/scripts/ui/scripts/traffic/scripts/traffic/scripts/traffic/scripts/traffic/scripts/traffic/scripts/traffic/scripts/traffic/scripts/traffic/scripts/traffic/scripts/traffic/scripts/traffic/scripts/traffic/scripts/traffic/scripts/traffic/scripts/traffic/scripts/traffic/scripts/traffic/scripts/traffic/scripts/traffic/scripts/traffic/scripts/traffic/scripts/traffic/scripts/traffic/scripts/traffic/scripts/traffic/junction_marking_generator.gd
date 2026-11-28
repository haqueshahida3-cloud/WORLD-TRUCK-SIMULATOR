extends Node3D
class_name JunctionMarkingGenerator

@export_group("Junction Reference")
@export var junction: RoadJunctionGenerator

@export_group("Road Settings")
@export var road_width: float = 14.0
@export var junction_width: float = 16.0
@export var junction_length: float = 16.0

@export_group("Marking Settings")
@export var marking_height: float = 0.06
@export var line_width: float = 0.15
@export var stop_line_width: float = 0.35

@export_group("Crosswalk")
@export var crosswalk_enabled: bool = true
@export var zebra_stripe_count: int = 8
@export var zebra_stripe_width: float = 0.45
@export var zebra_stripe_gap: float = 0.35

@export_group("Visibility")
@export var show_stop_lines: bool = true
@export var show_lane_lines: bool = true
@export var show_direction_arrows: bool = true

@export_group("Colors")
@export var white_color: Color = Color.WHITE
@export var yellow_color: Color = Color.YELLOW

var white_material: StandardMaterial3D
var yellow_material: StandardMaterial3D


func _ready() -> void:
    generate_markings()


# ============================================================
# MAIN GENERATOR
# ============================================================

func generate_markings() -> void:

    clear_markings()

    if is_instance_valid(junction):
        road_width = junction.road_width
        junction_width = junction.junction_width
        junction_length = junction.junction_length

    _create_materials()

    if show_stop_lines:
        _create_stop_lines()

    if crosswalk_enabled:
        _create_crosswalks()

    if show_lane_lines:
        _create_lane_lines()

    if show_direction_arrows:
        _create_direction_arrows()


# ============================================================
# MATERIALS
# ============================================================

func _create_materials() -> void:

    white_material = StandardMaterial3D.new()
    white_material.albedo_color = white_color
    white_material.roughness = 1.0

    yellow_material = StandardMaterial3D.new()
    yellow_material.albedo_color = yellow_color
    yellow_material.roughness = 1.0


# ============================================================
# STOP LINES
# ============================================================

func _create_stop_lines() -> void:

    var half_road := road_width * 0.5
    var half_junction_x := junction_width * 0.5
    var half_junction_z := junction_length * 0.5

    if _connection_enabled("north"):
        _create_box(
            Vector3(0, marking_height, -half_junction_z - 1.5),
            Vector3(road_width, 0.025, stop_line_width),
            white_material
        )

    if _connection_enabled("south"):
        _create_box(
            Vector3(0, marking_height, half_junction_z + 1.5),
            Vector3(road_width, 0.025, stop_line_width),
            white_material
        )

    if _connection_enabled("east"):
        _create_box(
            Vector3(half_junction_x + 1.5, marking_height, 0),
            Vector3(stop_line_width, 0.025, road_width),
            white_material
        )

    if _connection_enabled("west"):
        _create_box(
            Vector3(-half_junction_x - 1.5, marking_height, 0),
            Vector3(stop_line_width, 0.025, road_width),
            white_material
        )


# ============================================================
# ZEBRA CROSSINGS
# ============================================================

func _create_crosswalks() -> void:

    var half_x := junction_width * 0.5
    var half_z := junction_length * 0.5

    if _connection_enabled("north"):
        _create_zebra(
            Vector3(0, marking_height, -half_z - 3.5),
            true
        )

    if _connection_enabled("south"):
        _create_zebra(
            Vector3(0, marking_height, half_z + 3.5),
            true
        )

    if _connection_enabled("east"):
        _create_zebra(
            Vector3(half_x + 3.5, marking_height, 0),
            false
        )

    if _connection_enabled("west"):
        _create_zebra(
            Vector3(-half_x - 3.5, marking_height, 0),
            false
        )


func _create_zebra(center: Vector3, horizontal: bool) -> void:

    var count := maxi(zebra_stripe_count, 1)

    for i in range(count):

        var offset := (
            float(i) - float(count - 1) * 0.5
        ) * (zebra_stripe_width + zebra_stripe_gap)

        var position := center

        var size: Vector3

        if horizontal:
            position.x += offset
            size = Vector3(
                zebra_stripe_width,
                0.025,
                2.2
            )
        else:
            position.z += offset
            size = Vector3(
                2.2,
                0.025,
                zebra_stripe_width
            )

        _create_box(position, size, white_material)


# ============================================================
# LANE DIVIDERS
# ============================================================

func _create_lane_lines() -> void:

    var lane_count := 4
    var lane_width := road_width / float(lane_count)

    for i in range(1, lane_count):

        var offset := (
            -road_width * 0.5
            + float(i) * lane_width
        )

        if absf(offset) < 0.01:
            continue

        if _connection_enabled("north"):
            _create_box(
                Vector3(offset, marking_height, -junction_length * 0.5 - 2.0),
                Vector3(line_width, 0.025, 3.0),
                white_material
            )

        if _connection_enabled("south"):
            _create_box(
                Vector3(offset, marking_height, junction_length * 0.5 + 2.0),
                Vector3(line_width, 0.025, 3.0),
                white_material
            )

        if _connection_enabled("east"):
            _create_box(
                Vector3(junction_width * 0.5 + 2.0, marking_height, offset),
                Vector3(3.0, 0.025, line_width),
                white_material
            )

        if _connection_enabled("west"):
            _create_box(
                Vector3(-junction_width * 0.5 - 2.0, marking_height, offset),
                Vector3(3.0, 0.025, line_width),
                white_material
            )


# ============================================================
# DIRECTION ARROWS
# ============================================================

func _create_direction_arrows() -> void:

    var half_x := junction_width * 0.5
    var half_z := junction_length * 0.5

    if _connection_enabled("north"):
        _create_arrow(
            Vector3(0, marking_height, -half_z - 7.0),
            PI
        )

    if _connection_enabled("south"):
        _create_arrow(
            Vector3(0, marking_height, half_z + 7.0),
            0.0
        )

    if _connection_enabled("east"):
        _create_arrow(
            Vector3(half_x + 7.0, marking_height, 0),
            PI * 0.5
        )

    if _connection_enabled("west"):
        _create_arrow(
            Vector3(-half_x - 7.0, marking_height, 0),
            -PI * 0.5
        )


func _create_arrow(position: Vector3, rotation_y: float) -> void:

    var arrow := MeshInstance3D.new()
    var mesh := BoxMesh.new()

    mesh.size = Vector3(0.35, 0.025, 2.2)

    arrow.mesh = mesh
    arrow.material_override = white_material

    add_child(arrow)

    arrow.position = position
    arrow.rotation.y = rotation_y

    _create_box(
        position + Vector3(0, 0, -0.75).rotated(Vector3.UP, rotation_y),
        Vector3(1.0, 0.025, 0.35),
        white_material
    )


# ============================================================
# BOX MARKING
# ============================================================

func _create_box(
    position: Vector3,
    size: Vector3,
    material: Material
) -> void:

    var instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()

    mesh.size = size

    instance.mesh = mesh
    instance.material_override = material

    add_child(instance)
    instance.position = position


# ============================================================
# CONNECTION CHECK
# ============================================================

func _connection_enabled(direction: String) -> bool:

    if not is_instance_valid(junction):
        return true

    match direction:
        "north":
            return junction.connect_north
        "south":
            return junction.connect_south
        "east":
            return junction.connect_east
        "west":
            return junction.connect_west

    return false


# ============================================================
# CLEAR AND REBUILD
# ============================================================

func clear_markings() -> void:

    for child in get_children():
        child.queue_free()

    white_material = null
    yellow_material = null


func rebuild_markings() -> void:
    generate_markings()


func set_markings_visible(enabled: bool) -> void:
    visible = enabled
