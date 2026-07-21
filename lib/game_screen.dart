import 'package:flutter/material.dart';
import 'game_models.dart';

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
  late List<Player> players;
  int currentPlayerIndex = 0;
  List<CardModel> tableCards = [];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    List<String> suits = ['♠️', '♥️', '♦️', '♣️'];
    int playerIndex = 0;
    
    players = List.generate(
      widget.totalPlayers,
      (i) => Player(
        id: "p_$i",
        name: widget.playerNames.length > i ? widget.playerNames[i] : "Player ${i + 1}",
        hand: [],
        currentScore: 0,
      ),
    );

    int cardNum = 1;
    while (cardNum <= 100) {
      for (String suit in suits) {
        if (cardNum > 100) break;
        players[playerIndex].hand.add(CardModel(number: cardNum, suit: suit));
        playerIndex = (playerIndex + 1) % widget.totalPlayers;
        cardNum++;
      }
    }

    for (var player in players) {
      player.hand.sort((a, b) => a.number.compareTo(b.number));
    }
  }

  void _playCard(CardModel card) {
    setState(() {
      players[currentPlayerIndex].hand.removeWhere((c) => c.number == card.number);
      tableCards.add(card);
      
      if (tableCards.length == widget.totalPlayers) {
        tableCards.clear();
      }
      
      currentPlayerIndex = (currentPlayerIndex + 1) % widget.totalPlayers;
    });
  }

  @override
  Widget build(BuildContext context) {
    Player current = players[currentPlayerIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomCode != null ? "Room Code: ${widget.roomCode}" : "100 Card Game"),
        backgroundColor: Color(0xFF0F172A),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Players Score Board
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Color(0xFF0F172A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: players.map((p) => Text("${p.name}: ${p.currentScore} pts", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))).toList(),
              ),
            ),

            // Table Center
            Expanded(
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Color(0xFF155E75),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 3),
                  ),
                  child: Center(
                    child: Wrap(
                      spacing: 8,
                      children: tableCards.map((c) => Chip(label: Text("${c.number} ${c.suit}", style: TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    ),
                  ),
                ),
              ),
            ),

            // Active Player Turn Text
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
