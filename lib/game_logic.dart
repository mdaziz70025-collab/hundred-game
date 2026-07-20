import 'dart:math';
import 'game_models.dart';

class RoundHistory {
  final int roundNumber;
  final String winnerName;
  final int points;
  RoundHistory({required this.roundNumber, required this.winnerName, required this.points});
}

class HundredGameLogic {
  final GameMode mode;
  final int totalPlayers;
  final int targetScore;

  List<Player> players = [];
  List<int> currentRoundCards = [];
  List<String> playedCardOwners = [];
  int currentPlayerIndex = 0;
  
  int totalRoundsPlayed = 0;
  Map<String, int> playerWinsMap = {};
  List<RoundHistory> roundHistoryList = []; // SCORE HISTORY LOG

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
    playerWinsMap.clear();
    roundHistoryList.clear();
    totalRoundsPlayed = 0;

    for (int i = 0; i < totalPlayers; i++) {
      players.add(Player(id: 'p_$i', name: playerNames[i], hand: []));
      playerWinsMap[playerNames[i]] = 0;
    }
    dealNewDeck();
  }

  void dealNewDeck() {
    isDeckFinished = false;
    isFirstRound = true;
    showFirstTurnDialog = false;
    currentRoundCards.clear();
    playedCardOwners.clear();

    List<int> deck = List.generate(20, (i) => (i + 1) * 5);

    if (totalPlayers == 3) {
      deck.remove(5);
      deck.remove(10);
    }

    var rng = Random.secure();
    deck.shuffle(rng);
    deck.shuffle(rng);

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
    totalRoundsPlayed++;
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
      String winnerNameStr = players[winningCardOwnerIndex].name;
      players[winningCardOwnerIndex].currentScore += roundPoints;
      
      playerWinsMap[winnerNameStr] = (playerWinsMap[winnerNameStr] ?? 0) + 1;
      
      // Add to History Log
      roundHistoryList.add(RoundHistory(
        roundNumber: totalRoundsPlayed,
        winnerName: winnerNameStr,
        points: roundPoints,
      ));

      lastRoundWinnerMsg = "🎉 $winnerNameStr won Baji #${totalRoundsPlayed} (+${roundPoints} pts)!";

      if (players[winningCardOwnerIndex].currentScore >= targetScore) {
        winnerName = winnerNameStr;
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
