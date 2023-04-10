class Session {
  final int id;

  Session({required this.id});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }

  @override
  String toString() {
    return 'Session{id: $id}';
  }

  static Session fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
    );
  }
}
