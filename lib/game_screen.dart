import 'dart:async';
import 'package:flutter/material.dart';
import 'game_models.dart';

class GameScreen extends StatefulWidget {
  final GameMode? mode;
  final int? totalPlayers;
  final int? targetScore;
  final List<String>? playerNames; // 👈 main.dart se playerNames accept karne ke liye

  const GameScreen({
    super.key,
    this.mode,
    this.totalPlayers,
    this.targetScore,
    this.playerNames,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Game States
  List<String> playerHand = ['A♠', '10♥', 'K♦', '7♣', 'Q♠'];
  List<String> botHand = ['J♠', '9♥', '5♦', 'K♣', '8♠'];
  List<String> tableCards = [];

  bool isHumanTurn = true;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
  }

  // Player jab card play karta hai
  void _playHumanCard(String card) {
    if (!isHumanTurn || isGameOver) return;

    setState(() {
      playerHand.remove(card);
      tableCards.add(card);
      isHumanTurn = false; // Turn Computer ko do
    });

    // Computer ka Automatic Turn Trigger karein
    _triggerBotTurn();
  }

  // Computer Automatically Card Throw Karega
  void _triggerBotTurn() {
    if (isGameOver) return;

    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

      if (botHand.isNotEmpty) {
        setState(() {
          String playedCard = botHand.removeAt(0);
          tableCards.add(playedCard);
          isHumanTurn = true; // Turn wapas Player ko do
        });
      } else {
        setState(() {
          isGameOver = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentPlayers = widget.totalPlayers ?? 2;
    int target = widget.targetScore ?? 100;
    String botName = (widget.playerNames != null && widget.playerNames!.length > 1)
        ? widget.playerNames![1]
        : "Computer";

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        title: Text(
          widget.mode == GameMode.online
              ? '100 Card Game (Online - Target: $target)'
              : '100 Card Game (Offline - Target: $target)',
        ),
        backgroundColor: Colors.green[900],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- COMPUTER / BOT SECTION ---
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy,
                          color: !isHumanTurn ? Colors.yellow : Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        !isHumanTurn
                            ? "$botName is thinking..."
                            : "$botName's Hand (${botHand.length})",
                        style: TextStyle(
                          color: !isHumanTurn ? Colors.yellow : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      botHand.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 45,
                        height: 65,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.style, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- TABLE AREA ---
            Expanded(
              child: Center(
                child: Container(
                  width: 220,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHumanTurn ? Colors.greenAccent : Colors.orangeAccent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: tableCards.isEmpty
                        ? Text(
                            isHumanTurn ? "Drop Card Here" : "$botName Playing...",
                            style: const TextStyle(color: Colors.white70),
                          )
                        : _buildCardWidget(tableCards.last, isTableCard: true),
                  ),
                ),
              ),
            ),

            // --- HUMAN PLAYER SECTION ---
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    isHumanTurn ? "YOUR TURN (Tap a Card)" : "WAIT FOR $botName",
                    style: TextStyle(
                      color: isHumanTurn ? Colors.greenAccent : Colors.white60,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: playerHand.map((card) {
                        return GestureDetector(
                          onTap: () => _playHumanCard(card),
                          child: _buildCardWidget(card),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWidget(String cardText, {bool isTableCard = false}) {
    bool isRed = cardText.contains('♥') || cardText.contains('♦');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isTableCard ? 70 : 60,
      height: isTableCard ? 100 : 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          cardText,
          style: TextStyle(
            fontSize: isTableCard ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: isRed ? Colors.red : Colors.black,
          ),
        ),
      ),
    );
  }
}
