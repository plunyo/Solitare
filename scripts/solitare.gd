extends Control

const MAX_DECK_OFFSET: Vector2 = Vector2(3, 3)
@export var card_scene: PackedScene

@onready var drag_layer: Control = $DragLayer
@onready var stock_container: HBoxContainer = $VSplitContainer/MarginContainer/StockContainer
@onready var deck: CenterContainer = $VSplitContainer/MarginContainer/StockContainer/Deck

@onready var rows: Array[VBoxContainer] = [
	$VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row1, $VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row2,
	$VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row3, $VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row4,
	$VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row5, $VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row6,
	$VSplitContainer/HSplitContainer/MarginContainer/HBoxContainer/Row7
]
@onready var foundations: Array[Foundation] = [
	$VSplitContainer/HSplitContainer/CenterContainer/VBoxContainer/RedSuitFoundations/HeartFoundation,
	$VSplitContainer/HSplitContainer/CenterContainer/VBoxContainer/RedSuitFoundations/DiamondFoundation,
	$VSplitContainer/HSplitContainer/CenterContainer/VBoxContainer/BlackSuitFoundations/SpadeFoundation,
	$VSplitContainer/HSplitContainer/CenterContainer/VBoxContainer/BlackSuitFoundations/ClubFoundation
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

func get_foundation_under_mouse() -> Foundation:
	for foundation: Foundation in foundations:
		if foundation.is_mouse_over:
			return foundation

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

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released() \
	and deck.get_global_rect().has_point(get_global_mouse_position()):
		
		var max_stock := 10

		# if deck has cards and waste isn't full
		if deck.get_child_count() > 0 and stock_container.get_child_count() < max_stock:
			var card := deck.get_child(0) as Card
			deck.remove_child(card)
			stock_container.add_child(card)
			if card.face_down:
				card.flip()

		# if stock is full, take all waste back into deck
		elif stock_container.get_child_count() >= max_stock:
			await recycle_waste()

func recycle_waste() -> void:
	var waste := stock_container.get_children().filter(func(x) -> bool: return x is Card)
	for i in range(waste.size() - 1, -1, -1):
		var c := waste[i] as Card
		if not c.face_down:
			c.flip()

		# get global position before removing
		var start_pos = c.global_position
		var end_pos = deck.global_position
		
		# temporarily keep it in the scene so tween works
		c.reparent(get_tree().current_scene)
		c.global_position = start_pos

		var move_tween = get_tree().create_tween()
		move_tween.tween_property(c, "global_position", end_pos, 0.1)
		await move_tween.finished

		# now reparent to deck after tween
		c.reparent(deck)
	
	shuffle()



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
