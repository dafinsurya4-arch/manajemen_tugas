import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String fromUser;
  final String toUser;
  final String? groupId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.fromUser,
    required this.toUser,
    this.groupId,
    required this.isRead,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'fromUser': fromUser,
      'toUser': toUser,
      'groupId': groupId,
      'isRead': isRead,
      // Store as Firestore Timestamp for consistency
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      fromUser: map['fromUser'] ?? '',
      toUser: map['toUser'] ?? '',
      groupId: map['groupId'],
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is DateTime
                ? map['createdAt'] as DateTime
                : DateTime.now()),
    );
  }
}
