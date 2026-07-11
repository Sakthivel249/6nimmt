extends Control

@onready var stacksContainer = $MarginContainer/VBoxContainer/HBoxContainer/GameArea/PlayTable/VBoxContainer/HBoxTableContent/CenterContainerStacks/StacksGrid
@onready var playerHandContainer = $MarginContainer/VBoxContainer/HBoxContainer/GameArea/PlayTable/VBoxContainer/HandPanel/MarginContainer/VBoxContainer/CenterContainerHand/PlayerHandContainer
@onready var turnLabel = $MarginContainer/VBoxContainer/HBoxContainer/GameArea/PlayerTurnLabel
@onready var scoreboardLabel = $MarginContainer/VBoxContainer/HBoxContainer/Sidebar/MarginContainer/VBoxContainer/ScoreLabel
@onready var statusLabel = $MarginContainer/VBoxContainer/HBoxContainer/Sidebar/MarginContainer/VBoxContainer/StatusLabel
@onready var setupDialog = $SetupDialog
@onready var playerCountInput = $SetupDialog/PanelContainer/MarginContainer/VBoxContainer/HBoxHumans/LineEdit
@onready var aiCountInput = $SetupDialog/PanelContainer/MarginContainer/VBoxContainer/HBoxAI/LineEditAI
@onready var setupErrorLabel = $SetupDialog/PanelContainer/MarginContainer/VBoxContainer/SetupErrorLabel
@onready var namesContainer = $SetupDialog/PanelContainer/MarginContainer/VBoxContainer/NamesContainer
@onready var handLabel = $MarginContainer/VBoxContainer/HBoxContainer/GameArea/PlayTable/VBoxContainer/HandPanel/MarginContainer/VBoxContainer/Label
@onready var handPanel = $MarginContainer/VBoxContainer/HBoxContainer/GameArea/PlayTable/VBoxContainer/HandPanel
@onready var revealedCardsContainer = $MarginContainer/VBoxContainer/HBoxContainer/GameArea/PlayTable/VBoxContainer/HBoxTableContent/RevealedPanel/MarginContainer/VBoxContainer/ChosenCardsContainer
@onready var sidebar = $MarginContainer/VBoxContainer/HBoxContainer/Sidebar
@onready var roundLabel = $MarginContainer/VBoxContainer/HBoxContainer/Sidebar/MarginContainer/VBoxContainer/RoundLabel
@onready var revealedPanel = $MarginContainer/VBoxContainer/HBoxContainer/GameArea/PlayTable/VBoxContainer/HBoxTableContent/RevealedPanel
@onready var rowChooserDialog = $MarginContainer/VBoxContainer/HBoxContainer/GameArea/PlayTable/VBoxContainer/HBoxTableContent/RowChooserDialog
@onready var gameOverDialog = $GameOverDialog
@onready var winnerLabel = $GameOverDialog/PanelContainer/MarginContainer/VBoxContainer/WinnerLabel
@onready var finalScoresLabel = $GameOverDialog/PanelContainer/MarginContainer/VBoxContainer/FinalScoresLabel
@onready var click_player = $ClickPlayer
@onready var place_player = $PlacePlayer
@onready var bgm_player = $BGMPlayer

const INF = 999999

var CardScene = preload("res://card.tscn")
var deck: Array = []
var totalPlayers: int = 0
var playerNames: Array = []
var activePlayer: int = 1
var rows: Array[Array] = [[], [], [], []]
var selectedCards: Dictionary = {}
var scores: Array = []
var hands: Array = []

var pendingCard: int = -1
var pendingPlayer: int = -1
var waitingForRow: bool = false

var cardProcessingQueue: Array = []

var totalAI: int  = 0
var aiPlayers : Array  = []

var roundNumber : int = 1
var maxScore: int = 66

func _ready() -> void:
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.18, 0.12, 0.35, 1))
	gradient.set_color(1, Color(0.05, 0.05, 0.1, 1))
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1, 1)
	$Background.texture = tex
	
	rowChooserDialog.get_node("MarginContainer/VBoxContainer/RowsContainer/BtnRow1").connect("pressed", Callable(self, "_on_row_button_pressed").bind(0))
	rowChooserDialog.get_node("MarginContainer/VBoxContainer/RowsContainer/BtnRow2").connect("pressed", Callable(self, "_on_row_button_pressed").bind(1))
	rowChooserDialog.get_node("MarginContainer/VBoxContainer/RowsContainer/BtnRow3").connect("pressed", Callable(self, "_on_row_button_pressed").bind(2))
	rowChooserDialog.get_node("MarginContainer/VBoxContainer/RowsContainer/BtnRow4").connect("pressed", Callable(self, "_on_row_button_pressed").bind(3))
	
	stacksContainer.hide()
	handPanel.hide()
	setupDialog.show()
	rowChooserDialog.hide()
	gameOverDialog.hide()
	sidebar.hide()
	revealedPanel.hide()
	turnLabel.text = ""
	statusLabel.text = ""
	setupErrorLabel.text = ""
	
	playerCountInput.value_changed.connect(_on_human_count_changed)
	_on_human_count_changed(playerCountInput.value)

func _on_human_count_changed(value: float) -> void:
	for child in namesContainer.get_children():
		child.queue_free()
		
	var count = int(value)
	for i in range(count):
		var input = LineEdit.new()
		input.placeholder_text = "Player %d Name" % (i + 1)
		input.add_theme_font_size_override("font_size", 20)
		input.alignment = HORIZONTAL_ALIGNMENT_CENTER
		namesContainer.add_child(input)
	statusLabel.text = ""
	setupErrorLabel.text = ""

func _on_start_button_pressed() -> void:
	click_player.play()
	var numHumans = int(playerCountInput.value)
	totalAI = int(aiCountInput.value)
	
	if numHumans == 1 and totalAI == 0:
		setupErrorLabel.text = "Need at least 2 players total."
		return
	if totalAI < 0 or totalAI + numHumans > 10:
		setupErrorLabel.text = "Total players max is 10."
		return
		
	totalPlayers = numHumans + totalAI
	aiPlayers.clear()
	playerNames.clear()
	
	var name_inputs = namesContainer.get_children()
	for i in range(numHumans):
		var p_name = name_inputs[i].text.strip_edges()
		if p_name == "":
			p_name = "Player %d" % (i + 1)
		playerNames.append(p_name)
		
	for i in range(numHumans + 1, totalPlayers + 1):
		aiPlayers.append(i)
		playerNames.append("AI %d" % (i - numHumans))
		
	setupDialog.hide()
	bgm_player.stop()
	stacksContainer.show()
	handPanel.show()
	sidebar.show()
	
	start_game()

func start_game() -> void:
	roundNumber = 1
	roundLabel.text = "Round: 1"
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
	turnLabel.text = "%s: Select a card" % playerNames[activePlayer - 1]
	
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
		
		var rowContainer = HBoxContainer.new()
		stacksContainer.add_child(rowContainer)
		
		var firstCard = CardScene.instantiate()
		firstCard.initialize(number)
		firstCard.disabled = true 
		rowContainer.add_child(firstCard)

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

func process_row_choice(chosen_row_index: int, player_index: int, card_number: int) -> void: 
	var takenRow = rows[chosen_row_index]
	var bullSum = 0
	for card in takenRow:
		bullSum += bull_points(card)
	
	scores[player_index - 1] += bullSum
	rows[chosen_row_index] = [card_number]

	update_scoreboard()
	update_rows_display()
	statusLabel.append_text("[color=#ffd700][b]%s[/b][/color] took [color=#ff6666][b]Row %d[/b][/color]\n" % [playerNames[player_index - 1], chosen_row_index + 1])
	
	pendingCard = -1
	pendingPlayer = -1
	waitingForRow = false
	
func ai_choose_row() -> void:
	await get_tree().create_timer(1.0).timeout
	
	var min_bull = INF
	var chosen_row_index = 0
	
	for i in range(rows.size()):
		var bullSum = 0
		for c in rows[i]:
			bullSum += bull_points(c)
		
		if bullSum < min_bull:
			min_bull = bullSum
			chosen_row_index = i
			
	process_row_choice(chosen_row_index, pendingPlayer, pendingCard)
	
	await get_tree().create_timer(1.5).timeout
	process_cards_in_queue()
	
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

	hands[aiIndex - 1].erase(chosenCard)
	selectedCards[aiIndex] = chosenCard
	
	show_ai_chosen_card(chosenCard)
	await get_tree().create_timer(1.0).timeout

	if selectedCards.size() == totalPlayers:
		_reveal_cards()
	else:
		next_turn()

func show_ai_chosen_card(cardNumber: int) -> void:
	queue_free_children(playerHandContainer)
	var card = CardScene.instantiate()
	card.initialize(cardNumber)
	card.disabled = true
	playerHandContainer.add_child(card)

func show_hand(playerIndex: int) -> void:
	queue_free_children(playerHandContainer)
	handLabel.text = "%s's Hand" % playerNames[playerIndex - 1]
	
	if playerIndex in aiPlayers:
		ai_play(playerIndex)
		return
		
	for cardNumber in hands[playerIndex - 1]:
		var card = CardScene.instantiate()
		card.initialize(cardNumber)
		card.connect("selected", _on_card_selected)
		playerHandContainer.add_child(card)

func _on_card_selected(cardNode: TextureButton) -> void:
	# Disable all cards immediately so the player can't click twice
	for child in playerHandContainer.get_children():
		child.disabled = true
		
	click_player.play()
	var playedNumber = cardNode.card_number
	selectedCards[activePlayer] = playedNumber
	hands[activePlayer - 1].erase(playedNumber)

	highlight_selected_card(cardNode)
	await get_tree().create_timer(1.0).timeout
	cardNode.queue_free()
	
	if selectedCards.size() == totalPlayers:
		_reveal_cards()
	else:
		next_turn()

func highlight_selected_card(cardNode: TextureButton) -> void:
	var tween = get_tree().create_tween()
	cardNode.modulate = Color(1, 1, 0.5, 1)  

	tween.tween_property(cardNode, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(cardNode, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func process_cards_in_queue() -> void:
	if waitingForRow or gameOverDialog.visible:
		return
	if cardProcessingQueue.is_empty():
		queue_free_children(revealedCardsContainer)
		revealedPanel.hide()
		_process_cards() 
		return
	var cardData = cardProcessingQueue.pop_front()
	var playedNumber = cardData.card
	var playerIndex = cardData.player
	place_card(playedNumber, playerIndex)
	await get_tree().create_timer(0.5).timeout
	if not waitingForRow:
		process_cards_in_queue()

func _reveal_cards() -> void:
	revealedPanel.show()
	queue_free_children(revealedCardsContainer)
	var sortedCardsData : Array  = []
	for playerIndex in selectedCards.keys():
		sortedCardsData.append({"player":playerIndex,"card":selectedCards[playerIndex]})
	sortedCardsData.sort_custom(func (a,b): return a.card < b.card)
	cardProcessingQueue = sortedCardsData
	selectedCards.clear()
	for cardData in cardProcessingQueue:
		var card = CardScene.instantiate()
		card.initialize(cardData.card)
		card.disabled = true
		revealedCardsContainer.add_child(card)
	
	await get_tree().create_timer(1.0).timeout
	process_cards_in_queue()

func _show_card(playerIndex: int, cardNumber: int) -> void:
	var card = CardScene.instantiate()
	card.initialize(cardNumber)
	card.disabled = true
	playerHandContainer.add_child(card)   

func _process_cards() -> void:
	if gameOverDialog.visible:
		return
	turnLabel.text = "[color=#ffffff]Revealing cards...[/color]"
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
		turnLabel.text = "%s: Select a card" % playerNames[activePlayer - 1]
		
func trigger_game_over() -> void:
	var min_score = scores[0]
	var winner = 0
	for j in range(1, scores.size()):
		if scores[j] < min_score:
			min_score = scores[j]
			winner = j

	var final_scores = "[table=2]\n"
	var sortable_scores = []
	for p in range(totalPlayers):
		sortable_scores.append({"name": playerNames[p], "score": scores[p]})
		
	sortable_scores.sort_custom(func(a, b): return a.score < b.score)
	
	for p in range(totalPlayers):
		var medal = ""
		var color = "#cccccc"
		if p == 0:
			medal = "🥇 "
			color = "#ffd700"
		elif p == 1:
			medal = "🥈 "
			color = "#c0c0c0"
		elif p == 2:
			medal = "🥉 "
			color = "#cd7f32"
		
		final_scores += "[cell][color=%s]%s%s  [/color][/cell][cell][color=%s]%d[/color][/cell]\n" % [color, medal, sortable_scores[p].name, color, sortable_scores[p].score]
	
	final_scores += "[/table]"

	turnLabel.text = ""
	winnerLabel.text = "%s wins the game with %d points!" % [playerNames[winner], min_score]
	finalScoresLabel.text = final_scores
	
	handPanel.hide()
	stacksContainer.hide()
	sidebar.hide()
	revealedPanel.hide()
	rowChooserDialog.hide()
	cardProcessingQueue.clear()
	gameOverDialog.show()

func end_round() -> void:
	var game_over = false
	for i in range(totalPlayers):
		if scores[i] >= maxScore:
			game_over = true
			break
			
	if roundNumber >= 10:
		game_over = true

	if game_over:
		trigger_game_over()
		return

	roundNumber += 1
	roundLabel.text = "Round: %d" % roundNumber
	turnLabel.text = " Starting Round %d " % roundNumber
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
	activePlayer = 1
	show_hand(activePlayer)
	turnLabel.text = "%s: Select a card" % playerNames[activePlayer - 1]
	update_scoreboard()


func get_card_owner(cardNumber: int) -> int:
	for key in selectedCards.keys():
		if selectedCards[key] == cardNumber:
			return key
	return 1 
	
func place_card(playedNumber: int, playerIndex: int) -> void:
	place_player.play()
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

		if playerIndex in aiPlayers:
			ai_choose_row()
		else:
			turnLabel.text = "%s must choose a row" % playerNames[playerIndex - 1]
			statusLabel.append_text("[color=#888888]Waiting for %s...[/color]\n" % playerNames[playerIndex - 1])
			revealedPanel.hide()
			rowChooserDialog.show()
	else:
		place_card_in_row(playedNumber, playerIndex, bestRowIndex)

func _on_row_button_pressed(chosen_row_index: int) -> void:
	click_player.play()
	rowChooserDialog.hide()
	if not cardProcessingQueue.is_empty():
		revealedPanel.show()
	process_row_choice(chosen_row_index, pendingPlayer, pendingCard)
	process_cards_in_queue()

func place_card_in_row(playedNumber: int, playerIndex: int, rowIndex: int) -> void:
	var takenRow: Array = []
	if rows[rowIndex].size() >= 5:
		for i in range(5):
			takenRow.append(rows[rowIndex][i])
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
	scoreboardLabel.text = "[center][b][color=#ffd700]Leaderboard[/color][/b][/center]\n\n"
	
	var best_score = INF
	var game_over_triggered = false
	for score in scores:
		if score < best_score:
			best_score = score
		if score >= maxScore:
			game_over_triggered = true
			
	if roundNumber > 10:
		game_over_triggered = true
			
	for i in range(totalPlayers):
		var player_name = playerNames[i]
		
		if scores[i] == best_score:
			scoreboardLabel.text += "[color=#ffd700]★ %s: %d[/color]\n" % [player_name, scores[i]]
		else:
			scoreboardLabel.text += "[color=#8eb3d4]%s: %d[/color]\n" % [player_name, scores[i]]

	if game_over_triggered and not gameOverDialog.visible:
		trigger_game_over()

func update_rows_display() -> void:
	for child in stacksContainer.get_children():
		child.queue_free()

	# Create a StyleBox for the row tracks programmatically
	var track_style = StyleBoxFlat.new()
	track_style.bg_color = Color(0.08, 0.08, 0.15, 0.8)
	track_style.border_width_bottom = 4
	track_style.border_width_top = 2
	track_style.border_width_left = 2
	track_style.border_width_right = 2
	track_style.border_color = Color(0.3, 0.2, 0.5, 0.8)
	track_style.corner_radius_top_left = 15
	track_style.corner_radius_top_right = 15
	track_style.corner_radius_bottom_left = 15
	track_style.corner_radius_bottom_right = 15
	track_style.content_margin_left = 20
	track_style.content_margin_right = 20
	track_style.content_margin_top = 10
	track_style.content_margin_bottom = 10

	for i in range(rows.size()):
		var track = PanelContainer.new()
		track.add_theme_stylebox_override("panel", track_style)
		stacksContainer.add_child(track)
		
		var rowContainer = HBoxContainer.new()
		rowContainer.add_theme_constant_override("separation", 15)
		track.add_child(rowContainer)
		
		# Add beautiful ROW label
		var rowLabel = Label.new()
		rowLabel.text = "ROW %d" % (i + 1)
		rowLabel.add_theme_font_size_override("font_size", 24)
		rowLabel.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 0.8)) # Gold but slightly transparent
		rowLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rowLabel.custom_minimum_size = Vector2(100, 0)
		rowContainer.add_child(rowLabel)
		
		for cardNumber in rows[i]:
			var card = CardScene.instantiate()
			card.initialize(cardNumber)
			card.disabled = true
			rowContainer.add_child(card)

func next_turn() -> void:
	activePlayer += 1
	if activePlayer > totalPlayers:
		activePlayer = 1
	
	show_hand(activePlayer)
	turnLabel.text = "%s: Select a card" % playerNames[activePlayer - 1]

func queue_free_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func _on_exit_button_pressed():
	click_player.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://StartScreen.tscn")

func _on_play_again_pressed():
	click_player.play()
	bgm_player.play()
	gameOverDialog.hide()
	setupDialog.show()
	sidebar.hide()
	revealedPanel.hide()
	rowChooserDialog.hide()
	turnLabel.text = ""
	statusLabel.text = ""
	setupErrorLabel.text = ""
