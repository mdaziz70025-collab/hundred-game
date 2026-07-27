import 'dart:async';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

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

  // Player jab card drop/play karta hai
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

    // 1-second delay taaki natural lage ki computer soch raha hai
    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

      if (botHand.isNotEmpty) {
        setState(() {
          // Bot pehla card select karke table par dalega
          String playedCard = botHand.removeAt(0);
          tableCards.add(playedCard);

          // Turn wapas Human Player ko do
          isHumanTurn = true;
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
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20), // Classic Green Table Surface
      appBar: AppBar(
        title: const Text('100 Card Game'),
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
                            ? "Computer is thinking..."
                            : "Computer's Hand (${botHand.length})",
                        style: TextStyle(
                          color: !isHumanTurn ? Colors.yellow : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bot Cards (Face Down)
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

            // --- TABLE / DISCARD PILE AREA ---
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
                            isHumanTurn ? "Drop Card Here" : "Computer Playing...",
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
                    isHumanTurn ? "YOUR TURN (Tap a Card)" : "WAIT FOR COMPUTER",
                    style: TextStyle(
                      color: isHumanTurn ? Colors.greenAccent : Colors.white60,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Player Cards List
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

  // Card Design Widget
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
