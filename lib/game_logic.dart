import 'dart:math';
import 'game_models.dart';

class TableCard {
  final CardModel card;
  final int playerIndex;

  TableCard({required this.card, required this.playerIndex});
}

class GameLogic {
  final int totalPlayers;
  final int targetScore;
  final List<String> playerNames;

  List<Player> players = [];
  int currentPlayerIndex = 0;
  List<TableCard> tableCards = [];
  bool isGameOver = false;
  String? winnerName;
  int roundNumber = 0;

  GameLogic({
    required this.totalPlayers,
    required this.targetScore,
    required this.playerNames,
  }) {
    _startNewRound();
  }

  void _startNewRound() {
    roundNumber++;
    List<String> suits = ['♠️', '♥️', '♦️', '♣️'];
    Random rng = Random();

    List<CardModel> fullDeck = [];
    int startVal = (totalPlayers == 3) ? 15 : 5;

    for (int v = startVal; v <= 100; v += 5) {
      String suit = suits[rng.nextInt(suits.length)];
      fullDeck.add(CardModel(number: v, suit: suit));
    }

    fullDeck.shuffle(rng);

    int cardsPerPlayer = 5;
    if (totalPlayers == 2) cardsPerPlayer = 10;
    if (totalPlayers == 3) cardsPerPlayer = 6;

    players = List.generate(
      totalPlayers,
      (i) => Player(
        id: "p_$i",
        name: playerNames.length > i ? playerNames[i] : "Player ${i + 1}",
        hand: [],
        currentScore: players.length > i ? players[i].currentScore : 0,
        wins: players.length > i ? players[i].wins : 0,
      ),
    );

    int cardIndex = 0;
    for (int i = 0; i < totalPlayers; i++) {
      for (int c = 0; c < cardsPerPlayer; c++) {
        if (cardIndex < fullDeck.length) {
          players[i].hand.add(fullDeck[cardIndex++]);
        }
      }
      players[i].hand.sort((a, b) => a.number.compareTo(b.number));
    }

    int startingPlayer = 0;
    int lowestFound = 999;
    int targetOpeningCard = (totalPlayers == 3) ? 15 : 5;

    for (int i = 0; i < totalPlayers; i++) {
      for (var card in players[i].hand) {
        if (card.number == targetOpeningCard) {
          startingPlayer = i;
          lowestFound = card.number;
          break;
        } else if (card.number < lowestFound) {
          lowestFound = card.number;
          startingPlayer = i;
        }
      }
      if (lowestFound == targetOpeningCard) break;
    }

    currentPlayerIndex = startingPlayer;
    tableCards.clear();
  }

  void playCard(CardModel card) {
    Player current = players[currentPlayerIndex];
    current.hand.removeWhere((c) => c.number == card.number);
    tableCards.add(TableCard(card: card, playerIndex: currentPlayerIndex));

    if (tableCards.length == totalPlayers) {
      _evaluateRoundWinner();
    } else {
      currentPlayerIndex = (currentPlayerIndex + 1) % totalPlayers;
    }
  }

  void _evaluateRoundWinner() {
    TableCard highest = tableCards[0];
    int roundPoints = 0;

    for (var tc in tableCards) {
      roundPoints += tc.card.number;
      if (tc.card.number > highest.card.number) {
        highest = tc;
      }
    }

    int winnerIdx = highest.playerIndex;
    players[winnerIdx].currentScore += roundPoints;
    players[winnerIdx].wins += 1;

    if (players[winnerIdx].currentScore >= targetScore) {
      isGameOver = true;
      winnerName = players[winnerIdx].name;
    } else {
      tableCards.clear();
      if (players.any((p) => p.hand.isEmpty)) {
        _startNewRound();
      } else {
        currentPlayerIndex = winnerIdx;
      }
    }
  }
}
