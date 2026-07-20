import 'dart:math';
import 'game_models.dart';

class HundredGameLogic {
  final GameMode mode;
  final int totalPlayers;
  final int targetScore;

  List<Player> players = [];
  List<int> currentRoundCards = [];
  List<String> playedCardOwners = [];
  int currentPlayerIndex = 0;
  
  bool isCardHiddenForPass = false;
  String firstTurnNotice = "";
  bool showFirstTurnDialog = true;
  String lastRoundWinnerMsg = "";
  String winnerName = "";

  HundredGameLogic({
    required this.mode,
    required this.totalPlayers,
    required this.targetScore,
  });

  // GRAND TOTAL 100-POINT SCORING FORMULA:
  // 5=0 | 10=1, 15=1 | 20=2, 25=2 ... 90=9, 95=9 | 100=10 (Total Sum = 100 Pts)
  int calculateCardPoints(int cardValue) {
    if (cardValue == 5) return 0;
    return cardValue ~/ 10;
  }

  void startMatch(List<String> playerNames) {
    List<int> deck = List.generate(20, (i) => (i + 1) * 5); // [5, 10, 15 ... 100]

    // 3 Players Rule: 5 aur 10 remove ho jaate hain
    if (totalPlayers == 3) {
      deck.remove(5);
      deck.remove(10);
    }

    deck.shuffle(Random());

    players.clear();
    int cardsPerPlayer = (totalPlayers == 2) ? 10 : (totalPlayers == 3 ? 6 : 5);

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
    playedCardOwners.add(current.name);

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

    // Pehle digit ke basis par scoring sum
    int roundPoints = 0;
    for (int card in currentRoundCards) {
      roundPoints += calculateCardPoints(card);
    }

    players[winnerIndex].currentScore += roundPoints;
    lastRoundWinnerMsg = "🎉 ${players[winnerIndex].name} won the baji (+${roundPoints} pts)!";

    if (players[winnerIndex].currentScore >= targetScore) {
      winnerName = players[winnerIndex].name;
    }

    currentPlayerIndex = winnerIndex;
    currentRoundCards.clear();
    playedCardOwners.clear();
    
    if (mode == GameMode.offline) {
      isCardHiddenForPass = true;
    }
  }
}
