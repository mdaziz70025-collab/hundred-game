import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool isProcessingTurn = false;
  int? flyingCardValue;
  String currentDealerName = "";

  late AnimationController _turnAnimationController;
  late Animation<double> _turnScaleAnimation;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  final String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  final String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();

    User? user = FirebaseAuth.instance.currentUser;
    List<String> names = List.from(widget.playerNames);
    if (user != null && names.isNotEmpty && widget.mode != GameMode.friend) {
      names[0] = user.displayName ?? names[0];
    }

    game = HundredGameLogic(
      mode: widget.mode,
      totalPlayers: widget.totalPlayers,
      targetScore: widget.targetScore,
    );
    game.startMatch(names);

    cardsDealt = false;

    _turnAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _turnScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _turnAnimationController, curve: Curves.easeInOut),
    );

    if (widget.mode == GameMode.friend && widget.roomCode.isNotEmpty) {
      _listenToFirebaseRoom();
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
            if (mounted) setState(() => _isBannerAdLoaded = true);
          },
          onAdFailedToLoad: (ad, err) => ad.dispose(),
        ),
      )..load();
    } catch (e) {
      debugPrint("Banner Ad error: $e");
    }
  }

  void _loadInterstitialAd() {
    try {
      InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
          },
          onAdFailedToLoad: (err) {
            _isInterstitialAdLoaded = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint("Interstitial Ad error: $e");
    }
  }

  void _showInterstitialAd({required VoidCallback onAdDismissed}) {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
          onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _loadInterstitialAd();
          onAdDismissed();
        },
      );
      _interstitialAd!.show();
    } else {
      onAdDismissed();
    }
  }

  void _listenToFirebaseRoom() {
    try {
      _roomSubscription?.cancel();
      _roomSubscription = _dbRef.child("rooms").child(widget.roomCode).onValue.listen((event) {
        if (!event.snapshot.exists || event.snapshot.value == null) return;

        Map<dynamic, dynamic> roomData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        List<String> roomPlayers = List<String>.from(roomData['players'] ?? []);
        int currentDealerIdx = roomData['currentDealerIndex'] ?? 0;
        bool firebaseDealtStatus = roomData['cardsDealt'] ?? false;
        bool isBajiFinishedInFb = roomData['isBajiFinished'] ?? false;

        if (roomPlayers.isNotEmpty) {
          if (game.players.length != roomPlayers.length) {
            game.players = roomPlayers.map((name) => Player(id: name, name: name, hand: [])).toList();
          }

          String dealer = roomPlayers[currentDealerIdx % roomPlayers.length];
          
          if (mounted) {
            setState(() {
              currentDealerName = dealer;
            });
          }

          if (roomData['targetScore'] != null) {
            int tScore = int.tryParse(roomData['targetScore'].toString()) ?? widget.targetScore;
            game.targetScore = tScore;
          }

          List<int> tableCards = List<int>.from(roomData['tableCards'] ?? []);
          List<String> tableOwners = List<String>.from(roomData['tableOwners'] ?? []);

          if (mounted) {
            setState(() {
              isProcessingTurn = false;
              isCardFlying = false;
            });
          }

          if (firebaseDealtStatus && roomData['hands'] != null) {
            Map handsMap = roomData['hands'] as Map;
            
            for (int p = 0; p < game.players.length; p++) {
              String pName = game.players[p].name;
              var matchingKey = handsMap.keys.firstWhere(
                (k) => k.toString().trim().toLowerCase() == pName.trim().toLowerCase(),
                orElse: () => null,
              );

              if (matchingKey != null) {
                List<int> pHand = List<int>.from(handsMap[matchingKey] ?? []);
                game.players[p].hand = pHand;
              }
            }

            if (roomData['scores'] != null) {
              Map scoresMap = roomData['scores'] as Map;
              for (int p = 0; p < game.players.length; p++) {
                String pName = game.players[p].name;
                var matchingKey = scoresMap.keys.firstWhere(
                  (k) => k.toString().trim().toLowerCase() == pName.trim().toLowerCase(),
                  orElse: () => null,
                );
                if (matchingKey != null) {
                  int sVal = int.tryParse(scoresMap[matchingKey].toString()) ?? 0;
                  game.players[p].currentScore = sVal;

                  if (sVal >= game.targetScore && game.winnerName.isEmpty) {
                    game.winnerName = pName;
                  }
                }
              }
            }

            if (roomData['wins'] != null) {
              Map winsMap = roomData['wins'] as Map;
              winsMap.forEach((key, value) {
                game.playerWinsMap[key.toString()] = int.tryParse(value.toString()) ?? 0;
              });
            }

            if (roomData['totalRoundsPlayed'] != null) {
              game.totalRoundsPlayed = int.tryParse(roomData['totalRoundsPlayed'].toString()) ?? 0;
            }

            game.currentRoundCards = tableCards;
            game.playedCardOwners = tableOwners;

            if (roomData['currentTurnPlayer'] != null) {
              String activeTurnName = roomData['currentTurnPlayer'].toString().trim().toLowerCase();
              int foundIndex = game.players.indexWhere((p) => p.name.trim().toLowerCase() == activeTurnName);
              if (foundIndex != -1) {
                game.currentPlayerIndex = foundIndex;
              }
            }

            bool isTargetHit = game.players.any((p) => p.currentScore >= game.targetScore);
            
            if (isBajiFinishedInFb || game.isDeckFinished) {
              if (!isTargetHit && mounted) {
                setState(() {
                  game.isDeckFinished = true;
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  game.isDeckFinished = false;
                });
              }
            }

            if (mounted) {
              setState(() {
                cardsDealt = true;
              });
            }
          } else if (!firebaseDealtStatus) {
            bool isTargetHit = game.players.any((p) => p.currentScore >= game.targetScore);
            bool hasPlayedAtLeastOneRound = game.totalRoundsPlayed > 0;

            if (mounted) {
              setState(() {
                cardsDealt = false;
                if (!isTargetHit && hasPlayedAtLeastOneRound) {
                  game.isDeckFinished = true;
                } else {
                  game.isDeckFinished = false;
                }
              });
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Firebase sync error: $e");
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
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

  int _getRelativePlayerIndex(int seatPosition) {
    if (widget.mode != GameMode.friend) return seatPosition;

    int myLocalIndex = game.players.indexWhere((p) => p.name.trim().toLowerCase() == widget.myPlayerName.trim().toLowerCase());
    if (myLocalIndex == -1) myLocalIndex = 0;

    return (myLocalIndex + seatPosition) % game.players.length;
  }

  bool get _isMyTurn {
    if (widget.mode != GameMode.friend) return true;
    if (game.players.isEmpty || game.currentPlayerIndex >= game.players.length) return false;
    
    String activeTurnPlayer = game.players[game.currentPlayerIndex].name.trim().toLowerCase();
    String myDevicePlayer = widget.myPlayerName.trim().toLowerCase();
    
    return activeTurnPlayer == myDevicePlayer;
  }

  void _startDealingAnimation() async {
    _playHeavySoundEffect();
    setState(() {
      isDealing = true;
      cardsDealt = false;
      currentDealingCardIndex = 0;
      game.isDeckFinished = false;
    });

    game.dealNewDeck();

    if (widget.mode == GameMode.friend && widget.roomCode.isNotEmpty) {
      Map<String, List<int>> handsSyncMap = {};
      Map<String, int> scoresSyncMap = {};
      for (var player in game.players) {
        handsSyncMap[player.name] = player.hand;
        scoresSyncMap[player.name] = player.currentScore;
      }

      String firstTurnPlayerName = game.players[game.currentPlayerIndex].name;

      await _dbRef.child("rooms").child(widget.roomCode).update({
        "cardsDealt": true,
        "isBajiFinished": false,
        "targetScore": widget.targetScore,
        "hands": handsSyncMap,
        "scores": scoresSyncMap,
        "wins": game.playerWinsMap,
        "totalRoundsPlayed": game.totalRoundsPlayed,
        "tableCards": [],
        "tableOwners": [],
        "currentTurnPlayer": firstTurnPlayerName,
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
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _playHeavySoundEffect();
      setState(() {
        isDealing = false;
        cardsDealt = true;
        currentlyDealingPlayerIndex = -1;
        
        if (widget.mode == GameMode.offline) {
          game.isCardHiddenForPass = true;
        } else {
          game.revealFirstTurnDialog();
        }
      });

      if (widget.mode != GameMode.offline) {
        _checkAndPlayNextTurn();
      }
    }
  }

  void _checkAndPlayNextTurn() async {
    if (widget.mode == GameMode.friend) return;

    if (isDealing || game.isDeckFinished || game.winnerName.isNotEmpty) return;
    if (game.players.isEmpty || game.currentPlayerIndex >= game.players.length) return;

    Player current = game.players[game.currentPlayerIndex];

    if (current.hand.isEmpty) return;

    if (current.name.toLowerCase().contains("bot") || current.name.toLowerCase().contains("computer")) {
      await Future.delayed(const Duration(milliseconds: 700));
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
    if (isProcessingTurn || isCardFlying) return;
    if (game.players.isEmpty || game.currentPlayerIndex >= game.players.length) return;
    if (widget.mode == GameMode.friend && !_isMyTurn) return;

    Player current = game.players[game.currentPlayerIndex];

    if (!current.hand.contains(cardValue)) return;

    if (game.isFirstRound) {
      if (current.hand.contains(5) && cardValue != 5) {
        setState(() => game.warningMsg = "Pehle 5 number card hi chalna hoga!");
        return;
      }
      if (widget.totalPlayers == 3 && cardValue != 15 && current.hand.contains(15)) {
        setState(() => game.warningMsg = "Pehle 15 number card hi chalna hoga!");
        return;
      }
    }

    if (game.currentRoundCards.isNotEmpty) {
      int highestOnTable = game.currentRoundCards.reduce(max);
      bool hasHigherCard = current.hand.any((c) => c > highestOnTable);
      if (hasHigherCard && cardValue < highestOnTable) {
        setState(() => game.warningMsg = "Aapke paas $highestOnTable se bada card hai, chhota nahi chal sakte!");
        return;
      }
    }

    _playSoundEffect();

    setState(() {
      isProcessingTurn = true;
      isCardFlying = true;
      flyingCardValue = cardValue;
      game.warningMsg = "";
    });

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    current.hand.remove(cardValue);
    game.currentRoundCards.add(cardValue);
    game.playedCardOwners.add(current.name);

    bool isLastCardOfTrick = (game.currentRoundCards.length >= widget.totalPlayers);

    int nextTurnIdx = (game.currentPlayerIndex + 1) % game.players.length;
    String nextTurnPlayerName = game.players[nextTurnIdx].name;

    if (widget.mode == GameMode.friend && widget.roomCode.isNotEmpty) {
      Map<String, List<int>> handsSyncMap = {};
      Map<String, int> scoresSyncMap = {};
      for (var player in game.players) {
        handsSyncMap[player.name] = player.hand;
        scoresSyncMap[player.name] = player.currentScore;
      }

      await _dbRef.child("rooms").child(widget.roomCode).update({
        "hands": handsSyncMap,
        "tableCards": List<int>.from(game.currentRoundCards),
        "tableOwners": List<String>.from(game.playedCardOwners),
        "currentTurnPlayer": nextTurnPlayerName,
      });
    }

    if (mounted) {
      setState(() {
        isCardFlying = false;
        flyingCardValue = null;
      });
    }

    if (isLastCardOfTrick) {
      // 1.3 Seconds delay to ensure all players see cards rendered on table
      await Future.delayed(const Duration(milliseconds: 1300));

      game.evaluateRoundWinner();

      if (widget.mode == GameMode.friend && widget.roomCode.isNotEmpty) {
        Map<String, List<int>> handsSyncMap = {};
        Map<String, int> scoresSyncMap = {};
        for (var player in game.players) {
          handsSyncMap[player.name] = player.hand;
          scoresSyncMap[player.name] = player.currentScore;
        }

        String trickWinnerPlayerName = game.players[game.currentPlayerIndex].name;
        bool isTargetHit = game.players.any((p) => p.currentScore >= game.targetScore);

        await _dbRef.child("rooms").child(widget.roomCode).update({
          "hands": handsSyncMap,
          "scores": scoresSyncMap,
          "wins": game.playerWinsMap,
          "targetScore": widget.targetScore,
          "totalRoundsPlayed": game.totalRoundsPlayed,
          "tableCards": [], 
          "tableOwners": [],
          "currentTurnPlayer": trickWinnerPlayerName,
          "isBajiFinished": (game.isDeckFinished && !isTargetHit),
          if (game.isDeckFinished && !isTargetHit) "cardsDealt": false,
        });
      }
    }

    if (mounted) {
      setState(() {
        isProcessingTurn = false;
      });

      _checkAndPlayNextTurn();
    }
  }

  Future<bool> _showExitDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit Game?"),
        content: const Text("Kya aap game chhod kar baahar jaana chahte hain?"),
        actions: [
          TextButton(
            child: const Text("NO"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("YES, EXIT"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showScoreHistoryDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("📊 Match Score History", style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: Colors.white30),
              Expanded(
                child: game.roundHistoryList.isEmpty
                    ? const Center(child: Text("Abhi tak koi baji nahi kheli gayi.", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: game.roundHistoryList.length,
                        itemBuilder: (context, index) {
                          var history = game.roundHistoryList[index];
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.amber, child: Text("#${history.roundNumber}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                            title: Text("Winner: ${history.winnerName}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: Text("+${history.points} pts", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
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
    if (value >= 80) return "🌹";
    if (value >= 50) return "🌻";
    if (value >= 30) return "🌺";
    return "🌸";
  }

  Color _getSuitColor(String suit) {
    return Colors.black; 
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
        margin: const EdgeInsets.symmetric(horizontal: 2),
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
              offset: const Offset(1, 2),
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
            Text(suit, style: const TextStyle(fontSize: 16)),
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
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.pink.shade900,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white70, width: 1),
      ),
      child: const Center(child: Text("🌸", style: TextStyle(fontSize: 10))),
    );
  }

  Widget _buildPlayerLabel(Player player, int realIndex, {bool isRotated = false, int quarterTurns = 0}) {
    bool isCurrentTurn = (game.currentPlayerIndex == realIndex);
    bool isReceivingCard = isDealing && (currentlyDealingPlayerIndex == realIndex);
    bool isDealer = currentDealerName.isNotEmpty && (player.name.trim().toLowerCase() == currentDealerName.trim().toLowerCase());
    int wins = game.playerWinsMap[player.name] ?? 0;

    Widget textWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                const Text("🌸 ", style: TextStyle(fontSize: 10)),
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

  Widget _buildPlayerHandView(int realIndex, {bool isVertical = false}) {
    if (!cardsDealt) return const SizedBox.shrink();
    if (realIndex >= game.players.length) return const SizedBox.shrink();

    Player p = game.players[realIndex];
    bool isCurrentTurn = (game.currentPlayerIndex == realIndex);

    bool isMyDevicePlayer = (widget.mode == GameMode.friend)
        ? (p.name.trim().toLowerCase() == widget.myPlayerName.trim().toLowerCase())
        : (realIndex == 0);

    List<int> displayHand = List.from(p.hand);

    if (widget.mode == GameMode.friend) {
      if (isMyDevicePlayer) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: displayHand.map((cardValue) {
              return _buildPlayingCard(
                value: cardValue,
                onTap: (isProcessingTurn || isCardFlying || !isCurrentTurn || !_isMyTurn) ? null : () => _handleCardTap(cardValue),
              );
            }).toList(),
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    bool shouldShowCards = isCurrentTurn && !game.isCardHiddenForPass;

    if (shouldShowCards) {
      if (isVertical) {
        return Column(
          children: displayHand.map((cardValue) {
            return _buildPlayingCard(
              value: cardValue,
              onTap: (isProcessingTurn || isCardFlying || !isCurrentTurn) ? null : () => _handleCardTap(cardValue),
            );
          }).toList(),
        );
      } else {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: displayHand.map((cardValue) {
              return _buildPlayingCard(
                value: cardValue,
                onTap: (isProcessingTurn || isCardFlying || !isCurrentTurn) ? null : () => _handleCardTap(cardValue),
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
      return const Scaffold(
        backgroundColor: Color(0xFF1B2A47),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    Player activePlayer = game.players[game.currentPlayerIndex % game.players.length];
    String dealerDisplayName = currentDealerName.isNotEmpty ? currentDealerName : game.players[0].name;

    int bottomIdx = _getRelativePlayerIndex(0);
    int rightIdx = _getRelativePlayerIndex(1);
    int topIdx = _getRelativePlayerIndex(2);
    int leftIdx = _getRelativePlayerIndex(3);

    return WillPopScope(
      onWillPop: _showExitDialog,
      child: Scaffold(
        backgroundColor: const Color(0xFF1B2A47),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                  const Text("100 Card Game", style: TextStyle(color: Colors.white, fontSize: 15)),
                  Text("Round/Baji: #${game.totalRoundsPlayed}", style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
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
                    icon: const Icon(Icons.history, color: Colors.amber),
                    onPressed: _showScoreHistoryDrawer,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "TARGET: ${game.targetScore}",
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
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
                const SizedBox(height: 25),
                if (game.players.length >= 3)
                  Column(
                    children: [
                      _buildPlayerLabel(game.players[topIdx], topIdx),
                      const SizedBox(height: 6),
                      _buildPlayerHandView(topIdx),
                    ],
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (game.players.length == 4)
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Column(
                          children: [
                            _buildPlayerLabel(game.players[leftIdx], leftIdx, isRotated: true, quarterTurns: 1),
                            const SizedBox(height: 6),
                            _buildPlayerHandView(leftIdx, isVertical: true),
                          ],
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                    Container(
                      width: 175,
                      height: 175,
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFF0F5132),
                            Color(0xFF06321D),
                          ],
                          radius: 0.8,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.shade600, width: 4),
                        boxShadow: const [
                          BoxShadow(color: Colors.black87, blurRadius: 12, spreadRadius: 2)
                        ],
                      ),
                      child: Center(
                        child: !isDealing && !cardsDealt
                            ? (_canCurrentPlayerDeal
                                ? ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                    ),
                                    icon: const Icon(Icons.style),
                                    label: const Text("DEAL CARDS", style: TextStyle(fontWeight: FontWeight.bold)),
                                    onPressed: _startDealingAnimation,
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Waiting for $dealerDisplayName to Deal...",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ))
                            : isDealing
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Dealing Cards...", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 38,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          color: Colors.pink.shade900,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amber, width: 2),
                                        ),
                                        child: const Center(child: Text("🌸", style: TextStyle(fontSize: 16))),
                                      ),
                                      const SizedBox(height: 6),
                                      Text("Card #$currentDealingCardIndex", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          ...List.generate(game.currentRoundCards.length, (index) {
                                            int cardVal = game.currentRoundCards[index];
                                            return Column(
                                              children: [
                                                _buildPlayingCard(value: cardVal),
                                                const SizedBox(height: 2),
                                                Text(
                                                  index < game.playedCardOwners.length ? game.playedCardOwners[index] : "",
                                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            );
                                          }),
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
                            _buildPlayerLabel(game.players[rightIdx], rightIdx, isRotated: true, quarterTurns: 3),
                            const SizedBox(height: 6),
                            _buildPlayerHandView(rightIdx, isVertical: true),
                          ],
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 25),
                _buildPlayerLabel(game.players[bottomIdx], bottomIdx),
                const SizedBox(height: 8),
                _buildPlayerHandView(bottomIdx),
                const Spacer(),
                if (game.warningMsg.isNotEmpty)
                  Container(
                    color: Colors.redAccent,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: Text(game.warningMsg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
            if (widget.mode != GameMode.offline && game.showFirstTurnDialog)
              Container(
                color: Colors.black54,
                child: AlertDialog(
                  title: const Text("Lowest Card Rule"),
                  content: Text(game.firstTurnNotice),
                  actions: [
                    ElevatedButton(
                      child: const Text("Start Turn"),
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
                    const Text("🃏 Baji Khatam! 🃏", style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Text("Target score (${game.targetScore}) abhi tak kisi ne hit nahi kiya.", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 25),
                    if (_canCurrentPlayerDeal || widget.isHost)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        ),
                        icon: const Icon(Icons.style, color: Colors.white),
                        label: const Text("AGLI BAJI DEAL KAREIN", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          if (widget.mode == GameMode.friend && widget.roomCode.isNotEmpty) {
                            DataSnapshot snap = await _dbRef.child("rooms").child(widget.roomCode).get();
                            int currentDealer = 0;
                            int totalP = game.players.length;

                            if (snap.exists && snap.value != null) {
                              Map data = Map<dynamic, dynamic>.from(snap.value as Map);
                              currentDealer = data['currentDealerIndex'] ?? 0;
                            }

                            int nextDealer = (currentDealer + 1) % (totalP > 0 ? totalP : 1);

                            await _dbRef.child("rooms").child(widget.roomCode).update({
                              "currentDealerIndex": nextDealer,
                              "cardsDealt": false,
                              "isBajiFinished": false,
                              "tableCards": [],
                              "tableOwners": [],
                            });
                          }
                          setState(() {
                            game.dealNewDeck();
                            cardsDealt = false;
                          });
                        },
                      )
                    else
                      Column(
                        children: [
                          const CircularProgressIndicator(color: Colors.amber),
                          const SizedBox(height: 15),
                          Text(
                            "Waiting for $dealerDisplayName to Deal Cards...",
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            if (widget.mode == GameMode.offline && game.isCardHiddenForPass && game.winnerName.isEmpty && !game.isDeckFinished && !isCardFlying)
              Container(
                color: Colors.black87,
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (game.lastRoundWinnerMsg.isNotEmpty) ...[
                      Text(game.lastRoundWinnerMsg, style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 25),
                    ],
                    const Text("Pass Phone to:", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text("Turn: ${activePlayer.name}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.amberAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text("NEXT TURN / CONTINUE", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("🎆 👑 🎆", style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 10),
                    Text("🎉 ${game.winnerName} WINS THE MATCH! 🎉", style: const TextStyle(color: Colors.yellow, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    const Text("Congratulations! Champion of 100 Card Game!", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                      child: const Text("BACK TO MENU", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        _showInterstitialAd(onAdDismissed: () {
                          Navigator.pop(context);
                        });
                      },
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
