enum GameMode { offline, online, friend }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'hand': hand,
      'currentScore': currentScore,
    };
  }

  factory Player.fromJson(Map<dynamic, dynamic> json) {
    return Player(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Player',
      avatar: json['avatar'] ?? '👑',
      hand: List<int>.from(json['hand'] ?? []),
      currentScore: json['currentScore'] ?? 0,
    );
  }
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

class RoundHistory {
  final int roundNumber;
  final String winnerName;
  final int points;

  RoundHistory({
    required this.roundNumber,
    required this.winnerName,
    required this.points,
  });
}
