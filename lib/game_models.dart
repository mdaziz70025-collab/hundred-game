enum GameMode { online, offline }

class Player {
  final String id;
  final String name;
  List<int> hand;
  int currentScore;

  Player({
    required this.id,
    required this.name,
    required this.hand,
    this.currentScore = 0,
  });
}
