import 'package0:flutter/material.dart';
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

  // TAASH PATTI CARD DESIGN (For Players Hand & Center Table)
  Widget _buildPlayingCard({required int value, bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 75,
        margin: EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade700, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 5,
              offset: Offset(2, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 3.0, top: 2.0),
                child: Text("$value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
              ),
            ),
            Text("♠️", style: TextStyle(fontSize: 18, color: Colors.blue.shade900)),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 3.0, bottom: 2.0),
                child: Text("$value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hidden Opponent Cards
  Widget _buildHiddenCard({bool isVertical = false}) {
    return Container(
      width: isVertical ? 24 : 34,
      height: isVertical ? 38 : 26,
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white70, width: 1),
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
        backgroundColor: Color(0xFF0F172A),
        elevation: 4,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("100 Card Game", style: TextStyle(color: Colors.white, fontSize: 18)),
            // 3. TARGET POINT DISPLAYED CLEARLY AT TOP
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "TARGET: ${widget.targetScore}",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 10),
              
              // Top Player (Player 3)
              if (game.players.length >= 3)
                Column(
                  children: [
                    Text("${game.players[2].name} : ${game.players[2].currentScore} pts", 
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(game.players[2].hand.length, (_) => _buildHiddenCard()),
                    ),
                  ],
                ),

              Spacer(),

              // Middle Row (Left, Center Table, Right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Player (Player 4)
                  if (game.players.length == 4)
                    Padding(
                      padding: const EdgeInsets.only(left: 6.0),
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
                    SizedBox(width: 40),

                  // 2. CENTER TABLE MAT WITH REAL TAASH CARDS
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade900,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
                    ),
                    child: Center(
                      child: game.currentRoundCards.isEmpty
                          ? Text("Table Mat", style: TextStyle(color: Colors.white54, fontSize: 13))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.center,
                                  children: List.generate(game.currentRoundCards.length, (index) {
                                    return Column(
                                      children: [
                                        _buildPlayingCard(value: game.currentRoundCards[index]),
                                        SizedBox(height: 2),
                                        Text(game.playedCardOwners[index], style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ],
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
                      padding: const EdgeInsets.only(right: 6.0),
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
                    SizedBox(width: 40),
                ],
              ),

              Spacer(),

              // 4. BOTTOM PLAYER 1 AREA WITH REAL TAASH PATTI CARDS
              Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Text("Turn: ${activePlayer.name} (Score: ${activePlayer.currentScore} pts)", 
                        style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: activePlayer.hand.map((cardValue) {
                          // 1. TAASH PATTI CARDS AT BOTTOM
                          return _buildPlayingCard(
                            value: cardValue,
                            onTap: () {
                              setState(() {
                                game.playCard(cardValue);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // First Turn Notice Popup
          if (game.showFirstTurnDialog)
            Container(
              color: Colors.black54,
              child: AlertDialog(
                title: Text("Lowest Card Notice"),
                content: Text(game.firstTurnNotice),
                actions: [
                  ElevatedButton(
                    child: Text("Start Match"),
                    onPressed: () => setState(() => game.showFirstTurnDialog = false),
                  )
                ],
              ),
            ),

          // Pass Phone Screen
          if (game.isCardHiddenForPass && !game.showFirstTurnDialog && game.winnerName.isEmpty)
            Container(
              color: Colors.black97,
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
