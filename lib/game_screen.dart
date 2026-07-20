import 'package:flutter/material.dart';
import 'game_models.dart';
import 'game_logic.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late HundredGameLogic game;

  @override
  void initState() {
    super.initState();
    game = HundredGameLogic(
      mode: GameMode.offline,
      totalPlayers: 2,
      targetScore: 500,
    );
    game.startMatch(["Player 1", "Player 2"]);
  }

  @override
  Widget build(BuildContext context) {
    Player activePlayer = game.players[game.currentPlayerIndex];

    return Scaffold(
      appBar: AppBar(title: Text("100 Game - ${activePlayer.name}")),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: game.players
                    .map((p) => Text("${p.name}: ${p.currentScore} pts",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
                    .toList(),
              ),
              Spacer(),
              Text("${activePlayer.name} ke Cards:", style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: activePlayer.hand.map((card) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    child: Text("$card", style: TextStyle(fontSize: 20, color: Colors.white)),
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
                title: Text("First Turn Announcement"),
                content: Text(game.firstTurnNotice),
                actions: [
                  ElevatedButton(
                    child: Text("OK, Play Now"),
                    onPressed: () {
                      setState(() {
                        game.showFirstTurnDialog = false;
                      });
                    },
                  )
                ],
              ),
            ),
          if (game.isCardHiddenForPass && !game.showFirstTurnDialog)
            Container(
              color: Colors.black87
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Pass Phone to\n${activePlayer.name}",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                    child: Text("Show My Cards", style: TextStyle(fontSize: 18)),
                    onPressed: () {
                      setState(() {
                        game.isCardHiddenForPass = false;
                      });
                    },
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
