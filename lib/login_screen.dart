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
  
  bool isFirstRound = true; // Pehle round ke 5 card rule ke liye

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
    List<int> deck = List.generate(20, (i) => (i + 1) * 5); // [5, 10, 15 ... 100]

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

  // 1. PEHLA TURN: Jiske paas 5 number hoga wahi pehle chalega
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
    firstTurnNotice = "${players[startingIndex].name} ke paas $lowestCard number card hai! Pehla card $lowestCard inhi ko chalna hoga.";
    showFirstTurnDialog = true;
  }

  void playCard(int cardValue) {
    Player current = players[currentPlayerIndex];

    // Pehli baji me 5 number compulsory hona chahiye agar paas me hai
    if (isFirstRound && current.hand.contains(5) && cardValue != 5) {
      return; 
    }
    if (isFirstRound && totalPlayers == 3 && current.hand.contains(15) && cardValue != 15) {
      return;
    }

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

  // 2. BAJI JEETNE WALA AGLA TURN CHALEGA
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
    lastRoundWinnerMsg = "🎉 ${players[winnerIndex].name} won the baji (+${roundPoints} pts)! Ab inka turn hai.";

    if (players[winnerIndex].currentScore >= targetScore) {
      winnerName = players[winnerIndex].name;
    }

    // Winner ko agla turn diya jata hai
    currentPlayerIndex = winnerIndex;
    isFirstRound = false; // Pehla round khatam
    currentRoundCards.clear();
    playedCardOwners.clear();
    
    if (mode == GameMode.offline) {
      isCardHiddenForPass = true;
    }
  }
}
