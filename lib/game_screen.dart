import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late HundredGameLogic game;
  
  bool isDealing = false;
  bool cardsDealt = false;
  bool isSoundEnabled = true;

  int currentlyDealingPlayerIndex = -1;
  int currentDealingCardIndex = 0;

  bool isCardFlying = false;
  int? flyingCardValue;

  late AnimationController _turnAnimationController;
  late Animation<double> _turnScaleAnimation;

  @override
  void initState() {
    super.initState();
    game = HundredGameLogic(
      mode: widget.mode,
      totalPlayers: widget.totalPlayers,
      targetScore: widget.targetScore,
    );
    game.startMatch(widget.playerNames);

    _turnAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _turnScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _turnAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _turnAnimationController.dispose();
    super.dispose();
  }

  void _playSoundEffect() {
    if (isSoundEnabled) {
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _playHeavySoundEffect() {
    if (isSoundEnabled) {
      HapticFeedback.vibrate();
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void _startDealingAnimation() async {
    _playHeavySoundEffect();
    setState(() {
      isDealing = true;
      cardsDealt = false;
      currentDealingCardIndex = 0;
    });

    int cardsPerPlayer = (widget.totalPlayers == 2) ? 10 : (widget.totalPlayers == 3 ? 6 : 5);

    for (int c = 0; c < cardsPerPlayer; c++) {
      for (int p = 0; p < widget.totalPlayers; p++) {
        if (!mounted) return;
        setState(() {
          currentlyDealingPlayerIndex = p;
          currentDealingCardIndex++;
        });
        _playSoundEffect();
        await Future.delayed(Duration(milliseconds: 120));
      }
    }

    await Future.delayed(Duration(milliseconds: 200));
    if (mounted) {
      _playHeavySoundEffect();
      setState(() {
        isDealing = false;
        cardsDealt = true;
        currentlyDealingPlayerIndex = -1;
        game.revealFirstTurnDialog();
      });
    }
  }

  void _handleCardTap(int cardValue) async {
    Player current = game.players[game.currentPlayerIndex];
    
    if (game.isFirstRound) {
      if (current.hand.contains(5) && cardValue != 5) {
        setState(() => game.warningMsg = "Pehle 5 number card hi chalna hoga!");
        return;
      }
      if (widget.totalPlayers == 3 && current.hand.contains(15) && cardValue != 15) {
        setState(() => game.warningMsg = "Pehle 15 number card hi chalna hoga!");
        return;
      }
    }

    if (game.currentRoundCards.isNotEmpty) {
      int highestOnTable = game.currentRoundCards.reduce((a, b) => a > b ? a : b);
      bool hasHigherCard = current.hand.any((c) => c > highestOnTable);
      if (hasHigherCard && cardValue < highestOnTable) {
        setState(() => game.warningMsg = "Aapke paas $highestOnTable se bada card hai, chhota nahi chal sakte!");
        return;
      }
    }

    _playSoundEffect();

    setState(() {
      isCardFlying = true;
      flyingCardValue = cardValue;
      game.warningMsg = "";
    });

    await Future.delayed(Duration(milliseconds: 350));

    if (!mounted) return;

    setState(() {
      isCardFlying = false;
      flyingCardValue = null;
      game.playCard(cardValue);
    });
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

  void _showScoreHistoryDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("📊 Match Score History", style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Divider(color: Colors.white30),
              Expanded(
                child: game.roundHistoryList.isEmpty
                    ? Center(child: Text("Abhi tak koi baji nahi kheli gayi.", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: game.roundHistoryList.length,
                        itemBuilder: (context, index) {
                          var history = game.roundHistoryList[index];
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.amber, child: Text("#${history.roundNumber}", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                            title: Text("Winner: ${history.winnerName}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: Text("+${history.points} pts", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCardSuit(int value) {
    if (value >= 80) return "♥️";
    if (value >= 50) return "♠️";
    if (value >= 30) return "♦️";
    return "♣️";
  }

  Color _getSuitColor(String suit) {
    return (suit == "♥️" || suit == "♦️") ? Colors.red.shade700 : Colors.black;
  }

  Widget _buildPlayingCard({required int value, VoidCallback? onTap}) {
    bool isHighValue = value >= 80;
    String suit = _getCardSuit(value);
    Color suitColor = _getSuitColor(suit);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 68,
        margin: EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isHighValue ? Colors.amber.shade600 : Colors.blueGrey.shade300,
            width: isHighValue ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighValue ? Colors.amber.withOpacity(0.4) : Colors.black38,
              blurRadius: isHighValue ? 6 : 3,
              spreadRadius: 1,
              offset: Offset(1, 2),
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
                child: Text("$value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: suitColor)),
              ),
            ),
            Text(suit, style: TextStyle(fontSize: 16, color: suitColor)),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 3.0, bottom: 2.0),
                child: Text("$value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: suitColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenCard({bool isVertical = false}) {
    return Container(
      width: isVertical ? 22 : 30,
      height: isVertical ? 34 : 22,
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white70, width: 1),
      ),
      child: Center(child: Text("🎴", style: TextStyle(fontSize: 8))),
    );
  }

  Widget _buildPlayerLabel(Player player, int playerIndex, {bool isRotated = false, int quarterTurns = 0}) {
    bool isCurrentTurn = cardsDealt && (game.currentPlayerIndex == playerIndex);
    bool isReceivingCard = isDealing && (currentlyDealingPlayerIndex == playerIndex);
    int wins = game.playerWinsMap[player.name] ?? 0;

    Widget textWidget = Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isReceivingCard 
            ? Colors.amber.shade800 
            : (isCurrentTurn ? Colors.green.shade700 : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
        border: (isCurrentTurn || isReceivingCard) ? Border.all(color: Colors.amberAccent, width: 2) : null,
        boxShadow: (isCurrentTurn || isReceivingCard)
            ? [BoxShadow(color: Colors.amberAccent.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrentTurn || isReceivingCard) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                ),
                SizedBox(width: 4),
              ],
              Text(
                "${player.name} : ${player.currentScore} pts",
                style: TextStyle(
                  color: (isCurrentTurn || isReceivingCard) ? Colors.white : Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: isCurrentTurn ? 13 : 11,
                ),
              ),
            ],
          ),
          Text(
            "👑 Wins: $wins",
            style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

    if (isRotated) {
      textWidget = RotatedBox(quarterTurns: quarterTurns, child: textWidget);
    }

    if (isCurrentTurn) {
      return ScaleTransition(scale: _turnScaleAnimation, child: textWidget);
    }

    return textWidget;
  }

  // PLAYER HAND AREA DIRECTLY UNDER THEIR NAME (ACTIVE PLAYER = OPEN CARDS, OTHERS = HIDDEN)
  Widget _buildPlayerHandView(int playerIndex, {bool isVertical = false}) {
    if (!cardsDealt) return SizedBox.shrink();

    Player p = game.players[playerIndex];
    bool isCurrentTurn = (game.currentPlayerIndex == playerIndex);

    // ONLY SHOW OPEN CARDS IF IT'S THIS PLAYER'S TURN
    if (isCurrentTurn) {
      if (isVertical) {
        return Column(
          children: List.generate(p.hand.length, (i) => _buildPlayingCard(
            value: p.hand[i],
            onTap: isCardFlying ? null : () => _handleCardTap(p.hand[i]),
          )),
        );
      } else {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: p.hand.map((cardValue) {
              return _buildPlayingCard(
                value: cardValue,
                onTap: isCardFlying ? null : () => _handleCardTap(cardValue),
              );
            }).toList(),
          ),
        );
      }
    } else {
      // OTHERWISE KEEP CARDS FULLY HIDDEN (BACKFACE)
      if (isVertical) {
        return Column(
          children: List.generate(p.hand.length, (_) => _buildHiddenCard(isVertical: true)),
        );
      } else {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(p.hand.length, (_) => _buildHiddenCard()),
        );
      }
    }
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("100 Card Game", style: TextStyle(color: Colors.white, fontSize: 15)),
                  Text("Round/Baji: #${game.totalRoundsPlayed}", style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                      color: isSoundEnabled ? Colors.greenAccent : Colors.redAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        isSoundEnabled = !isSoundEnabled;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.history, color: Colors.amber),
                    onPressed: _showScoreHistoryDrawer,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "TARGET: ${widget.targetScore}",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 25),

                // TOP PLAYER (PLAYER INDEX 2)
                if (game.players.length >= 3)
                  Column(
                    children: [
                      _buildPlayerLabel(game.players[2], 2),
                      SizedBox(height: 6),
                      _buildPlayerHandView(2),
                    ],
                  ),

                SizedBox(height: 20),

                // CENTER ROW WITH CASINO MAT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LEFT PLAYER (PLAYER INDEX 3)
                    if (game.players.length == 4)
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Column(
                          children: [
                            _buildPlayerLabel(game.players[3], 3, isRotated: true, quarterTurns: 1),
                            SizedBox(height: 6),
                            _buildPlayerHandView(3, isVertical: true),
                          ],
                        ),
                      )
                    else
                      SizedBox(width: 40),

                    // REALISTIC CASINO GREEN TABLE MAT
                    Container(
                      width: 175,
                      height: 175,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFF0F5132),
                            Color(0xFF06321D),
                          ],
                          radius: 0.8,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.shade600, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black87, blurRadius: 12, spreadRadius: 2)
                        ],
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
                                      Text("Dealing Cards...", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                                      SizedBox(height: 6),
                                      Container(
                                        width: 38,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.shade900,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amber, width: 2),
                                        ),
                                        child: Center(child: Text("🎴", style: TextStyle(fontSize: 16))),
                                      ),
                                      SizedBox(height: 6),
                                      Text("Card #$currentDealingCardIndex", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    ],
                                  )
                                : (game.currentRoundCards.isEmpty && !isCardFlying)
                                    ? Text("Table Mat", style: TextStyle(color: Colors.white54, fontSize: 13))
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            alignment: WrapAlignment.center,
                                            children: [
                                              ...List.generate(game.currentRoundCards.length, (index) {
                                                return Column(
                                                  children: [
                                                    _buildPlayingCard(value: game.currentRoundCards[index]),
                                                    SizedBox(height: 2),
                                                    Text(game.playedCardOwners[index], style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                                  ],
                                                );
                                              }),
                                              if (isCardFlying && flyingCardValue != null)
                                                AnimatedScale(
                                                  scale: 1.1,
                                                  duration: Duration(milliseconds: 300),
                                                  child: _buildPlayingCard(value: flyingCardValue!),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                      ),
                    ),

                    // RIGHT PLAYER (PLAYER INDEX 1)
                    if (game.players.length >= 2)
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Column(
                          children: [
                            _buildPlayerLabel(game.players[1], 1, isRotated: true, quarterTurns: 3),
                            SizedBox(height: 6),
                            _buildPlayerHandView(1, isVertical: true),
                          ],
                        ),
                      )
                    else
                      SizedBox(width: 40),
                  ],
                ),

                SizedBox(height: 25),

                // BOTTOM PLAYER (PLAYER INDEX 0)
                _buildPlayerLabel(game.players[0], 0),
                SizedBox(height: 8),
                _buildPlayerHandView(0),

                Spacer(),

                if (game.warningMsg.isNotEmpty)
                  Container(
                    color: Colors.redAccent,
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: Text(game.warningMsg, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),

            // FIRST TURN POPUP
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

            // RE-DEAL OVERLAY
            if (game.isDeckFinished && game.winnerName.isEmpty && !isCardFlying)
              Container(
                color: Colors.black87,
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("🃏 Hand Completed! 🃏", style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    Text("Target Score abhi tak kisi ne hit nahi kiya.", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 25),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                      icon: Icon(Icons.style, color: Colors.white),
                      label: Text("START NEXT BAJI (RE-DEAL)", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setState(() {
                          game.dealNewDeck();
                          cardsDealt = false;
                        });
                      },
                    )
                  ],
                ),
              ),

            // PASS PHONE OVERLAY (APPEARS BEFORE NEXT TURN TO HIDE CARDS)
            if (game.isCardHiddenForPass && !game.showFirstTurnDialog && game.winnerName.isEmpty && cardsDealt && !game.isDeckFinished && !isCardFlying)
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
                    Text("Pass Phone to:", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    SizedBox(height: 6),
                    Text("Turn: ${activePlayer.name}", textAlign: TextAlign.center, style: TextStyle(color: Colors.amberAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: Text("NEXT TURN / CONTINUE", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => setState(() {
                        game.isCardHiddenForPass = false;
                        game.lastRoundWinnerMsg = "";
                      }),
                    )
                  ],
                ),
              ),

            // MATCH WINNER OVERLAY
            if (game.winnerName.isNotEmpty && !isCardFlying)
              Container(
                color: Colors.black87,
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("🎆 👑 🎆", style: TextStyle(fontSize: 40)),
                    SizedBox(height: 10),
                    Text("🎉 ${game.winnerName} WINS THE MATCH! 🎉", style: TextStyle(color: Colors.yellow, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    SizedBox(height: 10),
                    Text("Congratulations! Champion of 100 Card Game!", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                      child: Text("BACK TO MENU", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
