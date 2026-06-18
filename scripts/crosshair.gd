extends Control

## Crosshair drawn procedurally

const COLOR = Color(1.0, 1.0, 1.0, 0.85)
const GAP = 6.0
const LENGTH = 10.0
const THICKNESS = 1.5
const DOT_SIZE = 2.0

func _ready() -> void:
	# Fill entire viewport so center is always correct
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var cx = size.x * 0.5
	var cy = size.y * 0.5

	# Left
	draw_line(Vector2(cx - GAP - LENGTH, cy), Vector2(cx - GAP, cy), COLOR, THICKNESS)
	# Right
	draw_line(Vector2(cx + GAP, cy), Vector2(cx + GAP + LENGTH, cy), COLOR, THICKNESS)
	# Up
	draw_line(Vector2(cx, cy - GAP - LENGTH), Vector2(cx, cy - GAP), COLOR, THICKNESS)
	# Down
	draw_line(Vector2(cx, cy + GAP), Vector2(cx, cy + GAP + LENGTH), COLOR, THICKNESS)
	# Center dot
	draw_circle(Vector2(cx, cy), DOT_SIZE * 0.5, COLOR)
