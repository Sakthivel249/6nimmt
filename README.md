# 6 Nimmt! (Take 6!) - Godot Implementation

A digital implementation of the classic card game **6 Nimmt!** (also known as Take 6!), built using the Godot Engine. 


## Table of Contents
- [About the Game](#about-the-game)
- [How to Play (Rules)](#how-to-play-rules)
- [Features](#features)
- [Tech Stack & Modules](#tech-stack--modules)
- [Project Structure](#project-structure)
- [Installation & Setup](#installation--setup)

## About the Game
6 Nimmt! is a strategic card game where players aim to avoid scoring points. The game consists of 104 cards, numbered 1 to 104. Each card has a penalty value (bullheads). The objective is to finish the game with the fewest bullheads possible.

## How to Play (Rules)

### Setup
- The deck has 104 cards (numbered 1 to 104).
- 4 cards are dealt face-up on the table to form the starting cards of 4 rows.
- Each player is dealt 10 cards to form their hand.

### Gameplay
1. **Choose a Card:** Each round, all players secretly and simultaneously choose one card from their hand to play.
2. **Reveal Cards:** All chosen cards are revealed at the same time.
3. **Place Cards:** Cards are placed into the 4 rows on the table in ascending order of their face value. The lowest card is placed first, followed by the next lowest, and so on.
   - A card must always be placed in the row that ends with the highest number that is lower than the played card's number.
   - *Example: If the rows end in 12, 37, 43, and 58, and you play a 48, it must go in the row ending in 43.*
4. **Taking a Row (The "6 Nimmt" Rule):**
   - If a row already has 5 cards, and a player's card must be placed in that row as the 6th card, that player must take the 5 cards currently in the row (scoring their bullheads) and their played card becomes the new first card of that row.
   - **Too Low to Play:** If a player's chosen card is lower than all the ending cards of the 4 rows, they cannot place it legally. Instead, they must choose any one of the 4 rows to take (scoring its bullheads), and their played card becomes the new first card of that row.

### Scoring
- Cards have "bullheads" which count as penalty points:
  - **Most cards:** 1 bullhead
  - **Cards ending in 5:** 2 bullheads
  - **Cards ending in 0 (multiples of 10):** 3 bullheads
  - **Double digits (11, 22, 33, etc.):** 5 bullheads
  - **Card 55:** 7 bullheads!
- The game ends when a player hits 66 points (or after 10 rounds). The player with the fewest points wins!

## Features
- **Local Multiplayer:** Play with human players locally.
- **AI Opponents:** Configurable AI players to play against, utilizing algorithmic decision making (Minimax/Greedy strategies).
- **Automated Game Logic:** The game handles all sorting, placing, and scoring automatically.
- **Dynamic UI:** Smooth animations, turn announcements, and card highlighting.
- **Audio:** Integrated background music and sound effects for card placement and button clicks.

## Tech Stack & Modules

- **Game Engine:** [Godot Engine 4.x](https://godotengine.org/)
- **Language:** GDScript (Godot's Python-like native scripting language)
- **UI System:** Godot Control Nodes (VBoxContainer, HBoxContainer, PanelContainer)
- **Architecture Modules:**
  - `scripts/main.gd`: Core game loop, state management, scoring, and AI logic.
  - `scripts/start_screen.gd`: Main menu navigation and transitions.
  - `scripts/card.gd`: Individual card logic and visual representation.

## Project Structure

The project has been carefully organized for clarity and scalability:

```text
6nimmt/
├── assets/             # Game assets (media)
│   ├── audio/          # Background music & sound effects (.wav)
│   ├── graphics/       # UI graphics and backgrounds (.png, .svg)
│   └── cards/          # The 104 individual card textures
├── scenes/             # Godot Scene files (.tscn)
│   ├── MainScene.tscn  # The core gameplay scene
│   ├── StartScreen.tscn# The main menu scene
│   └── card.tscn       # The reusable card prefab
├── scripts/            # GDScript logic files (.gd)
│   ├── main.gd         
│   ├── start_screen.gd 
│   └── card.gd         
├── resources/          # Reusable Godot resources (.tres)
│   ├── ui_theme.tres   # Global UI styling
│   └── default_bus_layout.tres
└── docs/               # Documentation & rules
```

