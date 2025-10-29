class_name Card
extends Control

enum Suit { SPADE, CLUB, HEART, DIAMOND }

const CARD_SPRITES_FOLDER: String = "res://assets/cards/"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var card_texture: TextureRect = $Textures/CardTexture
@onready var flipped_texture: TextureRect = $Textures/FlippedTexture
@onready var textures: Control = $Textures

# exported properties
@export var rank: int = 1
@export var suit: Suit = Suit.SPADE
@export var face_down: bool = false

# drag vars
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO         # offset from mouse to the reference card global pos
var drag_sequence: Array = []
var pile_ref: Row = null                         # set by piles when card is added

# keep original global position to snap back if needed
var _original_global_position: Vector2 = Vector2.ZERO

# offsets keyed by instance_id (safer than node keys)
var card_offsets: Dictionary = {}
var drag_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	update_texture()

func update_texture() -> void:
	var suit_path := ""
	match suit:
		Suit.SPADE: suit_path = "spades/"
		Suit.HEART: suit_path = "hearts/"
		Suit.DIAMOND: suit_path = "diamonds/"
		Suit.CLUB: suit_path = "clubs/"

	var rank_file := ""
	if rank >= 1 and rank <= 13:
		rank_file = str(rank) + ".png"
	elif rank == 0:
		rank_file = "back.png"
	else:
		push_warning("Invalid rank: " + str(rank))
		rank_file = "back.png"

	var path := CARD_SPRITES_FOLDER + suit_path + rank_file
	if not ResourceLoader.exists(path):
		push_error("card texture not found: " + path)
		card_texture.texture = null
		return

	var tex = load(path)
	if tex == null:
		push_error("failed to load texture at: " + path)
		card_texture.texture = null
		return

	card_texture.texture = tex as Texture2D

	if face_down:
		flipped_texture.show()
		card_texture.hide()
	else:
		flipped_texture.hide()
		card_texture.show()

func flip() -> void:
	face_down = not face_down
	animation_player.play("flip_card_down" if face_down else "flip_card_up")
	# await the animation_finished signal (returns animation name)
	await animation_player.animation_finished

func is_red() -> bool:
	return suit == Suit.HEART or suit == Suit.DIAMOND

func start_drag(mouse_pos: Vector2) -> void:
	# store original position for fallback
	_original_global_position = global_position
	drag_pos = global_position

	if pile_ref:
		drag_sequence = pile_ref.get_sequence_from_card(self)
		# if the pile says there's no draggable sequence, bail
		if drag_sequence.is_empty():
			return
	else:
		# not part of a pile → just drag this card
		drag_sequence = [self]

	is_dragging = true
	card_offsets.clear()

	# offset relative to mouse so movement feels tight to cursor
	drag_offset = drag_pos - mouse_pos

	for i in range(drag_sequence.size()):
		var card = drag_sequence[i]
		card.z_index = 1000
		card.modulate = Color(1, 1, 1, 0.9)
		# store offset keyed by instance id
		card_offsets[str(card.get_instance_id())] = card.global_position - drag_pos

func _process(_delta: float) -> void:
	if not is_dragging:
		return

	var mouse_pos = get_global_mouse_position()
	for card in drag_sequence:
		var key = str(card.get_instance_id())
		if card_offsets.has(key):
			card.global_position = mouse_pos + drag_offset + card_offsets[key]

func stop_drag() -> void:
	if not is_dragging:
		return

	is_dragging = false

	var game = get_tree().current_scene
	if game == null:
		push_error("current_scene is null in stop_drag")
		# fallback: snap back
		_snap_back()
		_reset_visuals()
		drag_sequence.clear()
		return

	var dest_pile = game.get_pile_under_mouse()
	var dest_foundation: Foundation = game.get_foundation_under_mouse()

	if pile_ref:
		# dragging from a pile
		if dest_pile and dest_pile.can_accept_sequence(drag_sequence):
			pile_ref.move_sequence_to(drag_sequence, dest_pile)
		elif dest_foundation:
			var top_card = drag_sequence[-1]
			if dest_foundation.can_accept(top_card):
				dest_foundation.add_card(top_card)
			else:
				_snap_back() # or however you handle invalid drops
		else:
			pile_ref.return_sequence(drag_sequence)
	else:
		# floating card (not in a pile)
		if dest_pile and dest_pile.can_accept_sequence(drag_sequence):
			# reparent safely while preserving global position
			_safe_reparent_sequence_to(drag_sequence, dest_pile)
			drag_sequence[0].pile_ref = dest_pile
		elif dest_foundation and dest_foundation.can_accept(drag_sequence[-1]):
			_safe_reparent_sequence_to([drag_sequence[-1]], dest_foundation)
		else:
			# fallback: snap back to original container (stock/waste)
			var stock_container = game.stock_container
			if stock_container:
				_safe_reparent_sequence_to(drag_sequence, stock_container)
			else:
				_snap_back()

	_reset_visuals()
	drag_sequence.clear()

# helper: reparent while preserving global position
func _safe_reparent_sequence_to(sequence: Array, new_parent: Node) -> void:
	for card in sequence:
		var old_parent = card.get_parent()
		var saved_global = card.global_position
		if old_parent:
			old_parent.remove_child(card)
		new_parent.add_child(card)
		# restore the same screen position
		card.global_position = saved_global

func _snap_back() -> void:
	for card in drag_sequence:
		card.global_position = _original_global_position
		# if they belong to a container, reparent back (optional)
		if pile_ref and card != null:
			if card.get_parent() != pile_ref:
				pile_ref.add_child(card)
				card.pile_ref = pile_ref

func _reset_visuals() -> void:
	for card in drag_sequence:
		card.z_index = 0
		card.modulate = Color(1, 1, 1, 1)

func _on_textures_gui_input(event: InputEvent) -> void:
	# don't allow dragging if card face-down
	if face_down:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drag(get_global_mouse_position())
		else:
			stop_drag()
