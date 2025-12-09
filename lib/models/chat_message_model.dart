import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String groupId;
  final String fromUser;
  final String text;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.groupId,
    required this.fromUser,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'fromUser': fromUser,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      fromUser: map['fromUser'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
