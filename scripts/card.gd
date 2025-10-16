class_name Card
extends Control

enum Suit { SPADE, CLUB, HEART, DIAMOND }

const CARD_SPRITES_FOLDER: String = "res://assets/cards/"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var card_texture: TextureRect = $CardTexture
@onready var flipped_texture: TextureRect = $FlippedTexture

@export var rank: int
@export var suit: Suit

@export var flipped: bool = false

func _ready() -> void:
	var rot: float = deg_to_rad(randf_range(-5, 5))
	card_texture.rotation = rot
	flipped_texture.rotation = rot

	var suit_path: String = ""
	match suit:
		Card.Suit.SPADE: suit_path = "spades/"
		Card.Suit.HEART: suit_path = "hearts/"
		Card.Suit.DIAMOND: suit_path = "diamonds/"
		Card.Suit.CLUB: suit_path = "clubs/"
		_:
			suit_path = ""
	
	var rank_file: String = ""
	if rank >= 1 and rank <= 13:
		# pad single-digit numbers with 0
		rank_file = str(rank) + ".png"
	elif rank == 0:
		suit_path = ""
		rank_file = "back.png"
	else:
		push_warning("Invalid card rank: " + str(rank))
		rank_file = "back.png"
	
	var path: String = CARD_SPRITES_FOLDER + suit_path + rank_file
	
	if !ResourceLoader.exists(path):
		push_error("Card texture not found: " + path)
	
	card_texture.texture = load(path) as Texture2D

	if flipped:
		$FlippedTexture.show()

func flip() -> void:
	flipped = !flipped
	if randi_range(1, 100) == 100:
		animation_player.play("vertical_flip_card_down" if flipped else "vertical_flip_card_up")
	else:
		animation_player.play("flip_card_down" if flipped else "flip_card_up")
	await animation_player.animation_finished
