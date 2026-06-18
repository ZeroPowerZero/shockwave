extends Control

## Hit Marker — flashes red X on kill/hit

const COLOR_HIT = Color(1.0, 0.2, 0.2, 0.9)
const SIZE = 10.0
const THICKNESS = 2.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func _draw() -> void:
	var cx = size.x * 0.5
	var cy = size.y * 0.5
	draw_line(Vector2(cx - SIZE, cy - SIZE), Vector2(cx + SIZE, cy + SIZE), COLOR_HIT, THICKNESS)
	draw_line(Vector2(cx + SIZE, cy - SIZE), Vector2(cx - SIZE, cy + SIZE), COLOR_HIT, THICKNESS)
