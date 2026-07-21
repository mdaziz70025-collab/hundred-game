enum GameMode { offline, online }

class Player {
  final String id;
  String name;
  String avatar;
  List<int> hand;
  int currentScore;

  Player({
    required this.id,
    required this.name,
    this.avatar = "👑",
    required this.hand,
    this.currentScore = 0,
  });
}

class UserProfile {
  String name;
  String avatar;
  int totalMatches;
  int totalWins;
  int xp;
  int level;
  int highScore;

  UserProfile({
    this.name = "Guest Player",
    this.avatar = "👑",
    this.totalMatches = 0,
    this.totalWins = 0,
    this.xp = 0,
    this.level = 1,
    this.highScore = 0,
  });

  double get winRate => totalMatches > 0 ? ((totalWins / totalMatches) * 100) : 0.0;
}
