enum GameMode { offline, vsComputer, online }

class CardModel {
  final int number;
  final String suit;

  CardModel({required this.number, required this.suit});

  Map<String, dynamic> toJson() => {
    'number': number,
    'suit': suit,
  };

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      number: json['number'] as int,
      suit: json['suit'] as String,
    );
  }
}

class Player {
  final String id;
  final String name;
  List<CardModel> hand;
  int currentScore;

  Player({
    required this.id,
    required this.name,
    required this.hand,
    this.currentScore = 0,
  });

  int get score => currentScore;
  set score(int val) => currentScore = val;
}
