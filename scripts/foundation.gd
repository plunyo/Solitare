extends CenterContainer
class_name Foundation

@export var suit: Card.Suit
var cards: Array[Card] = []

var is_mouse_over: bool

func _input(_event: InputEvent) -> void:
	is_mouse_over = get_global_rect().has_point(get_global_mouse_position())

func can_accept(card: Card) -> bool:
	if card.suit != suit:
		return false

	# empty foundation only accepts an Ace
	if cards.is_empty():
		return card.rank == 1

	# next card must be one higher
	var top_card = cards[-1]
	return card.rank == top_card.rank + 1


func add_card(card: Card) -> void:
	cards.append(card)
	card.reparent(self)
	card.pile_ref = null

func get_top_rank() -> int:
	return cards[-1].rank if not cards.is_empty() else 0
