import 'package:flutter/material.dart';
import 'game_models.dart';
import 'game_logic.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final int totalPlayers;
  final int targetScore;
  final List<String> playerNames;
  final String? roomCode;

  GameScreen({
    Key? key,
    required this.mode,
    required this.totalPlayers,
    required this.targetScore,
    required this.playerNames,
    this.roomCode,
  }) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameLogic game;

  @override
  void initState() {
    super.initState();
    game = GameLogic(
      mode: widget.mode,
      totalPlayers: widget.totalPlayers,
      targetScore: widget.targetScore,
      playerNames: widget.playerNames,
    );
  }

  void _playCard(CardModel card) {
    setState(() {
      game.playCard(card);
    });
  }

  @override
  Widget build(BuildContext context) {
    Player current = game.players[game.currentPlayerIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomCode != null ? "Room Code: ${widget.roomCode}" : "100 Card Game"),
        backgroundColor: Color(0xFF0F172A),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scoreboard
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Color(0xFF0F172A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: game.players
                    .map((p) => Text("${p.name}: ${p.currentScore} pts", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)))
                    .toList(),
              ),
            ),

            // Table Center
            Expanded(
              child: Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Color(0xFF155E75),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 3),
                  ),
                  child: Center(
                    child: Wrap(
                      spacing: 8,
                      children: game.tableCards
                          .map((tc) => Chip(
                                label: Text("${tc.card.number} ${tc.card.suit}", style: TextStyle(fontWeight: FontWeight.bold)),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),

            Text("${current.name}'s Turn", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            // Player Hand Cards
            Container(
              height: 100,
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: current.hand.length,
                itemBuilder: (context, index) {
                  CardModel card = current.hand[index];
                  return GestureDetector(
                    onTap: () => _playCard(card),
                    child: Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${card.number}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text(card.suit, style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
