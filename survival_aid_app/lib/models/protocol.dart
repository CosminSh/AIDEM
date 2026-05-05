class Branch {
  final String label;
  final String target;

  Branch({required this.label, required this.target});

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      label: json['label'] as String,
      target: json['target'] as String,
    );
  }
}

class ProtocolNode {
  final String id;
  final String question;
  final String? source;
  final bool gpsContext;
  final List<Branch> branches;

  ProtocolNode({
    required this.id,
    required this.question,
    this.source,
    required this.gpsContext,
    required this.branches,
  });

  factory ProtocolNode.fromJson(Map<String, dynamic> json) {
    return ProtocolNode(
      id: json['id'] as String,
      question: json['question'] as String,
      source: json['source'] as String?,
      gpsContext: json['gps_context'] as bool? ?? false,
      branches: (json['branches'] as List<dynamic>?)
              ?.map((e) => Branch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

enum MessageAuthor { ai, user }

class ChatMessage {
  final String text;
  final String? imagePath;
  final MessageAuthor author;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    this.imagePath,
    required this.author,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'imagePath': imagePath,
        'author': author.index,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] as String,
        imagePath: json['imagePath'] as String?,
        author: MessageAuthor.values[json['author'] as int],
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
