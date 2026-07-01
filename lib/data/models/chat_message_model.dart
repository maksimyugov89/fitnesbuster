import 'dart:convert';
import 'package:fitnesbuster/domain/entities/chat_message.dart';

class ChatMessageModel {
  final String role;
  final String content;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessageModel.fromEntity(ChatMessage entity) => ChatMessageModel(
    role: entity.role,
    content: entity.content,
    timestamp: entity.timestamp,
  );

  ChatMessage toEntity() =>
      ChatMessage(role: role, content: content, timestamp: timestamp);

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) => ChatMessageModel(
    role: j['role'] as String,
    content: j['content'] as String,
    timestamp: DateTime.parse(j['timestamp'] as String),
  );

  static String encodeList(List<ChatMessage> messages) => jsonEncode(
    messages.map((m) => ChatMessageModel.fromEntity(m).toJson()).toList(),
  );

  static List<ChatMessage> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) =>
              ChatMessageModel.fromJson(e as Map<String, dynamic>).toEntity(),
        )
        .toList();
  }
}
