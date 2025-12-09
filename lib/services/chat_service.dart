import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns a stream of messages for a given group, ordered by createdAt ascending.
  Stream<List<ChatMessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection('group_messages')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ChatMessageModel.fromMap(d.data())).toList(),
        );
  }

  /// Sends a new message to the group's chat.
  Future<void> sendGroupMessage(ChatMessageModel message) async {
    await _firestore
        .collection('group_messages')
        .doc(message.id)
        .set(message.toMap());
  }
}
