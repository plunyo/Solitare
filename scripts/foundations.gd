extends PanelContainer

func _ready() -> void:
	for foundation_shadow: CenterContainer in $CenterContainer/VBoxContainer.get_children():
		for texture: TextureRect in foundation_shadow.get_children():
			texture.rotation += deg_to_rad(randf_range(-5, 5))
