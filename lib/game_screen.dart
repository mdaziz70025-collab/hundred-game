import 'package:flutter/material.dart';
import 'dart:math';
import 'game_models.dart';
import 'game_logic.dart';

class GameScreen extends StatefulWidget {
  final dynamic mode;
  final int totalPlayers;
  final int targetScore;
  final List<String> playerNames;
  final String? roomCode;

  const GameScreen({
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

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameLogic game;
  bool isDealing = false;

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

  void _dealCards() {
    setState(() {
      isDealing = true;
    });
    // Dummy delay to simulate deal animation time
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        isDealing = false;
      });
    });
  }

  Color _getSuitColor(String suit) {
    if (suit == '♥️' || suit == '♦️') return Colors.redAccent;
    return Colors.black87;
  }

  Widget _buildPlayerAvatar(Player player, Alignment alignment, bool isVertical, bool isCurrentTurn) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isCurrentTurn ? Colors.amberAccent.withOpacity(0.9) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isCurrentTurn ? Colors.amber : Colors.white24),
          boxShadow: isCurrentTurn ? [const BoxShadow(color: Colors.amber, blurRadius: 10)] : [],
        ),
        child: RotatedBox(
          quarterTurns: isVertical ? 0 : 0, // Set to 1 or 3 if you want text rotated on sides
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${player.name} : ${player.currentScore} pts",
                style: TextStyle(
                  color: isCurrentTurn ? Colors.black : Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                "👑 Wins: ${player.wins}",
                style: TextStyle(
                  color: isCurrentTurn ? Colors.black87 : Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(TableCard tc) {
    // Basic 3D Flip Entry Animation using TweenAnimationBuilder
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: pi, end: 0),
      duration: const Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // 3D perspective
            ..rotateY(value),
          alignment: FractionalOffset.center,
          child: value >= (pi / 2)
              ? Container(
                  width: 50,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade800,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                )
              : child,
        );
      },
      child: Container(
        width: 50,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${tc.card.number}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getSuitColor(tc.card.suit)),
            ),
            Text(tc.card.suit, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Player current = game.players[game.currentPlayerIndex];
    // Assigning positions (Bottom: Current Player, Top: Player 3, Left/Right: Player 2/4)
    Player p1Bottom = game.players[0];
    Player? p2Right = game.totalPlayers > 1 ? game.players[1] : null;
    Player? p3Top = game.totalPlayers > 2 ? game.players[2] : null;
    Player? p4Left = game.totalPlayers > 3 ? game.players[3] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF1E2436), // Dark background matching the "sahi" photo
      appBar: AppBar(
        title: Text(
          widget.roomCode != null ? "Room: ${widget.roomCode}" : "100 Card Game",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "TARGET: ${widget.targetScore}",
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Center Casino Table
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0xFF1B4F2B), Color(0xFF0C2B14)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
                  border: Border.all(color: Colors.amberAccent, width: 4),
                ),
                child: Center(
                  child: game.tableCards.isEmpty
                      ? ElevatedButton.icon(
                          onPressed: _dealCards,
                          icon: const Icon(Icons.style, color: Colors.black),
                          label: Text(isDealing ? "Dealing Cards..." : "DEAL CARDS"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        )
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: game.tableCards.map((tc) {
                            return _buildAnimatedCard(tc);
                          }).toList(),
                        ),
                ),
              ),
            ),

            // Player 3 (Top)
            if (p3Top != null)
              _buildPlayerAvatar(p3Top, Alignment.topCenter, true, current.id == p3Top.id),

            // Player 2 (Right)
            if (p2Right != null)
              _buildPlayerAvatar(p2Right, Alignment.centerRight, false, current.id == p2Right.id),

            // Player 4 (Left)
            if (p4Left != null)
              _buildPlayerAvatar(p4Left, Alignment.centerLeft, false, current.id == p4Left.id),

            // Player 1 / Main Hand (Bottom)
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPlayerAvatar(p1Bottom, Alignment.center, true, current.id == p1Bottom.id),
                  
                  // Active Player's Hand Cards
                  Container(
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: current.hand.length,
                      itemBuilder: (context, index) {
                        CardModel card = current.hand[index];
                        return GestureDetector(
                          onTap: () => _playCard(card),
                          child: Container(
                            width: 65,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${card.number}",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _getSuitColor(card.suit)),
                                ),
                                const SizedBox(height: 4),
                                Text(card.suit, style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        );
                      },
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
}
