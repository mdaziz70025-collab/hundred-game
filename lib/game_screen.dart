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

  Widget _buildHiddenCard({bool isVertical = false}) {
    return Container(
      width: isVertical ? 25 : 35,
      height: isVertical ? 35 : 25,
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Center(child: Text("🎴", style: TextStyle(fontSize: 10))),
    );
  }

  @override
  Widget build(BuildContext context) {
    Player activePlayer = game.players[game.currentPlayerIndex];

    return Scaffold(
      backgroundColor: Color(0xFF1B2A47),
      appBar: AppBar(
        title: Text("100 Game - Target: ${widget.targetScore}"),
        backgroundColor: Color(0xFF0F172A),
      ),
      body: Stack(
        children: [
          // LUDO BOARD LAYOUT SYSTEM
          Column(
            children: [
              SizedBox(height: 10),
              
              // Top Player (Player 3)
              if (game.players.length >= 3)
                Column(
                  children: [
                    Text("${game.players[2].name} : ${game.players[2].currentScore} pts", 
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(game.players[2].hand.length, (_) => _buildHiddenCard()),
                    ),
                  ],
                ),

              Spacer(),

              // Middle Row (Left Player, Center Table Mat, Right Player)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Player (Player 4)
                  if (game.players.length == 4)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        children: [
                          RotatedBox(
                            quarterTurns: 1,
                            child: Text("${game.players[3].name} : ${game.players[3].currentScore} pts", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(height: 5),
                          Column(
                            children: List.generate(game.players[3].hand.length, (_) => _buildHiddenCard(isVertical: true)),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(width: 50),

                  // Center Circle Table Mat
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade800,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
                    ),
                    child: Center(
                      child: game.currentRoundCards.isEmpty
                          ? Text("Table Mat", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Center Table", style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.center,
                                  children: List.generate(game.currentRoundCards.length, (index) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "${game.playedCardOwners[index]}: ${game.currentRoundCards[index]}",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Right Player (Player 2)
                  if (game.players.length >= 2)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        children: [
                          RotatedBox(
                            quarterTurns: 3,
                            child: Text("${game.players[1].name} : ${game.players[1].currentScore} pts", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(height: 5),
                          Column(
                            children: List.generate(game.players[1].hand.length, (_) => _buildHiddenCard(isVertical: true)),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(width: 50),
                ],
              ),

              Spacer(),

              // Bottom Active Player (You)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Text("Your Turn: ${activePlayer.name} (${activePlayer.currentScore} pts)", 
                        style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: activePlayer.hand.map((card) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              child: Text("$card", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                setState(() {
                                  game.playCard(card);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // First Turn Popup
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

          // Pass Phone Overlay
          if (game.isCardHiddenForPass && !game.showFirstTurnDialog && game.winnerName.isEmpty)
            Container(
              color: Colors.black87,
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (game.lastRoundWinnerMsg.isNotEmpty) ...[
                    Text(game.lastRoundWinnerMsg, style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    SizedBox(height: 20),
                  ],
                  Text("Pass Phone to\n${activePlayer.name}", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 30),
                  ElevatedButton(
                    child: Text("Show My Cards"),
                    onPressed: () => setState(() {
                      game.isCardHiddenForPass = false;
                      game.lastRoundWinnerMsg = "";
                    }),
                  )
                ],
              ),
            ),

          // Match Winner Screen
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
