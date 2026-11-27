extends CanvasLayer
class_name TowControlPanel

@export_group("Systems")
@export var winch: TowTruckWinch
@export var rope: TowRopePhysics

@export_group("UI")
@export var panel_position: Vector2 = Vector2(20, 300)
@export var panel_width: float = 300.0

var panel: PanelContainer
var status_label: Label
var cable_label: Label
var boom_label: Label

var boom_up_button: Button
var boom_down_button: Button
var cable_out_button: Button
var cable_in_button: Button
var connect_button: Button
var release_button: Button

var update_timer: float = 0.0


func _ready() -> void:
    _find_systems()
    _create_interface()


func _process(delta: float) -> void:
    update_timer += delta

    if update_timer >= 0.15:
        update_timer = 0.0
        _update_interface()


func _find_systems() -> void:

    if not is_instance_valid(winch):
        winch = get_tree().get_first_node_in_group(
            "tow_truck_winch"
        ) as TowTruckWinch

    if not is_instance_valid(rope):
        rope = get_tree().get_first_node_in_group(
            "tow_rope_physics"
        ) as TowRopePhysics


# ============================================================
# CREATE UI
# ============================================================

func _create_interface() -> void:

    panel = PanelContainer.new()
    panel.position = panel_position
    panel.custom_minimum_size = Vector2(panel_width, 0)
    add_child(panel)

    var layout := VBoxContainer.new()
    panel.add_child(layout)

    var title := Label.new()
    title.text = "HYDRAULIC WINCH CONTROL"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(title)

    status_label = Label.new()
    layout.add_child(status_label)

    boom_label = Label.new()
    layout.add_child(boom_label)

    cable_label = Label.new()
    layout.add_child(cable_label)

    _add_separator(layout)

    var boom_title := Label.new()
    boom_title.text = "HYDRAULIC BOOM"
    layout.add_child(boom_title)

    boom_up_button = _create_button(
        layout,
        "BOOM UP"
    )

    boom_down_button = _create_button(
        layout,
        "BOOM DOWN"
    )

    _add_separator(layout)

    var cable_title := Label.new()
    cable_title.text = "WINCH CABLE"
    layout.add_child(cable_title)

    cable_out_button = _create_button(
        layout,
        "EXTEND CABLE"
    )

    cable_in_button = _create_button(
        layout,
        "RETRACT CABLE"
    )

    _add_separator(layout)

    connect_button = _create_button(
        layout,
        "CONNECT HOOK"
    )

    release_button = _create_button(
        layout,
        "RELEASE HOOK"
    )

    _connect_buttons()


func _add_separator(container: VBoxContainer) -> void:
    var separator := HSeparator.new()
    container.add_child(separator)


func _create_button(
    container: VBoxContainer,
    button_text: String
) -> Button:

    var button := Button.new()
    button.text = button_text
    button.custom_minimum_size = Vector2(0, 42)

    container.add_child(button)

    return button


# ============================================================
# BUTTON EVENTS
# ============================================================

func _connect_buttons() -> void:

    boom_up_button.button_down.connect(
        _on_boom_up_pressed
    )

    boom_down_button.button_down.connect(
        _on_boom_down_pressed
    )

    cable_out_button.button_down.connect(
        _on_cable_out_pressed
    )

    cable_in_button.button_down.connect(
        _on_cable_in_pressed
    )

    connect_button.pressed.connect(
        _on_connect_pressed
    )

    release_button.pressed.connect(
        _on_release_pressed
    )


func _on_boom_up_pressed() -> void:
    if is_instance_valid(winch):
        winch.move_boom(0.25)


func _on_boom_down_pressed() -> void:
    if is_instance_valid(winch):
        winch.lower_boom(0.25)


func _on_cable_out_pressed() -> void:
    if is_instance_valid(winch):
        winch.extend_cable(0.5)


func _on_cable_in_pressed() -> void:
    if is_instance_valid(winch):
        winch.retract_cable(0.5)


func _on_connect_pressed() -> void:

    if not is_instance_valid(winch):
        return

    winch.try_hook_vehicle()

    if is_instance_valid(rope):
        var target := winch.hooked_vehicle

        if is_instance_valid(target):
            rope.connect_vehicle(target)


func _on_release_pressed() -> void:

    if is_instance_valid(rope):
        rope.disconnect_vehicle()

    if is_instance_valid(winch):
        winch.release_vehicle()


# ============================================================
# UPDATE INTERFACE
# ============================================================

func _update_interface() -> void:

    if not is_instance_valid(winch):
        _find_systems()

    if is_instance_valid(winch):

        boom_label.text = "Boom Angle: %.1f°" % (
            winch.get_boom_angle()
        )

        cable_label.text = "Cable Length: %.2f m" % (
            winch.get_cable_length()
        )

        status_label.text = (
            "HOOK: CONNECTED"
            if winch.is_vehicle_hooked()
            else "HOOK: DISCONNECTED"
        )

    else:
        status_label.text = "WINCH SYSTEM NOT FOUND"

    if is_instance_valid(rope):
        if rope.is_connected_to_vehicle():
            status_label.text = "ROPE: CONNECTED"
