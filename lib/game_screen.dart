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
  
  bool isDealing = false;
  bool cardsDealt = false;
  int dealtCardsCount = 0;

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

  void _startDealingAnimation() async {
    setState(() {
      isDealing = true;
      cardsDealt = false;
      dealtCardsCount = 0;
    });

    int totalCards = (widget.totalPlayers == 3) ? 18 : 20;

    for (int i = 0; i < totalCards; i++) {
      await Future.delayed(Duration(milliseconds: 100)); 
      if (mounted) {
        setState(() {
          dealtCardsCount = i + 1;
        });
      }
    }

    await Future.delayed(Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        isDealing = false;
        cardsDealt = true;
      });
    }
  }

  Future<bool> _showExitDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Exit Game?"),
        content: Text("Kya aap game chhod kar baahar jaana chahte hain?"),
        actions: [
          TextButton(
            child: Text("NO"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("YES, EXIT"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildPlayingCard({required int value, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 72,
        margin: EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade700, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 4,
              offset: Offset(2, 3),
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
                child: Text("$value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
              ),
            ),
            Text("♠️", style: TextStyle(fontSize: 16, color: Colors.blue.shade900)),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 3.0, bottom: 2.0),
                child: Text("$value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenCard({bool isVertical = false}) {
    return Container(
      width: isVertical ? 22 : 32,
      height: isVertical ? 36 : 24,
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white70, width: 1),
      ),
      child: Center(child: Text("🎴", style: TextStyle(fontSize: 9))),
    );
  }

  @override
  Widget build(BuildContext context) {
    Player activePlayer = game.players[game.currentPlayerIndex];

    return WillPopScope(
      onWillPop: _showExitDialog,
      child: Scaffold(
        backgroundColor: Color(0xFF1B2A47),
        appBar: AppBar(
          backgroundColor: Color(0xFF0F172A),
          elevation: 4,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _showExitDialog()) {
                Navigator.pop(context);
              }
            },
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("100 Card Game", style: TextStyle(color: Colors.white, fontSize: 16)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "TARGET: ${widget.targetScore}",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
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

                // 2. TOP PLAYER NAME & CARDS
                if (game.players.length >= 3)
                  Column(
                    children: [
                      Text(
                        "${game.players[2].name} : ${game.players[2].currentScore} pts", 
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: cardsDealt 
                            ? List.generate(game.players[2].hand.length, (_) => _buildHiddenCard())
                            : [],
                      ),
                    ],
                  ),

                SizedBox(height: 15),

                // 1 & 2. CENTER TABLE MAT SHIFTED UP & PLAYERS AROUND IT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LEFT PLAYER
                    if (game.players.length == 4)
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Column(
                          children: [
                            RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                "${game.players[3].name} : ${game.players[3].currentScore} pts", 
                                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            SizedBox(height: 5),
                            Column(
                              children: cardsDealt 
                                  ? List.generate(game.players[3].hand.length, (_) => _buildHiddenCard(isVertical: true))
                                  : [],
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(width: 40),

                    // CENTER CIRCLE TABLE MAT
                    Container(
                      width: 175,
                      height: 175,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade900,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
                      ),
                      child: Center(
                        child: !cardsDealt && !isDealing
                            ? ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                ),
                                icon: Icon(Icons.style),
                                label: Text("DEAL CARDS", style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: _startDealingAnimation,
                              )
                            : isDealing
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Dealing Fast...", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 6),
                                      CircularProgressIndicator(color: Colors.amber),
                                      SizedBox(height: 6),
                                      Text("$dealtCardsCount Cards", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    ],
                                  )
                                : game.currentRoundCards.isEmpty
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

                    // RIGHT PLAYER
                    if (game.players.length >= 2)
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Column(
                          children: [
                            RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                "${game.players[1].name} : ${game.players[1].currentScore} pts", 
                                style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            SizedBox(height: 5),
                            Column(
                              children: cardsDealt 
                                  ? List.generate(game.players[1].hand.length, (_) => _buildHiddenCard(isVertical: true))
                                  : [],
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(width: 40),
                  ],
                ),

                // 2. BOTTOM PLAYER NAME (Directly below circle)
                SizedBox(height: 10),
                Text(
                  "${game.players[0].name} : ${game.players[0].currentScore} pts",
                  style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15),
                ),

                Spacer(),

                if (game.warningMsg.isNotEmpty)
                  Container(
                    color: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: Text(game.warningMsg, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),

                // BOTTOM PLAYER HAND AREA
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Text("Turn: ${activePlayer.name}", 
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: cardsDealt 
                              ? activePlayer.hand.map((cardValue) {
                                  return _buildPlayingCard(
                                    value: cardValue,
                                    onTap: () {
                                      setState(() {
                                        game.playCard(cardValue);
                                      });
                                    },
                                  );
                                }).toList()
                              : [Text("Tap 'DEAL CARDS' on center table to start", style: TextStyle(color: Colors.white54, fontSize: 12))],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // First Turn Popup
            if (game.showFirstTurnDialog && cardsDealt)
              Container(
                color: Colors.black54,
                child: AlertDialog(
                  title: Text("Lowest Card Rule"),
                  content: Text(game.firstTurnNotice),
                  actions: [
                    ElevatedButton(
                      child: Text("Start Turn"),
                      onPressed: () => setState(() => game.showFirstTurnDialog = false),
                    )
                  ],
                ),
              ),

            // 3. NEXT BAJI / NEXT TURN BUTTON OVERLAY
            if (game.isCardHiddenForPass && !game.showFirstTurnDialog && game.winnerName.isEmpty && cardsDealt)
              Container(
                color: Colors.black87,
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (game.lastRoundWinnerMsg.isNotEmpty) ...[
                      Text(game.lastRoundWinnerMsg, style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      SizedBox(height: 25),
                    ],
                    Text("Turn: ${activePlayer.name}", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: Text("NEXT BAJI / CONTINUE", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
                    Text("🎉 ${game.winnerName} WINS THE MATCH! 🎉", style: TextStyle(color: Colors.yellow, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      child: Text("BACK TO MENU", style: TextStyle(fontSize: 16)),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
