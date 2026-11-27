extends Control
class_name Gauge
## Custom-drawn analog gauge with digital value readout.
## Reusable for speedometer, tachometer, fuel, temperature, etc.

@export var value: float = 0.0
@export var max_value: float = 100.0
@export var unit_label: String = "km/h"
@export var needle_color: Color = Color(1.0, 0.55, 0.1)
@export var bg_color: Color = Color(0.05, 0.05, 0.07, 0.85)

const START_ANGLE := 135.0
const SWEEP := 270.0
const TICK_COUNT := 10

func set_value(v: float) -> void:
	value = clampf(v, 0.0, max_value)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.44

	# Background
	draw_circle(center, radius, bg_color)
	draw_arc(center, radius, deg_to_rad(START_ANGLE),
		deg_to_rad(START_ANGLE + SWEEP), 64, Color(0.5, 0.5, 0.55), 3.0, true)

	# Ticks
	for i in range(TICK_COUNT + 1):
		var t := float(i) / TICK_COUNT
		var angle := deg_to_rad(START_ANGLE + t * SWEEP)
		var dir := Vector2(cos(angle), sin(angle))
		var is_major := i % 5 == 0
		var inner := radius - (14.0 if is_major else 8.0)
		draw_line(center + dir * inner, center + dir * (radius - 4.0),
			Color(0.9, 0.9, 0.9), 2.0 if is_major else 1.0, true)

	# Needle
	var t_val: float = value / max_value
	var angle := deg_to_rad(START_ANGLE + t_val * SWEEP)
	var dir := Vector2(cos(angle), sin(angle))
	draw_line(center - dir * 10.0, center + dir * (radius - 24.0),
		needle_color, 3.0, true)
	draw_circle(center, 6.0, needle_color)

	# Digital readout
	var font := get_theme_default_font()
	var val_str := str(int(round(value)))
	draw_string(font, center + Vector2(-60, 55), val_str,
		HORIZONTAL_ALIGNMENT_CENTER, 120, 26, Color.WHITE)
	draw_string(font, center + Vector2(-60, 78), unit_label,
		HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color(0.65, 0.65, 0.7))
