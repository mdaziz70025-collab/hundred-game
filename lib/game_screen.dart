import 'package:flutter/material.dart';
import 'game_models.dart';
import 'game_logic.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final int totalPlayers;
  final int targetScore;
  final List<String> playerNames;

  GameScreen({
    required this.mode,
    required this.totalPlayers,
    required this.targetScore,
    required this.playerNames,
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late HundredGameLogic game;

  @override
  void initState() {
    super.initState();
    game = HundredGameLogic(
      mode: widget.mode,
      totalPlayers: widget.totalPlayers,
      targetScore: widget.targetScore,
    );
    game.startMatch(widget.playerNames);
  }

  @override
  Widget build(BuildContext context) {
    Player activePlayer = game.players[game.currentPlayerIndex];

    return Scaffold(
      appBar: AppBar(title: Text("100 Game - Target: ${widget.targetScore}")),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 15),
              Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: 12,
                children: game.players
                    .map((p) => Text("${p.name}: ${p.currentScore}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
                    .toList(),
              ),
              Spacer(),
              Text("Turn: ${activePlayer.name}", style: TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activePlayer.hand.map((card) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    child: Text("$card", style: TextStyle(fontSize: 18, color: Colors.white)),
                    onPressed: () {
                      setState(() {
                        game.playCard(card);
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 40),
            ],
          ),
          if (game.showFirstTurnDialog)
            Container(
              color: Colors.black54,
              child: AlertDialog(
                title: Text("Lowest Card Check"),
                content: Text(game.firstTurnNotice),
                actions: [
                  ElevatedButton(
                    child: Text("Start Turn"),
                    onPressed: () => setState(() => game.showFirstTurnDialog = false),
                  )
                ],
              ),
            ),
          if (game.isCardHiddenForPass && !game.showFirstTurnDialog && game.winnerName.isEmpty)
            Container(
              color: Colors.black87,
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Pass Phone to\n${activePlayer.name}", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 30),
                  ElevatedButton(
                    child: Text("Show My Cards"),
                    onPressed: () => setState(() => game.isCardHiddenForPass = false),
                  )
                ],
              ),
            ),
          if (game.winnerName.isNotEmpty)
            Container(
              color: Colors.black87,
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("🎉 ${game.winnerName} WINS! 🎉", style: TextStyle(color: Colors.yellow, fontSize: 30, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text("Back to Menu"),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}
