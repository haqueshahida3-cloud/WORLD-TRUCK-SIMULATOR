extends CanvasLayer
## Phase 1 HUD — speedometer, tachometer, gear & transmission indicator.

@onready var speed_gauge: Gauge = $UI/SpeedGauge
@onready var rpm_gauge: Gauge = $UI/RpmGauge
@onready var gear_label: Label = $UI/Panel/VBox/GearLabel
@onready var mode_label: Label = $UI/Panel/VBox/ModeLabel
@onready var hint_label: Label = $UI/Hint

var _truck: Truck

func _ready() -> void:
	_truck = get_tree().get_first_node_in_group("player") as Truck
	if _truck == null:
		push_warning("HUD: no truck in 'player' group.")
	# Gauges are known scales — set maxes
	rpm_gauge.max_value = 2800.0
	rpm_gauge.unit_label = "RPM"
	rpm_gauge.needle_color = Color(0.2, 0.7, 1.0)
	speed_gauge.max_value = 140.0
	speed_gauge.unit_label = "km/h"

func _process(_delta: float) -> void:
	if _truck == null:
		return
	speed_gauge.set_value(abs(_truck.speed_kmh))
	rpm_gauge.set_value(_truck.current_rpm)
	gear_label.text = "GEAR  " + _truck.get_gear_name()
	mode_label.text = "AUTO" if _truck.is_automatic() else "MANUAL"
	hint_label.text = "W/S accelerate/brake  •  A/D steer  •  Q/E shift  •  T auto/manual  •  C camera  •  R reset  •  Space handbrake"
