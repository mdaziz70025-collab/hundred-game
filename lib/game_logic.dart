import 'game_models.dart';

class TableCard {
  final CardModel card;
  final int playerIndex;

  TableCard({required this.card, required this.playerIndex});
}

class GameLogic {
  final GameMode mode;
  final int totalPlayers;
  final int targetScore;
  final List<String> playerNames;

  List<Player> players = [];
  int currentPlayerIndex = 0;
  List<TableCard> tableCards = [];
  bool isGameOver = false;
  String? winnerName;

  GameLogic({
    required this.mode,
    required this.totalPlayers,
    required this.targetScore,
    required this.playerNames,
  }) {
    _startNewRound();
  }

  void _startNewRound() {
    List<String> suits = ['♠️', '♥️', '♦️', '♣️'];
    players = List.generate(
      totalPlayers,
      (i) => Player(
        id: "p_$i",
        name: playerNames.length > i ? playerNames[i] : "Player ${i + 1}",
        hand: [],
        currentScore: players.length > i ? players[i].currentScore : 0,
      ),
    );

    int cardNum = 1;
    int pIdx = 0;
    while (cardNum <= 100) {
      for (String suit in suits) {
        if (cardNum > 100) break;
        players[pIdx].hand.add(CardModel(number: cardNum, suit: suit));
        pIdx = (pIdx + 1) % totalPlayers;
        cardNum++;
      }
    }

    for (var player in players) {
      player.hand.sort((a, b) => a.number.compareTo(b.number));
    }

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

    if (players[winnerIdx].currentScore >= targetScore) {
      isGameOver = true;
      winnerName = players[winnerIdx].name;
    } else {
      tableCards.clear();
      currentPlayerIndex = winnerIdx;
    }
  }
}
