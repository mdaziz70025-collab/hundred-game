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
  String warningMsg = "";
  
  bool isFirstRound = true;

  HundredGameLogic({
    required this.mode,
    required this.totalPlayers,
    required this.targetScore,
  });

  int calculateCardPoints(int cardValue) {
    if (cardValue == 5) return 0;
    return cardValue ~/ 10;
  }

  void startMatch(List<String> playerNames) {
    List<int> deck = List.generate(20, (i) => (i + 1) * 5);

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
    firstTurnNotice = "${players[startingIndex].name} ke paas $lowestCard number card hai! Pehla card $lowestCard hi chalna compulsory hai.";
    showFirstTurnDialog = true;
  }

  void playCard(int cardValue) {
    warningMsg = "";
    Player current = players[currentPlayerIndex];

    // 1. RULE: Pehli baji me sabse chhota card (5 ya 15) hi chalna padega
    if (isFirstRound) {
      if (current.hand.contains(5) && cardValue != 5) {
        warningMsg = "Pehle 5 number card hi chalna hoga!";
        return; 
      }
      if (totalPlayers == 3 && current.hand.contains(15) && cardValue != 15) {
        warningMsg = "Pehle 15 number card hi chalna hoga!";
        return;
      }
    }

    // Bada card compulsory rule
    if (currentRoundCards.isNotEmpty) {
      int highestOnTable = currentRoundCards.reduce(max);
      bool hasHigherCard = current.hand.any((c) => c > highestOnTable);

      if (hasHigherCard && cardValue < highestOnTable) {
        warningMsg = "Aapke paas $highestOnTable se bada card hai, chhota nahi chal sakte!";
        return;
      }
    }

    current.hand.remove(cardValue);
    currentRoundCards.add(cardValue);
    playedCardOwners.add(current.name);

    if (currentRoundCards.length < totalPlayers) {
      currentPlayerIndex = (currentPlayerIndex + 1) % totalPlayers;
      if (mode == GameMode.offline) {
        isCardHiddenForPass = true;
      }
      checkAutoPlayLastCard();
    } else {
      evaluateRoundWinner();
    }
  }

  void checkAutoPlayLastCard() {
    bool allHaveOneCard = players.every((p) => p.hand.length == 1);
    if (allHaveOneCard && currentRoundCards.length < totalPlayers) {
      Player current = players[currentPlayerIndex];
      if (current.hand.isNotEmpty) {
        int autoCard = current.hand.first;
        playCard(autoCard);
      }
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
    isFirstRound = false;
    currentRoundCards.clear();
    playedCardOwners.clear();
    
    // Baji khatam hote hi Next Baji option aayega
    isCardHiddenForPass = true;
  }
}
