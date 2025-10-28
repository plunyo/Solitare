extends Control
class_name Card

enum Suit { SPADE, CLUB, HEART, DIAMOND }

const CARD_SPRITES_FOLDER: String = "res://assets/cards/"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var card_texture: TextureRect = $Textures/CardTexture
@onready var flipped_texture: TextureRect = $Textures/FlippedTexture
@onready var textures: Control = $Textures
@onready var drag_layer: Control = get_tree().current_scene.get_node("DragLayer")

@export var rank: int
@export var suit: Suit
@export var face_down: bool = false

# drag vars
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var drag_sequence: Array = []
var pile_ref: Row

func _ready() -> void:
	update_texture()

func update_texture() -> void:
	var suit_path: String = ""
	match suit:
		Suit.SPADE: suit_path = "spades/"
		Suit.HEART: suit_path = "hearts/"
		Suit.DIAMOND: suit_path = "diamonds/"
		Suit.CLUB: suit_path = "clubs/"

	var rank_file: String = ""
	if rank >= 1 and rank <= 13:
		rank_file = str(rank) + ".png"
	elif rank == 0:
		rank_file = "back.png"
	else:
		push_warning("Invalid rank: "+str(rank))
		rank_file = "back.png"

	var path: String = CARD_SPRITES_FOLDER + suit_path + rank_file
	if !ResourceLoader.exists(path):
		push_error("Card texture not found: "+path)

	card_texture.texture = load(path) as Texture2D

	if face_down:
		flipped_texture.show()
		card_texture.hide()
	else:
		flipped_texture.hide()
		card_texture.show()

func flip() -> void:
	face_down = !face_down
	animation_player.play("flip_card_down" if face_down else "flip_card_up")
	await animation_player.animation_finished

func is_red() -> bool:
	return suit == Suit.HEART or suit == Suit.DIAMOND

var card_offsets: Dictionary = {}

func start_drag(mouse_pos: Vector2) -> void:
	if pile_ref == null: return

	drag_sequence = pile_ref.get_sequence_from_card(self)
	if drag_sequence.is_empty(): return

	is_dragging = true
	card_offsets.clear()

	# lift all cards visually
	for i in range(drag_sequence.size()):
		var card = drag_sequence[i]
		card.z_index = 1000
		card.modulate = Color(1,1,1,0.9)
		card_offsets[card] = card.global_position - global_position

	drag_offset = global_position - mouse_pos

func _process(_delta: float) -> void:
	if is_dragging:
		var mouse_pos = get_global_mouse_position()
		for card in drag_sequence:
			card.global_position = mouse_pos + drag_offset + card_offsets[card]

func stop_drag() -> void:
	is_dragging = false

	var game = get_tree().current_scene
	var dest_pile = game.get_pile_under_mouse()
	var dest_foundation: Foundation = game.get_foundation_under_mouse()

	if dest_pile and dest_pile.can_accept_sequence(drag_sequence):
		pile_ref.move_sequence_to(drag_sequence, dest_pile)
	elif dest_foundation and dest_foundation.can_accept(drag_sequence[-1]):
		dest_foundation.add_card(drag_sequence[-1])
	else:
		pile_ref.return_sequence(drag_sequence)

	for card in drag_sequence:
		card.z_index = 0
		card.modulate = Color(1, 1, 1, 1)

	drag_sequence.clear()


func _on_textures_gui_input(event: InputEvent) -> void:
	if face_down:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drag(get_global_mouse_position())
		else:
			stop_drag()
