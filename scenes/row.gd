class_name Row
extends VBoxContainer

var is_mouse_over: bool

func _input(_event: InputEvent) -> void:
	is_mouse_over = get_global_rect().has_point(get_global_mouse_position())

func get_sequence_from_card(card: Card) -> Array:
	var row = card.pile_ref
	if not row:
		return []

	var cards: Array = row.get_children().filter(func(x) -> bool: return x is Card)
	var start_index = cards.find(card)

	if start_index == -1:
		return []

	return cards.slice(start_index, cards.size())


func move_sequence_to(drag_sequence: Array, dest_pile: Row) -> void:
	for card: Card in drag_sequence:
		remove_child(card)
		dest_pile.add_child(card)

	var cards: Array = get_children()
	if cards.is_empty(): return

	var last_card: Node = cards[-1]
	if last_card and last_card is Card and last_card.face_down:
		last_card.flip()

func can_accept_sequence(sequence: Array) -> bool:
	var cards: Array = get_children().filter(func(x) -> bool: return x is Card)
	if sequence.is_empty():
		return false

	var first_seq_card: Card = sequence[0]

	if cards.is_empty():
		return first_seq_card.rank == 13

	var last_card: Card = cards[-1] as Card

	var color_ok = (last_card.is_red() and not first_seq_card.is_red()) or \
				   (not last_card.is_red() and first_seq_card.is_red())

	var rank_ok = last_card.rank == first_seq_card.rank + 1

	return color_ok and rank_ok

func return_sequence(sequence: Array) -> void:
	for card: Card in sequence:
		#idgaf it works bro ending it
		remove_child(card)
		add_child(card)
		card.pile_ref = self
