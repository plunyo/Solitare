extends PanelContainer


func _ready() -> void:
	for y_offset: HSeparator in [$MarginContainer/HBoxContainer/Row1/OffsetY, $MarginContainer/HBoxContainer/Row2/OffsetY, $MarginContainer/HBoxContainer/Row3/OffsetY, $MarginContainer/HBoxContainer/Row4/OffsetY, $MarginContainer/HBoxContainer/Row5/OffsetY, $MarginContainer/HBoxContainer/Row6/OffsetY]:
		y_offset.add_theme_constant_override("separation", randi_range(0, 10))
