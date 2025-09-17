extends Node

# --- Node References ---
@onready var stacks_grid = $StacksGrid
@onready var player_hand_container = $PlayerHandContainer
@onready var player_turn_label = $UILayer/PlayerTurnLabel
@onready var score_label = $UILayer/ScoreLabel
@onready var input_label = $Label
@onready var num_players_input = $LineEdit
@onready var start_button = $start_button
@onready var chosen_cards_container = $UILayer/ChosenCardsContainer

# --- Game Variables ---
var CardScene = preload("res://card.tscn")
var deck: Array = []
var num_players: int = 0
var current_player: int = 1   # Tracks which player’s turn it is
var stacks: Array[Array] = [[], [], [], []]
var chosen_cards: Dictionary = {}
var player_scores: Array = []


# Each player’s hand (array of arrays, index 0 → Player 1, etc.)
var player_hands: Array = []


# --- Engine Functions ---
func _ready() -> void:
	# Hide the game elements until the game starts
	stacks_grid.hide()
	player_hand_container.hide()
	$UILayer.hide()
	
	# Set up the input field
	num_players_input.placeholder_text = "Enter players (2-10)"


# --- UI Signal Functions ---
func _on_start_button_pressed() -> void:
	var input_text = num_players_input.text
	
	# Input Validation
	if not input_text.is_valid_int():
		input_label.text = "Invalid! Please enter a number."
		return
		
	num_players = input_text.to_int()
	
	if num_players < 2 or num_players > 10:
		input_label.text = "Players must be between 2 and 10."
		return
	
	# Hide Input UI & Show Game UI
	input_label.hide()
	num_players_input.hide()
	start_button.hide()
	
	stacks_grid.show()
	player_hand_container.show()
	$UILayer.show()
	
	# If validation is successful, start the game!
	start_game()


# --- Game Logic Functions ---
func start_game() -> void:
	print("Starting game with %d players!" % num_players)
	
	# Initialize player scores
	player_scores.clear()
	for i in range(num_players):
		player_scores.append(0)
	
	# Build and shuffle the deck
	deck = []
	for i in range(1, 105):
		deck.append(i)
	deck.shuffle()

	setup_stacks()
	deal_cards()
	
	current_player = 1
	show_player_hand(current_player)
	player_turn_label.text = "Player %d: Select a card" % current_player
	
	update_scoreboard()
	
func calculate_bull_points(card_number: int) -> int:
	if card_number == 55:
		return 7
	elif card_number % 11 == 0:
		return 5
	elif card_number % 10 == 0:
		return 3
	elif card_number % 5 == 0:
		return 2
	else:
		return 1


func setup_stacks() -> void:
	# Clear any previous stack data and visuals
	stacks = [[], [], [], []]
	for child in stacks_grid.get_children():
		child.queue_free()
		
	# Draw 4 cards from the deck for the stacks
	for i in range(4):
		var number = deck.pop_front()
		stacks[i].append(number)
		
		var first_card = CardScene.instantiate()
		first_card.initialize(number)
		first_card.disabled = true # Stack cards aren't clickable
		stacks_grid.add_child(first_card)


# NEW: Deal unique cards to each player
func deal_cards() -> void:
	player_hands.clear()
	for p in range(num_players):
		var hand: Array = []
		for i in range(10):
			hand.append(deck.pop_front())
		player_hands.append(hand)


# NEW: Show the current player’s hand
func show_player_hand(player_index: int) -> void:
	# FIX: call utility properly
	queue_free_children(player_hand_container)
	
	for card_number in player_hands[player_index - 1]:
		var card = CardScene.instantiate()
		card.initialize(card_number)
		card.connect("selected", _on_card_selected)
		player_hand_container.add_child(card)



func _on_card_selected(card_node: TextureButton) -> void:
	var played_number = card_node.card_number
	print("Player %d selected card %d" % [current_player, played_number])
	
	# Store choice
	chosen_cards[current_player] = played_number
	
	# Remove visually from hand
	player_hands[current_player - 1].erase(played_number)
	card_node.queue_free()
	
	# Next player's turn
	next_turn()
	
	# If all players have chosen, reveal cards
	if chosen_cards.size() == num_players:
		_reveal_chosen_cards()

func _reveal_chosen_cards() -> void:
	queue_free_children(chosen_cards_container)
	
	# Sort the chosen card numbers in ascending order
	var sorted_numbers = chosen_cards.values()
	sorted_numbers.sort()
	
	# Display sorted chosen cards
	for number in sorted_numbers:
		var card = CardScene.instantiate()
		card.initialize(number)
		card.disabled = true
		chosen_cards_container.add_child(card)
	
	player_turn_label.text = "All cards revealed! Processing..."
	
	# Add a short delay before placing
	await get_tree().create_timer(1.5).timeout
	_process_chosen_cards()


func _show_chosen_card(player_index: int, card_number: int) -> void:
	var card = CardScene.instantiate()
	card.initialize(card_number)
	card.disabled = true
	card.modulate = Color(0.8, 0.8, 0.8, 0.6)  # faded look
	player_hand_container.add_child(card)  # TODO: ideally put in a separate container per player

func _process_chosen_cards() -> void:
	player_turn_label.text = "Revealing cards..."

	# Sort by card number
	var ordered = chosen_cards.values()
	ordered.sort()

	for played_number in ordered:
		var player_index = get_player_who_played_card(played_number)
		_place_card(played_number, player_index)

	# Clear chosen cards for next round
	chosen_cards.clear()

	# Start next round with player 1
	current_player = 1
	show_player_hand(current_player)
	player_turn_label.text = "Player %d: Select a card" % current_player

func get_player_who_played_card(card_number: int) -> int:
	for key in chosen_cards.keys():
		if chosen_cards[key] == card_number:
			return key
	return 1  # Fallback


func _place_card(played_number: int, player_index: int) -> void:
	var best_row_index: int = -1
	var smallest_diff: int = 999
	for i in range(stacks.size()):
		var last_card_in_row = stacks[i][-1]
		var diff = played_number - last_card_in_row
		if diff > 0 and diff < smallest_diff:
			smallest_diff = diff
			best_row_index = i

	if best_row_index == -1:
		var chosen_row_index = _choose_row_for_player(player_index)
		var taken_row = stacks[chosen_row_index]
		print("Player %d takes row %d: %s" % [player_index, chosen_row_index + 1, str(taken_row)])
		stacks[chosen_row_index] = [played_number]
		var bull_points = 0
		for card in taken_row:
			bull_points += calculate_bull_points(card)
			player_scores[player_index - 1] += bull_points
		update_scoreboard()
	else:
		stacks[best_row_index].append(played_number)

		if stacks[best_row_index].size() > 5:
			var taken_row: Array = []
			for i in range(5):
				taken_row.append(stacks[best_row_index][i])

			print("Player %d triggered '6 Nimmt!' and takes row %d: %s" % [player_index, best_row_index + 1, str(taken_row)])

			var bull_points = 0
			for card in taken_row:
				bull_points += calculate_bull_points(card)

			player_scores[player_index - 1] += bull_points
			update_scoreboard()

			stacks[best_row_index] = [played_number]

	update_stacks_display()


func update_scoreboard() -> void:
	score_label.text = "Scores:\n"
	for i in range(num_players):
		score_label.text += "Player %d: %d\n" % [i + 1, player_scores[i]]



func _choose_row_for_player(player_index: int) -> int:
	# Simple logic: pick the row with the smallest last card
	var min_value = 999
	var chosen_index = 0
	for i in range(stacks.size()):
		if stacks[i][-1] < min_value:
			min_value = stacks[i][-1]
			chosen_index = i
	return chosen_index


func update_stacks_display() -> void:
	for child in stacks_grid.get_children():
		child.queue_free()

	for row in stacks:
		var row_container = HBoxContainer.new()
		stacks_grid.add_child(row_container)
		
		for card_number in row:
			var card = CardScene.instantiate()
			card.initialize(card_number)
			card.disabled = true
			row_container.add_child(card)


func next_turn() -> void:
	current_player += 1
	if current_player > num_players:
		current_player = 1
	
	show_player_hand(current_player)
	player_turn_label.text = "Player %d: Select a card" % current_player


# --- Utility ---
func queue_free_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
