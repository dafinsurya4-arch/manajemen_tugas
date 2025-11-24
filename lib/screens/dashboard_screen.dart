import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';
import '../services/group_service.dart';
import '../models/group_model.dart';

// Simple chart data model used by the dashboard charts.
class ChartData {
  final String x;
  final int y;
  final Color color;

  ChartData(this.x, this.y, this.color);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  // Static caches persist across widget rebuilds while the app runs.
  static List<TaskModel>? _cachedTasks;
  static List<GroupModel>? _cachedGroups;
  bool _initialLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Start background cache population if needed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCached());
  }

  Future<void> _ensureCached() async {
    if (_cachedTasks != null && _cachedGroups != null) return;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _initialLoading = true);
    try {
      final taskStream = Provider.of<TaskService>(
        context,
        listen: false,
      ).getRelevantTasks(currentUserId);
      final groupStream = Provider.of<GroupService>(
        context,
        listen: false,
      ).getGroupsForUser(currentUserId);

      // Prefer the first non-empty emission from each stream so we don't
      // accidentally cache an empty snapshot (which causes group tasks to
      // appear missing). Fall back to the immediate first emission if the
      // non-empty emission doesn't arrive within a short timeout.
      List<TaskModel> firstTasks;
      try {
        firstTasks = await taskStream
            .firstWhere((list) => list.isNotEmpty)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        firstTasks = await taskStream.first;
      }

      List<GroupModel> firstGroups;
      try {
        firstGroups = await groupStream
            .firstWhere((list) => list.isNotEmpty)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        firstGroups = await groupStream.first;
      }

      _cachedTasks = firstTasks;
      _cachedGroups = firstGroups;
    } catch (e) {
      // Ignore; we'll fall back to live streams in build.
      debugPrint('Dashboard cache populate error: $e');
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return Center(child: Text('Silakan login untuk melihat dashboard'));
    }

    // If we have cached data, render from it to avoid refetching.
    if (!_initialLoading && _cachedTasks != null && _cachedGroups != null) {
      return _buildFromData(_cachedTasks!, _cachedGroups!, currentUserId);
    }

    // Otherwise fall back to the original live stream builder which will
    // provide live updates.

    return StreamBuilder<List<TaskModel>>(
      stream: Provider.of<TaskService>(context).getRelevantTasks(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error memuat data',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        return StreamBuilder<List<GroupModel>>(
          stream: Provider.of<GroupService>(
            context,
          ).getGroupsForUser(currentUserId),
          builder: (context, gSnapshot) {
            final groups = gSnapshot.data ?? [];
            // Populate caches if not already set.
            _cachedTasks ??= tasks;
            _cachedGroups ??= groups;

            final List<TaskModel> individualTasks = [];

            for (var t in tasks) {
              if (t.groupId == null || t.groupId!.isEmpty) {
                individualTasks.add(t);
              }
            }

            final chartWidget = FutureBuilder<Map<String, int>>(
              future: Provider.of<TaskService>(
                context,
                listen: false,
              ).getTaskStatistics(currentUserId),
              builder: (context, statsSnap) {
                if (statsSnap.connectionState == ConnectionState.waiting ||
                    !statsSnap.hasData) {
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  );
                }

                final chartStats = statsSnap.data!;

                return Container(
                  height: 200,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    series: <CartesianSeries<ChartData, String>>[
                      ColumnSeries<ChartData, String>(
                        dataSource: [
                          ChartData(
                            'Selesai',
                            chartStats['completed'] ?? 0,
                            Colors.green,
                          ),
                          ChartData(
                            'Progress',
                            chartStats['inProgress'] ?? 0,
                            Colors.orange,
                          ),
                          ChartData(
                            'Tertunda',
                            chartStats['pending'] ?? 0,
                            Colors.red,
                          ),
                        ],
                        xValueMapper: (ChartData data, _) => data.x,
                        yValueMapper: (ChartData data, _) => data.y,
                        color: Color.fromRGBO(8, 142, 255, 1),
                        dataLabelSettings: DataLabelSettings(isVisible: true),
                      ),
                    ],
                  ),
                );
              },
            );

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUserId)
                        .snapshots(),
                    builder: (context, userSnap) {
                      final bool ready =
                          userSnap.hasData && userSnap.data!.exists;

                      final Widget content = ready
                          ? Builder(
                              builder: (ctx) {
                                final data = userSnap.data!.data();
                                String fullName = 'Pengguna';
                                if (data is Map<String, dynamic>) {
                                  fullName =
                                      (data['fullName'] as String?) ??
                                      'Pengguna';
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 32),
                                    Text(
                                      'Selamat Datang, $fullName!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Kelola tugas dan pantau progres anda dengan mudah',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 32),
                                  ],
                                );
                              },
                            )
                          : SizedBox(height: 32 + 24 + 32);

                      return AnimatedSwitcher(
                        duration: Duration(milliseconds: 250),
                        child: content,
                      );
                    },
                  ),
                  chartWidget,
                  Padding(
                    padding: EdgeInsets.zero,
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: Icon(Icons.refresh),
                          label: Text('Refresh Statistik'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        // Render group sections: for each group, listen to its
                        // specific task stream so group tasks appear on the
                        // dashboard even if they are not part of the user's
                        // personal/assigned task stream.
                        for (var g in groups)
                          _buildGroupSection(g, currentUserId),

                        // Individual tasks section
                        if (individualTasks.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Tugas Pribadi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        ...individualTasks.map(
                          (task) => Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(task.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task.description),
                                  SizedBox(height: 4),
                                  Text(
                                    'Deadline: ${_formatDate(task.deadline)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                tooltip: 'Ubah status',
                                icon: _getStatusChip(task.status),
                                onSelected: (value) async {
                                  final taskService = Provider.of<TaskService>(
                                    context,
                                    listen: false,
                                  );
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    await taskService.updateTaskStatus(
                                      task.id,
                                      value,
                                    );
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Status diperbarui'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Gagal memperbarui status: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'selesai',
                                    child: Text('Selesai'),
                                  ),
                                  PopupMenuItem(
                                    value: 'progres',
                                    child: Text('Progres'),
                                  ),
                                  PopupMenuItem(
                                    value: 'tertunda',
                                    child: Text('Tertunda'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _getStatusChip(String status) {
    Color color;
    switch (status) {
      case 'selesai':
        color = Colors.green;
        break;
      case 'progres':
        color = Colors.orange;
        break;
      case 'tertunda':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
    );
  }

  // Update the in-memory cached task status so the UI reflects changes
  // immediately when the dashboard is rendering from `_cachedTasks`.
  void _updateCachedTaskStatus(String taskId, String newStatus) {
    if (_cachedTasks == null) return;
    final idx = _cachedTasks!.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final old = _cachedTasks![idx];
    final updated = TaskModel(
      id: old.id,
      title: old.title,
      description: old.description,
      deadline: old.deadline,
      status: newStatus,
      collaboration: old.collaboration,
      userId: old.userId,
      groupId: old.groupId,
      assignedTo: old.assignedTo,
      createdBy: old.createdBy,
      createdAt: old.createdAt,
    );
    _cachedTasks![idx] = updated;
    if (mounted) setState(() {});
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildGroupSection(GroupModel group, String currentUserId) {
    return StreamBuilder<List<TaskModel>>(
      stream: Provider.of<TaskService>(context).getGroupTasks(group.id),
      builder: (context, snap) {
        final tasks = snap.data ?? [];
        // Only show tasks that have been "taken" by the current user.
        final visible = tasks
            .where((t) => t.assignedTo == currentUserId)
            .toList();
        if (visible.isEmpty) return SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Kelompok: ${group.name}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...visible.map(
              (task) => Card(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(task.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.description),
                      SizedBox(height: 4),
                      Text(
                        'Deadline: ${_formatDate(task.deadline)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Ubah status',
                    icon: _getStatusChip(task.status),
                    onSelected: (value) async {
                      final taskService = Provider.of<TaskService>(
                        context,
                        listen: false,
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await taskService.updateTaskStatus(task.id, value);
                        // Update local cache so the UI updates immediately
                        _updateCachedTaskStatus(task.id, value);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Status diperbarui')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Gagal memperbarui status: $e'),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'selesai', child: Text('Selesai')),
                      PopupMenuItem(value: 'progres', child: Text('Progres')),
                      PopupMenuItem(value: 'tertunda', child: Text('Tertunda')),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFromData(
    List<TaskModel> tasks,
    List<GroupModel> groups,
    String currentUserId,
  ) {
    final List<TaskModel> individualTasks = [];
    for (var t in tasks) {
      if (t.groupId == null || t.groupId!.isEmpty) {
        individualTasks.add(t);
      }
    }

    final chartWidget = FutureBuilder<Map<String, int>>(
      future: Provider.of<TaskService>(
        context,
        listen: false,
      ).getTaskStatistics(currentUserId),
      builder: (context, statsSnap) {
        if (statsSnap.connectionState == ConnectionState.waiting ||
            !statsSnap.hasData) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          );
        }

        final chartStats = statsSnap.data!;

        return Container(
          height: 200,
          padding: EdgeInsets.symmetric(vertical: 12),
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            series: <CartesianSeries<ChartData, String>>[
              ColumnSeries<ChartData, String>(
                dataSource: [
                  ChartData(
                    'Selesai',
                    chartStats['completed'] ?? 0,
                    Colors.green,
                  ),
                  ChartData(
                    'Progress',
                    chartStats['inProgress'] ?? 0,
                    Colors.orange,
                  ),
                  ChartData('Tertunda', chartStats['pending'] ?? 0, Colors.red),
                ],
                xValueMapper: (ChartData data, _) => data.x,
                yValueMapper: (ChartData data, _) => data.y,
                color: Color.fromRGBO(8, 142, 255, 1),
                dataLabelSettings: DataLabelSettings(isVisible: true),
              ),
            ],
          ),
        );
      },
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .snapshots(),
            builder: (context, userSnap) {
              final bool ready = userSnap.hasData && userSnap.data!.exists;

              final Widget content = ready
                  ? Builder(
                      builder: (ctx) {
                        final data = userSnap.data!.data();
                        String fullName = 'Pengguna';
                        if (data is Map<String, dynamic>) {
                          fullName =
                              (data['fullName'] as String?) ?? 'Pengguna';
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 32),
                            Text(
                              'Selamat Datang, $fullName!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Kelola tugas dan pantau progres anda dengan mudah',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 32),
                          ],
                        );
                      },
                    )
                  : SizedBox(height: 32 + 24 + 32);

              return AnimatedSwitcher(
                duration: Duration(milliseconds: 250),
                child: content,
              );
            },
          ),
          chartWidget,
          Padding(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh Statistik'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                // Render group sections using live group-specific streams.
                for (var g in groups) _buildGroupSection(g, currentUserId),

                // Individual tasks section
                if (individualTasks.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tugas Pribadi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                ...individualTasks.map(
                  (task) => Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.description),
                          SizedBox(height: 4),
                          Text(
                            'Deadline: ${_formatDate(task.deadline)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Ubah status',
                        icon: _getStatusChip(task.status),
                        onSelected: (value) async {
                          final taskService = Provider.of<TaskService>(
                            context,
                            listen: false,
                          );
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await taskService.updateTaskStatus(task.id, value);
                            // Update local cache so the UI updates immediately
                            _updateCachedTaskStatus(task.id, value);
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Status diperbarui')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Gagal memperbarui status: $e'),
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'selesai',
                            child: Text('Selesai'),
                          ),
                          PopupMenuItem(
                            value: 'progres',
                            child: Text('Progres'),
                          ),
                          PopupMenuItem(
                            value: 'tertunda',
                            child: Text('Tertunda'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
