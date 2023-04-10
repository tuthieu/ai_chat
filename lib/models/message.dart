enum Sender { me, ai }

class Message {
  final int id;
  final int sessionId;
  final String content;
  final Sender sender;
  final DateTime time;

  Message(
      {required this.id,
      required this.sessionId,
      required this.content,
      required this.sender,
      required this.time});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'content': content,
      'sender': sender.index,
      'time': time.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'Message{id: $id, sessionId: $sessionId, content: $content, sender: $sender, time: $time}';
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      sessionId: map['sessionId'],
      content: map['content'],
      sender: Sender.values[map['sender']],
      time: DateTime.fromMillisecondsSinceEpoch(map['time']),
    );
  }
}
