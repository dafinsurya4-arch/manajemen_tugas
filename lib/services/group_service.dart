import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/notification_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<GroupModel>> getUserGroups(List<String> groupIds) {
    if (groupIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('groups')
        .where('id', whereIn: groupIds)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> createGroup(GroupModel group) async {
    // Create group document
    await _firestore.collection('groups').doc(group.id).set(group.toMap());

    // Add group id to leader's user document so getUserGroups can find it
    try {
      await _firestore.collection('users').doc(group.leader).update({
        'groups': FieldValue.arrayUnion([group.id]),
      });
    } catch (e) {
      // If update fails (e.g., user doc not found), attempt to create/merge the field
      await _firestore.collection('users').doc(group.leader).set({
        'groups': [group.id],
      }, SetOptions(merge: true));
    }
  }

  Future<bool> inviteUser(
    String groupId,
    String leaderId,
    String userEmail,
  ) async {
    // Cari user berdasarkan email
    var userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .get();

    if (userQuery.docs.isNotEmpty) {
      var toUser = userQuery.docs.first;
      NotificationModel notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'group_invitation',
        title: 'Undangan Bergabung ke Grup',
        message: 'Anda diundang untuk bergabung ke dalam grup',
        fromUser: leaderId,
        toUser: toUser.id,
        groupId: groupId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
      return true;
    }

    return false;
  }

  Future<void> acceptInvitation(
    String notificationId,
    String groupId,
    String userId,
  ) async {
    // Tambah user ke group
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });

    // Update user groups
    await _firestore.collection('users').doc(userId).update({
      'groups': FieldValue.arrayUnion([groupId]),
    });

    // Hapus notifikasi
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  Future<void> rejectInvitation(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  Future<void> removeMember(
    String groupId,
    String userId, {
    bool deleteAssignedTasks = false,
  }) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });

    await _firestore.collection('users').doc(userId).update({
      'groups': FieldValue.arrayRemove([groupId]),
    });
    // Unassign or delete tasks that were assigned to the user in this group depending on `deleteAssignedTasks` flag.
    // - If `deleteAssignedTasks == false` (default): set `assignedTo` to null and `status` to 'tertunda'.
    // - If `deleteAssignedTasks == true`: delete the task documents entirely.
    try {
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('groupId', isEqualTo: groupId)
          .where('assignedTo', isEqualTo: userId)
          .get();
      if (tasksSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in tasksSnapshot.docs) {
          if (deleteAssignedTasks) {
            batch.delete(doc.reference);
          } else {
            batch.update(doc.reference, {
              'assignedTo': null,
              'status': 'tertunda',
            });
          }
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error unassigning tasks after removeMember: $e');
    }
  }

  Future<void> leaveGroup(
    String groupId,
    String userId, {
    bool deleteAssignedTasks = false,
  }) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });

    await _firestore.collection('users').doc(userId).update({
      'groups': FieldValue.arrayRemove([groupId]),
    });
    // Unassign tasks assigned to this user within the group, revert status to tertunda.
    try {
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('groupId', isEqualTo: groupId)
          .where('assignedTo', isEqualTo: userId)
          .get();
      if (tasksSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in tasksSnapshot.docs) {
          if (deleteAssignedTasks) {
            batch.delete(doc.reference);
          } else {
            batch.update(doc.reference, {
              'assignedTo': null,
              'status': 'tertunda',
            });
          }
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error unassigning tasks on leaveGroup: $e');
    }
  }

  /// Stream groups where the given user is a member.
  Stream<List<GroupModel>> getGroupsForUser(String userId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromMap(doc.data()))
              .toList(),
        );
  }
}
