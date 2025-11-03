import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final String status; // 'selesai', 'progres', 'tertunda'
  final String collaboration; // 'individu', 'kelompok'
  final String userId;
  final String? groupId;
  final String? assignedTo;
  final String createdBy;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.status,
    required this.collaboration,
    required this.userId,
    this.groupId,
    this.assignedTo,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      // Store as Firestore Timestamp for consistency
      'deadline': Timestamp.fromDate(deadline),
      'status': status,
      'collaboration': collaboration,
      'userId': userId,
      'groupId': groupId,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      // Support both Timestamp and DateTime values coming from Firestore
      deadline: map['deadline'] is Timestamp
          ? (map['deadline'] as Timestamp).toDate()
          : (map['deadline'] is DateTime ? map['deadline'] as DateTime : DateTime.now()),
      status: map['status'] ?? 'tertunda',
      collaboration: map['collaboration'] ?? 'individu',
      userId: map['userId'] ?? '',
      groupId: map['groupId'],
      assignedTo: map['assignedTo'],
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is DateTime ? map['createdAt'] as DateTime : DateTime.now()),
    );
  }
}