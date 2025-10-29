extends CenterContainer
class_name Foundation

@export var suit: Card.Suit
var is_mouse_over: bool = false

func _input(_event: InputEvent) -> void:
	is_mouse_over = get_global_rect().has_point(get_global_mouse_position())

func can_accept(card: Card) -> bool:
	var cards = get_children().filter(func(x) -> bool: return x is Card)
	# helpful debug
	print("can_accept? foundation suit: ", suit, " card suit: ", card.suit, " rank: ", card.rank, " cards: ", cards.size())

	# suit must match
	if card.suit != suit:
		print("reject: wrong suit")
		return false

	# empty foundation only accepts an Ace (rank == 1)
	if cards.is_empty():
		print("foundation empty -> accepting ace? ", card.rank == 1)
		return card.rank == 1

	# otherwise must be one higher than top card
	var top_card: Card = cards[-1]
	print("top card rank:", top_card.rank)
	return card.rank == top_card.rank + 1


func add_card(card: Card) -> void:
	var cards = get_children().filter(func(x) -> bool: return x is Card)
	
	# defensive
	if not card:
		push_error("add_card called with null card")
		return

	# record info for debugging
	print("add_card() called for card: ", card.name, "rank: ", card.rank, "suit: ", card.suit)

	# capture global position in a type-safe way
	var saved_global := Vector2.ZERO
	var card_is_control := card is Control

	if card_is_control:
		# Control: use rect global position
		saved_global = card.global_position
	else:
		# fallback
		saved_global = card.global_position if card.has_method("get_global_position") else Vector2.ZERO

	# append to our internal stack first
	cards.append(card)

	# reparent while preserving screen position
	var old_parent := card.get_parent()
	if old_parent:
		old_parent.remove_child(card)
	add_child(card)

	if card_is_control:
		card.global_position = saved_global
	else:
		# best-effort fallback
		if card.has_method("set_global_position"):
			card.set_global_position(saved_global)

	# if the card came from a pile, tell that pile to update (safe check)
	if card.pile_ref:
		var pile_ref = card.pile_ref
		if pile_ref and pile_ref.has_method("flip_last"):
			pile_ref.flip_last()
		card.pile_ref = null

	print("card added. foundation now has ", cards.size(), " cards")

func get_top_rank() -> int:
	var cards = get_children().filter(func(x) -> bool: return x is Card)
	return cards[-1].rank if not cards.is_empty() else 0
