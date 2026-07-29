import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_database/firebase_database.dart';
import 'game_models.dart';
import 'game_logic.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final int totalPlayers;
  final int targetScore;
  final List<String> playerNames;
  final bool isHost;
  final String roomCode;
  final String myPlayerName;

  GameScreen({
    required this.mode,
    required this.totalPlayers,
    required this.targetScore,
    required this.playerNames,
    this.isHost = true,
    this.roomCode = "",
    this.myPlayerName = "",
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late HundredGameLogic game;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _roomSubscription;

  bool isDealing = false;
  bool cardsDealt = false;
  bool isSoundEnabled = true;

  int currentlyDealingPlayerIndex = -1;
  int currentDealingCardIndex = 0;

  bool isCardFlying = false;
  int? flyingCardValue;
  String currentDealerName = "";

  late AnimationController _turnAnimationController;
  late Animation<double> _turnScaleAnimation;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  final String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();

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

    if (widget.mode == GameMode.friend && widget.roomCode.isNotEmpty) {
      _listenToFirebaseRoom();
    }
  }

  void _listenToFirebaseRoom() {
    try {
      _roomSubscription = _dbRef.child("rooms").child(widget.roomCode).onValue.listen((event) {
        if (!event.snapshot.exists || event.snapshot.value == null) return;

        Map<dynamic, dynamic> roomData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        List<String> roomPlayers = List<String>.from(roomData['players'] ?? []);
        int currentDealerIdx = roomData['currentDealerIndex'] ?? 0;
        bool firebaseDealtStatus = roomData['cardsDealt'] ?? false;

        if (roomPlayers.isNotEmpty) {
          String dealer = roomPlayers[currentDealerIdx % roomPlayers.length];
          
          if (mounted) {
            setState(() {
              currentDealerName = dealer;
            });
          }

          if (firebaseDealtStatus && roomData['hands'] != null) {
            Map handsMap = roomData['hands'] as Map;
            
            for (int p = 0; p < game.players.length; p++) {
              String pName = game.players[p].name;
              if (handsMap.containsKey(pName)) {
                List<int> pHand = List<int>.from(handsMap[pName] ?? []);
                game.players[p].hand = pHand;
              }
            }

            if (roomData['tableCards'] != null) {
              List<int> tableCards = List<int>.from(roomData['tableCards'] ?? []);
              List<String> tableOwners = List<String>.from(roomData['tableOwners'] ?? []);
              game.currentRoundCards = tableCards;
              game.playedCardOwners = tableOwners;
            }

            // 🎯 Realtime Turn Sync Across Devices
            if (roomData['turnIndex'] != null) {
              int syncedTurn = roomData['turnIndex'];
              if (syncedTurn < game.players.length) {
                game.currentPlayerIndex = syncedTurn;
              }
            }

            if (!cardsDealt) {
              setState(() {
                cardsDealt = true;
              });
            } else {
              setState(() {});
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Firebase sync error: $e");
    }
  }

  void _loadBannerAd() {
    try {
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isBannerAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, err) {
            ad.dispose();
          },
        ),
      )..load();
    } catch (e) {
      debugPrint("Ad error: $e");
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _bannerAd?.dispose();
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

  bool get _canCurrentPlayerDeal {
    if (widget.mode != GameMode.friend) return true;
    
    if (currentDealerName.isNotEmpty) {
      return widget.myPlayerName.trim().toLowerCase() == currentDealerName.trim().toLowerCase();
    }
    return widget.isHost;
  }

  void _startDealingAnimation() async {
    _playHeavySoundEffect();
    setState(() {
      isDealing = true;
      cardsDealt = false;
      currentDealingCardIndex = 0;
    });

    // 🎯 Step 1: New deck deal aur lowest card owner evaluate karo
    game.dealNewDeck();

    // 🎯 Step 2: Firebase Database par exact turnIndex (5 number card wale ka) sync karo
    if (widget.mode == GameMode.friend && widget.roomCode.isNotEmpty) {
      Map<String, List<int>> handsSyncMap = {};
      for (var player in game.players) {
        handsSyncMap[player.name] = player.hand;
      }

      await _dbRef.child("rooms").child(widget.roomCode).update({
        "cardsDealt": true,
        "hands": handsSyncMap,
        "tableCards": [],
        "tableOwners": [],
        "turnIndex": game.currentPlayerIndex, // 👈 Fix: Lowest card player index sent to all!
      });
    }

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

      _checkAndPlayNextTurn();
    }
  }

  void _checkAndPlayNextTurn() async {
    if (!cardsDealt || isDealing || game.isDeckFinished || game.winnerName.isNotEmpty) return;
    if (game.players.isEmpty || game.currentPlayerIndex >= game.players.length) return;

    Player current = game.players[game.currentPlayerIndex];

    bool isLastRound = game.players.every((p) => p.hand.length == 1);
    if (isLastRound) {
      await Future.delayed(Duration(milliseconds: 500));
      if (!mounted) return;
      if (current.hand.isNotEmpty) {
        _handleCardTap(current.hand.first);
      }
      return;
    }

    if (current.name.toLowerCase().contains("bot") || current.name.toLowerCase().contains("computer")) {
      await Future.delayed(Duration(milliseconds: 700));
      if (!mounted) return;

      List<int> playableCards = [];

      for (int card in current.hand) {
        bool isLegal = true;

        if (game.isFirstRound) {
          if (current.hand.contains(5) && card != 5) isLegal = false;
          if (widget.totalPlayers == 3 && current.hand.contains(15) && card != 15) isLegal = false;
        }

        if (game.currentRoundCards.isNotEmpty && isLegal) {
          int highestOnTable = game.currentRoundCards.reduce((a, b) => a > b ? a : b);
          bool hasHigherCard = current.hand.any((c) => c > highestOnTable);
          if (hasHigherCard && card < highestOnTable) {
            isLegal = false;
          }
        }

        if (isLegal) {
          playableCards.add(card);
        }
      }

      int selectedCard;
      if (playableCards.isNotEmpty) {
        playableCards.sort();
        if (game.currentRoundCards.isNotEmpty) {
          selectedCard = playableCards.last;
        } else {
          selectedCard = playableCards.first;
        }
      } else {
        selectedCard = current.hand.first;
      }

      _handleCardTap(selectedCard);
    }
  }

  void _handleCardTap(int cardValue) async {
    if (game.players.isEmpty || game.currentPlayerIndex >= game.players.length) return;
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

    await Future.delayed(Duration(milliseconds: 300));

    if (!mounted) return;

    game.playCard(cardValue);

    // 🎯 CARD MOVE SYNC: Firebase update triggers real-time move across connected devices
    if (widget.mode == GameMode.friend && widget.roomCode.isNotEmpty) {
      Map<String, List<int>> handsSyncMap = {};
      for (var player in game.players) {
        handsSyncMap[player.name] = player.hand;
      }

      await _dbRef.child("rooms").child(widget.roomCode).update({
        "hands": handsSyncMap,
        "tableCards": List<int>.from(game.currentRoundCards),
        "tableOwners": List<String>.from(game.playedCardOwners),
        "turnIndex": game.currentPlayerIndex,
      });
    }

    setState(() {
      isCardFlying = false;
      flyingCardValue = null;
    });

    _checkAndPlayNextTurn();
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
    bool isDealer = currentDealerName.isNotEmpty && (player.name.trim().toLowerCase() == currentDealerName.trim().toLowerCase());
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
              if (isDealer) ...[
                Text("🎴 ", style: TextStyle(fontSize: 10)),
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
            "👑 Wins: $wins ${isDealer ? '(Dealer)' : ''}",
            style: TextStyle(color: isDealer ? Colors.greenAccent : Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
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

  Widget _buildPlayerHandView(int playerIndex, {bool isVertical = false}) {
    if (!cardsDealt) return SizedBox.shrink();
    if (playerIndex >= game.players.length) return SizedBox.shrink();

    Player p = game.players[playerIndex];
    bool isCurrentTurn = (game.currentPlayerIndex == playerIndex);

    // 🎯 ONLINE / FRIEND MODE: Player 0 (Aapka Device Player) hamesha apne cards dekh sakta hai
    if (widget.mode == GameMode.friend) {
      if (playerIndex == 0) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: p.hand.map((cardValue) {
              return _buildPlayingCard(
                value: cardValue,
                onTap: (isCardFlying || !isCurrentTurn) ? null : () => _handleCardTap(cardValue),
              );
            }).toList(),
          ),
        );
      } else {
        return SizedBox.shrink();
      }
    }

    // PASS N PLAY MODE (Offline)
    bool shouldShowCards = isCurrentTurn && !game.isCardHiddenForPass;

    if (shouldShowCards) {
      if (isVertical) {
        return Column(
          children: p.hand.map((cardValue) {
            return _buildPlayingCard(
              value: cardValue,
              onTap: (isCardFlying || !isCurrentTurn) ? null : () => _handleCardTap(cardValue),
            );
          }).toList(),
        );
      } else {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: p.hand.map((cardValue) {
              return _buildPlayingCard(
                value: cardValue,
                onTap: (isCardFlying || !isCurrentTurn) ? null : () => _handleCardTap(cardValue),
              );
            }).toList(),
          ),
        );
      }
    } else {
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
    if (game.players.isEmpty) {
      return Scaffold(
        backgroundColor: Color(0xFF1B2A47),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    Player activePlayer = game.players[game.currentPlayerIndex % game.players.length];
    String dealerDisplayName = currentDealerName.isNotEmpty ? currentDealerName : game.players[0].name;

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
                if (game.players.length >= 3)
                  Column(
                    children: [
                      _buildPlayerLabel(game.players[2], 2),
                      SizedBox(height: 6),
                      _buildPlayerHandView(2),
                    ],
                  ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                            ? (_canCurrentPlayerDeal
                                ? ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                    ),
                                    icon: Icon(Icons.style),
                                    label: Text("DEAL CARDS", style: TextStyle(fontWeight: FontWeight.bold)),
                                    onPressed: _startDealingAnimation,
                                  )
                                : Container(
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Waiting for $dealerDisplayName to Deal...",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ))
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

                if (_isBannerAdLoaded && _bannerAd != null)
                  Container(
                    alignment: Alignment.center,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    margin: const EdgeInsets.only(bottom: 4.0),
                    child: AdWidget(ad: _bannerAd!),
                  ),
              ],
            ),
            if (game.showFirstTurnDialog && cardsDealt)
              Container(
                color: Colors.black54,
                child: AlertDialog(
                  title: Text("Lowest Card Rule"),
                  content: Text(game.firstTurnNotice),
                  actions: [
                    ElevatedButton(
                      child: Text("Start Turn"),
                      onPressed: () {
                        setState(() => game.showFirstTurnDialog = false);
                        _checkAndPlayNextTurn();
                      },
                    )
                  ],
                ),
              ),
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
                      onPressed: () async {
                        if (widget.mode == GameMode.friend && widget.roomCode.isNotEmpty) {
                          DataSnapshot snap = await _dbRef.child("rooms").child(widget.roomCode).get();
                          if (snap.exists) {
                            Map data = snap.value as Map;
                            List players = data['players'] ?? [];
                            int currentDealer = data['currentDealerIndex'] ?? 0;
                            int nextDealer = (currentDealer + 1) % players.length;

                            await _dbRef.child("rooms").child(widget.roomCode).update({
                              "currentDealerIndex": nextDealer,
                              "cardsDealt": false,
                              "tableCards": [],
                              "tableOwners": [],
                            });
                          }
                        }
                        setState(() {
                          game.dealNewDeck();
                          cardsDealt = false;
                        });
                      },
                    )
                  ],
                ),
              ),
            if (widget.mode != GameMode.friend && game.isCardHiddenForPass && !game.showFirstTurnDialog && game.winnerName.isEmpty && cardsDealt && !game.isDeckFinished && !isCardFlying)
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
                        _checkAndPlayNextTurn();
                      }),
                    )
                  ],
                ),
              ),
            if (game.winnerName.isNotEmpty && !isCardFlying)
              Container(
                color: Colors.black87,
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: BuildAxisAlignment.center,
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
