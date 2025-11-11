import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TaskModel>> getPersonalTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('collaboration', isEqualTo: 'individu')
        // Sementara hapus orderBy sampai index aktif
        // .orderBy('deadline')
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data()))
              .toList();

          // Sorting di memory sementara
          tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
          return tasks;
        });
  }

  Stream<List<TaskModel>> getGroupTasks(String groupId) {
    return _firestore
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        // Sementara hapus orderBy
        // .orderBy('deadline')
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data()))
              .toList();

          tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
          return tasks;
        });
  }

  Stream<List<TaskModel>> getAssignedTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        // Sementara hapus orderBy
        // .orderBy('deadline')
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data()))
              .toList();

          tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
          return tasks;
        });
  }

  /// Stream that merges personal tasks (owned by user) and tasks assigned to the user.
  /// Emits a de-duplicated list ordered by deadline.
  Stream<List<TaskModel>> getRelevantTasks(String userId) {
    final personal = getPersonalTasks(userId);
    final assigned = getAssignedTasks(userId);

    // We'll merge the two streams by listening to both and emitting combined lists.
    StreamController<List<TaskModel>> controller = StreamController.broadcast();

    List<TaskModel> lastPersonal = [];
    List<TaskModel> lastAssigned = [];

    void emitMerged() {
      final Map<String, TaskModel> map = {};
      for (var t in lastPersonal) map[t.id] = t;
      for (var t in lastAssigned) map[t.id] = t;
      final merged = map.values.toList();
      merged.sort((a, b) => a.deadline.compareTo(b.deadline));
      controller.add(merged);
    }

    final sub1 = personal.listen((list) {
      lastPersonal = list;
      emitMerged();
    }, onError: (e) => controller.addError(e));

    final sub2 = assigned.listen((list) {
      lastAssigned = list;
      emitMerged();
    }, onError: (e) => controller.addError(e));

    controller.onCancel = () async {
      await sub1.cancel();
      await sub2.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  // Method untuk mendapatkan statistik tugas tanpa complex query
  Future<Map<String, int>> getTaskStatistics(String userId) async {
    try {
      final personalTasks = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .where('collaboration', isEqualTo: 'individu')
          .get();

      final assignedTasks = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .get();

      // Gabungkan semua tugas
      final allTasks = [
        ...personalTasks.docs.map((doc) => TaskModel.fromMap(doc.data())),
        ...assignedTasks.docs.map((doc) => TaskModel.fromMap(doc.data())),
      ];

      // Hitung statistik
      int completed = allTasks.where((task) => task.status == 'selesai').length;
      int inProgress = allTasks
          .where((task) => task.status == 'progres')
          .length;
      int pending = allTasks.where((task) => task.status == 'tertunda').length;

      return {
        'completed': completed,
        'inProgress': inProgress,
        'pending': pending,
      };
    } catch (e) {
      print('Error getting task statistics: $e');
      return {'completed': 0, 'inProgress': 0, 'pending': 0};
    }
  }

  Future<void> addTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toMap());
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _firestore.collection('tasks').doc(taskId).update({'status': status});
  }

  /// Assign a task to a user. If [assigneeId] is null, the task will be unassigned.
  Future<void> updateTaskAssignment(String taskId, String? assigneeId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'assignedTo': assigneeId,
      // Optionally set status to 'progres' when assigned and to 'tertunda' when unassigned
      'status': assigneeId != null ? 'progres' : 'tertunda',
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }
}
