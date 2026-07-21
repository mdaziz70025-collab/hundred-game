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
  bool isHandVisible = true;

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
      if (widget.mode == GameMode.offline) {
        isHandVisible = false;
      }
    });
  }

  Color _getSuitColor(String suit) {
    if (suit == '♥️' || suit == '♦️') return Colors.redAccent;
    return Colors.black87;
  }

  Widget _buildPlayerSlot(Player p, bool isCurrentTurn, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrentTurn ? Colors.amberAccent : Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isCurrentTurn ? Colors.amber : Colors.white30, width: 2),
          boxShadow: [
            if (isCurrentTurn) BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              p.name,
              style: TextStyle(
                color: isCurrentTurn ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              "${p.currentScore} pts",
              style: TextStyle(
                color: isCurrentTurn ? Colors.black87 : Colors.amberAccent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Player current = game.players[game.currentPlayerIndex];

    Player pBottom = game.players[0];
    Player pLeft = game.players.length > 1 ? game.players[1] : game.players[0];
    Player pTop = game.players.length > 2 ? game.players[2] : game.players[0];
    Player pRight = game.players.length > 3 ? game.players[3] : game.players[0];

    return Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(
          widget.roomCode != null ? "Room: ${widget.roomCode}" : "100 Card Game",
          style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Color(0xFF0F172A),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 4-Sided Board Layout (Top, Left, Right, Center)
            Expanded(
              child: Stack(
                children: [
                  _buildPlayerSlot(pTop, current.id == pTop.id, Alignment.topCenter),
                  _buildPlayerSlot(pLeft, current.id == pLeft.id, Alignment.centerLeft),
                  _buildPlayerSlot(pRight, current.id == pRight.id, Alignment.centerRight),

                  // Casino Green Felt Table
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
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
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: game.tableCards.map((tc) {
                            return Container(
                              width: 48,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("${tc.card.number}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _getSuitColor(tc.card.suit))),
                                  Text(tc.card.suit, style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  _buildPlayerSlot(pBottom, current.id == pBottom.id, Alignment.bottomCenter),
                ],
              ),
            ),

            SizedBox(height: 8),

            // Turn Indicator & Show Cards Privacy Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("👉 ${current.name}'s Turn", style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                if (widget.mode == GameMode.offline && !isHandVisible) ...[
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                    child: Text("SHOW CARDS 👁️", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => setState(() => isHandVisible = true),
                  )
                ]
              ],
            ),

            SizedBox(height: 8),

            // Active Player Cards
            Container(
              height: 100,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: isHandVisible
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: current.hand.length,
                      itemBuilder: (context, index) {
                        CardModel card = current.hand[index];
                        bool isHighCard = card.number >= 80;

                        return GestureDetector(
                          onTap: () => _playCard(card),
                          child: Container(
                            width: 60,
                            margin: EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isHighCard ? Colors.amber : Colors.grey.shade400, width: isHighCard ? 2 : 1),
                              boxShadow: [
                                if (isHighCard) BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 5)
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("${card.number}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getSuitColor(card.suit))),
                                SizedBox(height: 2),
                                Text(card.suit, style: TextStyle(fontSize: 15)),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        "Pass phone to ${current.name} & tap 'SHOW CARDS'",
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
