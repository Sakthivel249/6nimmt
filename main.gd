extends Node

@onready var stacksContainer = $StacksGrid
@onready var playerHandContainer = $PlayerHandContainer
@onready var turnLabel = $UILayer/PlayerTurnLabel
@onready var scoreboardLabel = $UILayer/ScoreLabel
@onready var statusLabel = $Label
@onready var playerCountInput = $LineEdit
@onready var startButton = $start_button
@onready var revealedCardsContainer = $UILayer/ChosenCardsContainer
@onready var revealLabel = $RevealLabel
@onready var stackLabel = $StackLabel
@onready var aiCountInput = $LineEditAI
@onready var aiLabel = $LabelAI

const INF = 999999

var CardScene = preload("res://card.tscn")
var deck: Array = []
var totalPlayers: int = 0
var activePlayer: int = 1
var rows: Array[Array] = [[], [], [], []]
var selectedCards: Dictionary = {}
var scores: Array = []
var hands: Array = []

var pendingCard: int = -1
var pendingPlayer: int = -1
var waitingForRow: bool = false

var totalAI: int  = 0
var aiPlayers : Array  = []


var roundNumber : int = 1
var maxScore: int = 66
func _ready() -> void:
	stacksContainer.hide()
	stackLabel.hide()
	revealLabel.hide()
	playerHandContainer.hide()
	$UILayer.hide()
	playerCountInput.placeholder_text = "Enter players (2-10)"

func _on_start_button_pressed() -> void:
	if waitingForRow:
		var inputText = playerCountInput.text
		if not inputText.is_valid_int():
			statusLabel.text = "Invalid! Enter row (1-4)."
			return
		var chosenRow = inputText.to_int() - 1
		if chosenRow < 0 or chosenRow > 3:
			statusLabel.text = "Row must be between 1 and 4."
			return
		
		var takenRow = rows[chosenRow]
		print("Player %d chose row %d: %s" % [pendingPlayer, chosenRow + 1, str(takenRow)])
		var bullSum = 0
		for card in takenRow:
			bullSum += bull_points(card)
		scores[pendingPlayer - 1] += bullSum
		rows[chosenRow] = [pendingCard]

		update_scoreboard()
		update_rows_display()

		turnLabel.text = "Player %d took row %d and placed card %d" % [pendingPlayer, chosenRow + 1, pendingCard]

		pendingCard = -1
		pendingPlayer = -1
		waitingForRow = false
		playerCountInput.hide()
		startButton.hide()
	else:
		var humanText= playerCountInput.text
		if not humanText.is_valid_int():
			statusLabel.text = "Invalid ! Enter number of human players"
			return
		var numHumans = humanText.to_int();
		if numHumans <1 or numHumans > 10:
			statusLabel.text = "Players must be between 1 and 10"
			return
		var aiText = aiCountInput.text
		if aiText =="":
			totalAI = 0
		elif not aiText.is_valid_int():
			statusLabel.text = "Invalid Enter number of AI players"
			return
		else :
			totalAI =aiText.to_int()
		if(numHumans == 1 and totalAI==0):
			statusLabel.text = "Invalid"
			return 
		if(totalAI<0 or totalAI + numHumans >10):
			statusLabel.text = "AI count must be between 0 and %d"%(10 - numHumans)
			return
		totalPlayers = numHumans + totalAI
		aiPlayers.clear()
		for i in range(numHumans + 1, totalPlayers + 1):
			aiPlayers.append(i)
		statusLabel.hide()
		playerCountInput.hide()
		aiCountInput.hide()
		startButton.hide()
		
		stacksContainer.show()
		playerHandContainer.show()
		stackLabel.show()
		revealLabel.show()
		$UILayer.show()
		
		start_game()
func start_game() -> void:
	print("Starting game with %d players" % totalPlayers)
	scores.clear()
	for i in range(totalPlayers):
		scores.append(0)
	
	deck = []
	for i in range(1, 105):
		deck.append(i)
	deck.shuffle()

	setup_rows()
	deal_cards()
	
	activePlayer = 1
	show_hand(activePlayer)
	turnLabel.text = "Player %d: Select a card" % activePlayer
	
	update_scoreboard()

func bull_points(cardNumber: int) -> int:
	if cardNumber == 55:
		return 7
	elif cardNumber % 11 == 0:
		return 5
	elif cardNumber % 10 == 0:
		return 3
	elif cardNumber % 5 == 0:
		return 2
	else:
		return 1

func setup_rows() -> void:
	rows = [[], [], [], []]
	for child in stacksContainer.get_children():
		child.queue_free()
		
	for i in range(4):
		var number = deck.pop_front()
		rows[i].append(number)
		
		var firstCard = CardScene.instantiate()
		firstCard.initialize(number)
		firstCard.disabled = true 
		stacksContainer.add_child(firstCard)

func deal_cards() -> void:
	hands.clear()
	for p in range(totalPlayers):
		var hand: Array = []
		for i in range(10):
			hand.append(deck.pop_front())
		hands.append(hand)

func evaluate_state(state: Dictionary)->int : 
	return state.scores[1]-state.scores[0]
func hands_empty(state: Dictionary)->bool:
	for h in state.hands:
		if h.size() > 0:
			return false
	return true
	
func simulate_state(state: Dictionary, player_index: int, card: int) -> Dictionary:
	var new_state = {
		"hands": [state.hands[0].duplicate(), state.hands[1].duplicate()],
		"scores": [state.scores[0], state.scores[1]],
		"rows": []
	}
	for r in state.rows:
		new_state.rows.append(r.duplicate())

	new_state.hands[player_index].erase(card)

	var best_row = -1
	var smallest_diff = INF

	for i in range(new_state.rows.size()):
		var diff = card - new_state.rows[i][-1]
		if diff > 0 and diff < smallest_diff:
			smallest_diff = diff
			best_row = i

	if best_row == -1:
		var min_bull = INF
		var chosen_row = 0
		for i in range(new_state.rows.size()):
			var bullSum = 0
			for c in new_state.rows[i]:
				bullSum += bull_points(c)
			if bullSum < min_bull:
				min_bull = bullSum
				chosen_row = i
		new_state.scores[player_index] += min_bull
		new_state.rows[chosen_row] = [card]
	else:
		if new_state.rows[best_row].size() >= 5:
			var bullSum = 0
			for c in new_state.rows[best_row]:
				bullSum += bull_points(c)
			new_state.scores[player_index] += bullSum
			new_state.rows[best_row] = [card]
		else:
			new_state.rows[best_row].append(card)

	return new_state

	
		
	
func minimax(state : Dictionary , depth : int , maximizing_player: bool,alpha:int , beta: int)-> Array:
	if depth ==0 or hands_empty(state):
		return [evaluate_state(state),-1]
	if maximizing_player:
		var maxeval = -INF
		var bestcard = -1
		for card in state.hands[0]:
			var child = simulate_state(state, 0, card)
			var eval = minimax(child, depth-1,false,alpha,beta)[0]
			if eval > maxeval:
				maxeval = eval
				bestcard = card
			alpha = max(alpha,eval)
			if beta <= alpha: 
				break
		return [maxeval,bestcard]
	else : 
		var mineval = INF
		var bestcard = -1
		for card in state.hands[1]:
			var child = simulate_state(state, 1, card)
			var eval = minimax(child ,depth-1, true,alpha,beta)[0]
			if eval< mineval:
				mineval = eval
				bestcard  = card
			beta = min(beta, eval)
			if beta <= alpha : 
				break
		return [mineval,bestcard]
		
func ai_play(aiIndex: int) -> void:
	var chosenCard: int
	
	if totalPlayers == 2 and totalAI == 1:
		var state = {
			"hands": [hands[0].duplicate(), hands[1].duplicate()],
			"scores": [scores[0], scores[1]],
			"rows": []
		}
		for r in rows:
			state.rows.append(r.duplicate())
		var result = minimax(state, 2, false, -INF, INF)
		chosenCard = result[1]

		if chosenCard == -1:
			chosenCard = hands[aiIndex - 1][0]

		print("Minimax AI Player %d selected card %d" % [aiIndex, chosenCard])
	

	else:
		var hand = hands[aiIndex - 1]
		chosenCard = hand[0]
		var minRisk = INF
		var bestCard = chosenCard
		var safeFound = false

		for card in hand:
			var rowDiffs: Array = []
			for row in rows:
				rowDiffs.append(card - row[-1])
			rowDiffs.sort()

			if rowDiffs[0] > 0 and rowDiffs[0] < minRisk:
				minRisk = rowDiffs[0]
				bestCard = card
				safeFound = true

		if not safeFound:
			var minBull = INF
			var fallbackCard = hand[0]

			for card in hand:
				var possibleRow = -1
				var minPositive = INF

				for i in range(rows.size()):
					var diff = card - rows[i][-1]
					if diff > 0 and diff < minPositive:
						minPositive = diff
						possibleRow = i

				if possibleRow == -1:
					var bestRow = -1
					var bestBull = INF
					for j in range(rows.size()):
						var bullSum = 0
						for c in rows[j]:
							bullSum += bull_points(c)
						if bullSum < bestBull:
							bestBull = bullSum
							bestRow = j

					if bestBull < minBull:
						minBull = bestBull
						fallbackCard = card
				else:
					fallbackCard = card

			bestCard = fallbackCard

		chosenCard = bestCard
		print("Greedy AI Player %d selected card %d" % [aiIndex, chosenCard])

	hands[aiIndex - 1].erase(chosenCard)
	selectedCards[aiIndex] = chosenCard

	next_turn()

	if selectedCards.size() == totalPlayers:
		_reveal_cards()


		
		
func show_hand(playerIndex: int) -> void:
	queue_free_children(playerHandContainer)
	
	if playerIndex in aiPlayers:
		ai_play(playerIndex)
		return
		
	for cardNumber in hands[playerIndex - 1]:
		var card = CardScene.instantiate()
		card.initialize(cardNumber)
		card.connect("selected", _on_card_selected)
		playerHandContainer.add_child(card)

func _on_card_selected(cardNode: TextureButton) -> void:
	var playedNumber = cardNode.card_number
	print("Player %d selected card %d" % [activePlayer, playedNumber])
	selectedCards[activePlayer] = playedNumber
	
	hands[activePlayer - 1].erase(playedNumber)
	cardNode.queue_free()
	next_turn()
	
	if selectedCards.size() == totalPlayers:
		_reveal_cards()

func _reveal_cards() -> void:
	queue_free_children(revealedCardsContainer)
	var sortedNumbers = selectedCards.values()
	sortedNumbers.sort()
	for number in sortedNumbers:
		var card = CardScene.instantiate()
		card.initialize(number)
		card.disabled = true
		revealedCardsContainer.add_child(card)
	
	turnLabel.text = "All cards revealed! Processing..."
	await get_tree().create_timer(1.5).timeout
	_process_cards()

func _show_card(playerIndex: int, cardNumber: int) -> void:
	var card = CardScene.instantiate()
	card.initialize(cardNumber)
	card.disabled = true
	card.modulate = Color(0.8, 0.8, 0.8, 0.6)  
	playerHandContainer.add_child(card)   

func _process_cards() -> void:
	turnLabel.text = "Revealing cards..."
	var ordered = selectedCards.values()
	ordered.sort()

	for playedNumber in ordered:
		var playerIndex = get_card_owner(playedNumber)
		place_card(playedNumber, playerIndex)
	selectedCards.clear()
	var handsEmpty = true
	for hand in hands:
		if hand.size() >0:
			handsEmpty = false
			break
	if handsEmpty:
		end_round()
	else:
		activePlayer = 1
		show_hand(activePlayer)
		turnLabel.text = "Player %d: Select a card" % activePlayer
func end_round() -> void:
	var game_over = false
	for i in range(totalPlayers):
		if scores[i] >= maxScore:
			game_over = true
			break

	if game_over:
		var min_score = scores[0]
		var winner = 0
		for j in range(1, scores.size()):
			if scores[j] < min_score:
				min_score = scores[j]
				winner = j

		var final_scores = "Final Scores:\n"
		for p in range(totalPlayers):
			final_scores += "Player %d: %d\n" % [p + 1, scores[p]]

		turnLabel.text = " Player %d wins the game with %d points!" % [winner + 1, min_score]
		statusLabel.text = final_scores + "\nGame Over"
		playerHandContainer.hide()
		stacksContainer.hide()
		return

	roundNumber += 1
	turnLabel.text = " Starting Round %d..." % roundNumber
	statusLabel.text = ""
	await get_tree().create_timer(2).timeout
	start_new_round()

func start_new_round() -> void:
	deck.clear()
	for i in range(1,105):
		deck.append(i)
	deck.shuffle()
	setup_rows()
	deal_cards()
	activePlayer=1
	show_hand(activePlayer)
	turnLabel.text = "Player %d: Select a card" % activePlayer
	update_scoreboard()


func get_card_owner(cardNumber: int) -> int:
	for key in selectedCards.keys():
		if selectedCards[key] == cardNumber:
			return key
	return 1 
	
func place_card(playedNumber: int, playerIndex: int) -> void:
	var bestRowIndex: int = -1
	var smallestDiff: int = 999
	for i in range(rows.size()):
		var lastCard = rows[i][-1]
		var diff = playedNumber - lastCard
		if diff > 0 and diff < smallestDiff:
			smallestDiff = diff
			bestRowIndex = i

	if bestRowIndex == -1:
		pendingCard = playedNumber
		pendingPlayer = playerIndex
		waitingForRow = true

		turnLabel.text = "Player %d must choose a row (1-4) " % playerIndex
		statusLabel.text = "Enter the row number (1-4)  "
		
		playerCountInput.show()
		playerCountInput.placeholder_text = "Row (1-4)"
		playerCountInput.text = ""
		startButton.text = "Confirm Row"
		startButton.show()
	else:
		place_card_in_row(playedNumber, playerIndex, bestRowIndex)

func place_card_in_row(playedNumber: int, playerIndex: int, rowIndex: int) -> void:
	var takenRow: Array = []
	if rows[rowIndex].size() >= 5:
		for i in range(5):
			takenRow.append(rows[rowIndex][i])
		print("Player %d triggered '6 Nimmt!' and takes row %d: %s" % [playerIndex, rowIndex + 1, str(takenRow)])
		var bullSum = 0
		for card in takenRow:
			bullSum += bull_points(card)
		scores[playerIndex - 1] += bullSum
		rows[rowIndex] = [playedNumber]
	else:
		rows[rowIndex].append(playedNumber)

	update_scoreboard()
	update_rows_display()

func update_scoreboard() -> void:
	scoreboardLabel.text = "Scores:\n"
	for i in range(totalPlayers):
		scoreboardLabel.text += "Player %d: %d\n" % [i + 1, scores[i]]

func update_rows_display() -> void:
	for child in stacksContainer.get_children():
		child.queue_free()

	for row in rows:
		var rowContainer = HBoxContainer.new()
		stacksContainer.add_child(rowContainer)
		
		for cardNumber in row:
			var card = CardScene.instantiate()
			card.initialize(cardNumber)
			card.disabled = true
			rowContainer.add_child(card)

func next_turn() -> void:
	activePlayer += 1
	if activePlayer > totalPlayers:
		activePlayer = 1
	
	show_hand(activePlayer)
	turnLabel.text = "Player %d: Select a card" % activePlayer

func queue_free_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
