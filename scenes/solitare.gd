extends Control

const MAX_DECK_OFFSET: Vector2 = Vector2(3, 3)

@export var card_scene: PackedScene

@onready var drag_layer: Control = $DragLayer
@onready var deck: Control = $VSplitContainer/MarginContainer/HBoxContainer/Deck
@onready var rows: Array[VBoxContainer] = [
	$VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row1, $VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row2,
	$VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row3, $VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row4,
	$VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row5, $VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row6,
	$VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row7
]

func _ready() -> void:
	for rank in range(13):
		for suit in range(4):
			var card_instance: Card = card_scene.instantiate() as Card
			card_instance.rank = rank + 1
			card_instance.suit = suit as Card.Suit
			card_instance.face_down = true
			deck.add_child(card_instance)

	shuffle()
	deal()

func get_pile_under_mouse() -> Row:
	for row: Row in rows:
		if row.is_mouse_over:
			return row

	return null

func deal() -> void:
	var cards = deck.get_children()

	var card_index = 0
	for row_index in range(rows.size()):
		var row = rows[row_index]

		var cards_in_row = row_index + 1

		for i in range(cards_in_row):
			var card = cards[card_index] as Card
			card.pile_ref = row
			deck.remove_child(card)
			row.add_child(card)

			# flip only the last card face up
			if i == cards_in_row - 1:
				card.flip()

			card_index += 1


func shuffle() -> void:
	var cards: Array[Node] = deck.get_children()
	cards.shuffle()

	var start := deck.global_position
	var end := deck.global_position + MAX_DECK_OFFSET
	var card_count := cards.size()

	for i in range(card_count):
		deck.move_child(cards[i], i)
		
		var card := cards[i] as Card
		var t := float(i) / float(card_count - 1) if card_count > 1 else 0.0
		card.global_position = start.lerp(end, t)
