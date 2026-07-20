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
  bool showFirstTurnDialog = false;
  String lastRoundWinnerMsg = "";
  String winnerName = "";
  String warningMsg = "";
  
  bool isFirstRound = true;
  bool isDeckFinished = false;

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
    players.clear();
    for (int i = 0; i < totalPlayers; i++) {
      players.add(Player(id: 'p_$i', name: playerNames[i], hand: []));
    }
    dealNewDeck();
  }

  // ENHANCED RANDOM DECK DEALING
  void dealNewDeck() {
    isDeckFinished = false;
    isFirstRound = true;
    showFirstTurnDialog = false;
    currentRoundCards.clear();
    playedCardOwners.clear();

    List<int> deck = List.generate(20, (i) => (i + 1) * 5); // [5, 10, 15 ... 100]

    if (totalPlayers == 3) {
      deck.remove(5);
      deck.remove(10);
    }

    // High Quality Random Shuffle (Multiple passes to break bias)
    var rng = Random.secure();
    deck.shuffle(rng);
    deck.shuffle(rng); // Extra shuffle for fair distribution

    int cardsPerPlayer = (totalPlayers == 2) ? 10 : (totalPlayers == 3 ? 6 : 5);

    for (int i = 0; i < totalPlayers; i++) {
      List<int> hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);
      hand.sort();
      players[i].hand = hand;
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
    firstTurnNotice = "${players[startingIndex].name} ke paas $lowestCard number card gaya hai! Pehla turn inka hai.";
  }

  void revealFirstTurnDialog() {
    showFirstTurnDialog = true;
  }

  void playCard(int cardValue) {
    warningMsg = "";
    Player current = players[currentPlayerIndex];

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
    int winningCardOwnerIndex = -1;

    for (int i = 0; i < currentRoundCards.length; i++) {
      if (currentRoundCards[i] > highestCard) {
        highestCard = currentRoundCards[i];
        String ownerName = playedCardOwners[i];
        winningCardOwnerIndex = players.indexWhere((p) => p.name == ownerName);
      }
    }

    int roundPoints = 0;
    for (int card in currentRoundCards) {
      roundPoints += calculateCardPoints(card);
    }

    if (winningCardOwnerIndex != -1) {
      players[winningCardOwnerIndex].currentScore += roundPoints;
      lastRoundWinnerMsg = "🎉 ${players[winningCardOwnerIndex].name} won the baji (+${roundPoints} pts)!";

      if (players[winningCardOwnerIndex].currentScore >= targetScore) {
        winnerName = players[winningCardOwnerIndex].name;
      }

      currentPlayerIndex = winningCardOwnerIndex;
    }

    isFirstRound = false;
    currentRoundCards.clear();
    playedCardOwners.clear();

    bool allHandsEmpty = players.every((p) => p.hand.isEmpty);
    if (allHandsEmpty && winnerName.isEmpty) {
      isDeckFinished = true;
    } else if (mode == GameMode.offline) {
      isCardHiddenForPass = true;
    }
  }
}
