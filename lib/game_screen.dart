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

  Color _getSuitColor(String suit) {
    if (suit == '♥️' || suit == '♦️') return Colors.redAccent;
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    Player current = game.players[game.currentPlayerIndex];

    return Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(
          widget.roomCode != null ? "Room: ${widget.roomCode}" : "100 Card Game",
          style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF0F172A),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Players Score Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              color: Color(0xFF0F172A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: game.players.map((p) {
                  bool isCurrentTurn = p.id == current.id;
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isCurrentTurn ? Colors.amberAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isCurrentTurn ? Colors.amber : Colors.white24),
                    ),
                    child: Text(
                      "${p.name}: ${p.currentScore}",
                      style: TextStyle(
                        color: isCurrentTurn ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Casino Green Table (Center)
            Expanded(
              child: Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0xFF1E5631), Color(0xFF0B3B18)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 12)],
                    border: Border.all(color: Colors.amberAccent, width: 3),
                  ),
                  child: Center(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: game.tableCards.map((tc) {
                        return Container(
                          width: 50,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("${tc.card.number}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getSuitColor(tc.card.suit))),
                              Text(tc.card.suit, style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),

            // Turn Indicator
            Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.amberAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "👉 ${current.name}'s Turn",
                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: 10),

            // Active Player's Hand Cards (Bottom)
            Container(
              height: 105,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: current.hand.length,
                itemBuilder: (context, index) {
                  CardModel card = current.hand[index];
                  bool isHighCard = card.number >= 80;

                  return GestureDetector(
                    onTap: () => _playCard(card),
                    child: Container(
                      width: 62,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isHighCard ? Colors.amber : Colors.grey.shade400,
                          width: isHighCard ? 2 : 1,
                        ),
                        boxShadow: [
                          if (isHighCard) BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 5)
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${card.number}",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getSuitColor(card.suit)),
                          ),
                          SizedBox(height: 2),
                          Text(card.suit, style: TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
