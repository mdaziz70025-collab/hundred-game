import 'dart:math';
import 'game_models.dart';

class HundredGameLogic {
  final GameMode mode;
  final int totalPlayers;
  final int targetScore;

  List<Player> players = [];
  List<int> currentRoundCards = [];
  int currentPlayerIndex = 0;
  
  bool isCardHiddenForPass = false;
  String firstTurnNotice = "";
  bool showFirstTurnDialog = true;

  HundredGameLogic({
    required this.mode,
    required this.totalPlayers,
    required this.targetScore,
  });

  void startMatch(List<String> playerNames) {
    List<int> deck = List.generate(20, (i) => (i + 1) * 5);

    if (totalPlayers == 3) {
      deck.remove(5);
      deck.remove(10);
    }

    deck.shuffle(Random());

    players.clear();
    int cardsPerPlayer = (totalPlayers == 2) ? 10 : 5;

    for (int i = 0; i < totalPlayers; i++) {
      List<int> hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);
      hand.sort();
      players.add(Player(id: 'p_$i', name: playerNames[i], hand: hand));
    }

    determineFirstPlayer();
  }

  void determineFirstPlayer() {
    int lowestCard = 105;
    int startingIndex = 0;

    for (int i = 0; i < players.length; i++) {
      if (players[i].hand.contains(5)) {
        startingIndex = i;
        lowestCard = 5;
        break;
      } else if (totalPlayers == 3 && players[i].hand.contains(15)) {
        startingIndex = i;
        lowestCard = 15;
        break;
      }
    }

    currentPlayerIndex = startingIndex;
    firstTurnNotice = "${players[startingIndex].name} ke paas $lowestCard number card hai! Pehla turn inka hai.";
    showFirstTurnDialog = true;
  }

  void playCard(int cardValue) {
    Player current = players[currentPlayerIndex];
    current.hand.remove(cardValue);
    currentRoundCards.add(cardValue);

    if (currentRoundCards.length < totalPlayers) {
      currentPlayerIndex = (currentPlayerIndex + 1) % totalPlayers;
      if (mode == GameMode.offline) {
        isCardHiddenForPass = true;
      }
    } else {
      evaluateRoundWinner();
    }
  }

  void evaluateRoundWinner() {
    int highestCard = -1;
    int winnerIndex = -1;

    for (int i = 0; i < currentRoundCards.length; i++) {
      if (currentRoundCards[i] > highestCard) {
        highestCard = currentRoundCards[i];
        winnerIndex = i;
      }
    }

    int roundPoints = currentRoundCards.reduce((a, b) => a + b);
    players[winnerIndex].currentScore += roundPoints;

    currentPlayerIndex = winnerIndex;
    currentRoundCards.clear();
    
    if (mode == GameMode.offline) {
      isCardHiddenForPass = true;
    }
  }
}
