import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<MessageModel>> streamMessages(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MessageModel.fromMap(d.data())).toList(),
        );
  }

  Future<void> sendMessage(String groupId, MessageModel message) async {
    final ref = _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(message.id);
    await ref.set(message.toMap());
  }
}
