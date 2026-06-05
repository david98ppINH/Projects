class PlayerLead {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String identificacion;
  int score;
  final String gameType;
  final String timestamp;

  PlayerLead({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.identificacion,
    required this.score,
    required this.gameType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'identificacion': identificacion,
      'score': score,
      'gameType': gameType,
      'timestamp': timestamp,
    };
  }

  factory PlayerLead.fromJson(Map<String, dynamic> json) {
    return PlayerLead(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      identificacion: json['identificacion'] as String,
      score: json['score'] as int,
      gameType: json['gameType'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  PlayerLead copyWith({int? newScore}) {
    return PlayerLead(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      identificacion: identificacion,
      score: newScore ?? score,
      gameType: gameType,
      timestamp: timestamp,
    );
  }
}
