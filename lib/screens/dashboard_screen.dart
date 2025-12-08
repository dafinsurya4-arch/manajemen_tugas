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

class _DashboardScreenState extends State<DashboardScreen> {
<<<<<<< HEAD
  List<TaskModel>? _cachedTasks;
  List<GroupModel>? _cachedGroups;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
=======
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
>>>>>>> f2e3d166f6881b2d555229faf4872a27c63e8582

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return Center(child: Text('Harap masuk terlebih dahulu'));
    }

    final taskService = Provider.of<TaskService>(context, listen: false);
    final groupService = Provider.of<GroupService>(context, listen: false);

    return StreamBuilder<List<TaskModel>>(
<<<<<<< HEAD
      stream: taskService.getRelevantTasks(currentUserId),
      initialData: _cachedTasks ?? [],
      builder: (context, taskSnap) {
        _cachedTasks = taskSnap.data ?? _cachedTasks ?? [];
        return StreamBuilder<List<GroupModel>>(
          stream: groupService.getGroupsForUser(currentUserId),
          initialData: _cachedGroups ?? [],
          builder: (context, groupSnap) {
            _cachedGroups = groupSnap.data ?? _cachedGroups ?? [];
            return Scaffold(
              body: _buildFromData(
                _cachedTasks ?? [],
                _cachedGroups ?? [],
                currentUserId,
              ),
            );
=======
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

        // Filter tasks based on search query
        final filteredTasks = tasks.where((task) {
          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          return task.title.toLowerCase().contains(query) ||
              task.description.toLowerCase().contains(query);
        }).toList();

        // Compute statistics from the live task list so the chart stays in sync

        // Group tasks by groupId and build a grouped list. We need group names
        // for groupId values; fetch user's groups and build a map.
        return StreamBuilder<List<GroupModel>>(
          stream: Provider.of<GroupService>(
            context,
          ).getGroupsForUser(currentUserId),
          builder: (context, gSnapshot) {
            final groups = gSnapshot.data ?? [];
            final Map<String, String> groupNames = {
              for (var g in groups) g.id: g.name,
            };

            final Map<String, List<TaskModel>> groupTasks = {};
            final List<TaskModel> individualTasks = [];

            for (var t in filteredTasks) {
              if (t.groupId != null && t.groupId!.isNotEmpty) {
                groupTasks.putIfAbsent(t.groupId!, () => []).add(t);
              } else {
                individualTasks.add(t);
              }
            }

            final chartStats = {
              'completed': filteredTasks
                  .where((t) => t.status == 'selesai')
                  .length,
              'inProgress': filteredTasks
                  .where((t) => t.status == 'progres')
                  .length,
              'pending': filteredTasks
                  .where((t) => t.status == 'tertunda')
                  .length,
            };

            final chartWidget = Container(
              height: 200,
              padding: EdgeInsets.all(16),
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries<ChartData, String>>[
                  ColumnSeries<ChartData, String>(
                    dataSource: [
                      ChartData(
                        'Selesai',
                        chartStats['completed']!,
                        Colors.green,
                      ),
                      ChartData(
                        'Progress',
                        chartStats['inProgress']!,
                        Colors.orange,
                      ),
                      ChartData('Tertunda', chartStats['pending']!, Colors.red),
                    ],
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    color: Color.fromRGBO(8, 142, 255, 1),
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            );

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari tugas...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                chartWidget,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() {}),
                        icon: Icon(Icons.refresh),
                        label: Text('Refresh Statistik'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: filteredTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isEmpty
                                    ? Icons.task_alt
                                    : Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Belum ada tugas'
                                    : 'Tidak ada tugas yang cocok',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'dengan kata kunci "$_searchQuery"',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : ListView(
                          children: [
                            // Render group tasks sections
                            for (var entry in groupTasks.entries)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'Kelompok: ${groupNames[entry.key] ?? entry.key}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ...entry.value.map(
                                    (task) => Card(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      child: ListTile(
                                        title: Text(task.title),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            try {
                                              await Provider.of<TaskService>(
                                                context,
                                                listen: false,
                                              ).updateTaskStatus(
                                                task.id,
                                                value,
                                              );
                                              if (mounted)
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Status diperbarui',
                                                    ),
                                                  ),
                                                );
                                            } catch (e) {
                                              if (mounted)
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Gagal memperbarui status: $e',
                                                    ),
                                                  ),
                                                );
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

                            // Individual tasks section
                            if (individualTasks.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
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
                                margin: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  title: Text(task.title),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      try {
                                        await Provider.of<TaskService>(
                                          context,
                                          listen: false,
                                        ).updateTaskStatus(task.id, value);
                                        if (mounted)
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Status diperbarui',
                                              ),
                                            ),
                                          );
                                      } catch (e) {
                                        if (mounted)
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Gagal memperbarui status: $e',
                                              ),
                                            ),
                                          );
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
            );
>>>>>>> f2e3d166f6881b2d555229faf4872a27c63e8582
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

  // Note: previous function `_buildChartWithLabel` removed — we use `_buildChartFromTasks` instead.

  Widget _buildChartFromTasks(List<TaskModel> allTasks) {
    // Deduplicate tasks by id
    final Map<String, TaskModel> map = {};
    for (var t in allTasks) map[t.id] = t;
    final tasks = map.values.toList();

    final completed = tasks.where((t) => t.status == 'selesai').length;
    final inProgress = tasks.where((t) => t.status == 'progres').length;
    final pending = tasks.where((t) => t.status == 'tertunda').length;

    final chartStats = {
      'completed': completed,
      'inProgress': inProgress,
      'pending': pending,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
        ),
      ],
    );
  }

  // The chart now computes directly from the merged task list (live), see `_buildChartFromTasks`.

  // Helper to check whether a task matches the search query.
  bool _matchesSearch(TaskModel task) {
    if (_searchQuery.trim().isEmpty) return true;
    final q = _searchQuery.trim().toLowerCase();
    final title = task.title.toLowerCase();
    final desc = task.description.toLowerCase();
    return title.contains(q) || desc.contains(q);
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari tugas...',
            prefixIcon: Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
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

  void _updateCachedTask(TaskModel updated) {
    if (_cachedTasks == null) return;
    final idx = _cachedTasks!.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    _cachedTasks![idx] = updated;
    if (mounted) setState(() {});
  }

  void _removeCachedTask(String taskId) {
    if (_cachedTasks == null) return;
    _cachedTasks!.removeWhere((t) => t.id == taskId);
    if (mounted) setState(() {});
  }

  Future<void> _showEditTaskModal(TaskModel task) async {
    final titleCtrl = TextEditingController(text: task.title);
    final descriptionCtrl = TextEditingController(text: task.description);
    DateTime selectedDate = task.deadline;
    String status = task.status;

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx2, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Tugas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Judul',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: descriptionCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(
                      text:
                          '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Deadline',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx2,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'tertunda',
                        child: Text('Tertunda'),
                      ),
                      DropdownMenuItem(
                        value: 'progres',
                        child: Text('Dalam Progress'),
                      ),
                      DropdownMenuItem(
                        value: 'selesai',
                        child: Text('Selesai'),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => status = value ?? 'tertunda'),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final updated = TaskModel(
                              id: task.id,
                              title: titleCtrl.text,
                              description: descriptionCtrl.text,
                              deadline: selectedDate,
                              status: status,
                              collaboration: task.collaboration,
                              userId: task.userId,
                              groupId: task.groupId,
                              assignedTo: task.assignedTo,
                              createdBy: task.createdBy,
                              createdAt: task.createdAt,
                            );
                            try {
                              await Provider.of<TaskService>(
                                context,
                                listen: false,
                              ).updateTask(updated);
                              _updateCachedTask(updated);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Tugas diperbarui')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Gagal memperbarui tugas: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                            Navigator.pop(ctx);
                          },
                          child: Text('Simpan Perubahan'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDeleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Tugas'),
        content: Text('Apakah Anda yakin ingin menghapus tugas ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await Provider.of<TaskService>(
          context,
          listen: false,
        ).deleteTask(task.id);
        _removeCachedTask(task.id);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tugas dihapus')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus tugas: $e')));
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _refreshStats(String currentUserId) {
    // Force a UI refresh; chart will recompute from the latest stream values automatically.
    if (mounted) setState(() {});
  }

  Widget _buildGroupSection(GroupModel group, String currentUserId) {
    return StreamBuilder<List<TaskModel>>(
      stream: Provider.of<TaskService>(context).getGroupTasks(group.id),
      builder: (context, snap) {
        final tasks = snap.data ?? [];
        // Only show tasks that have been "taken" by the current user.
        final visible = tasks
            .where((t) => t.assignedTo == currentUserId && _matchesSearch(t))
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
    final List<TaskModel> individualTasks = tasks
        .where(
          (t) => (t.groupId == null || t.groupId!.isEmpty) && _matchesSearch(t),
        )
        .toList();

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
                            SizedBox(height: 16),
                          ],
                        );
                      },
                    )
                  : SizedBox(height: 16 + 24 + 16);

              return AnimatedSwitcher(
                duration: Duration(milliseconds: 250),
                child: content,
              );
            },
          ),
          _buildSearchBar(context),
          _buildChartFromTasks(tasks),
          Padding(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _refreshStats(currentUserId),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton<String>(
                            tooltip: 'Ubah status',
                            icon: _getStatusChip(task.status),
                            onSelected: (value) async {
                              final taskService = Provider.of<TaskService>(
                                context,
                                listen: false,
                              );
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await taskService.updateTaskStatus(
                                  task.id,
                                  value,
                                );
                                _updateCachedTaskStatus(task.id, value);
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
                          // Action toggle menu (edit/delete) shows only for tasks owned by the current user
                          if (task.userId == currentUserId)
                            PopupMenuButton<String>(
                              tooltip: 'Aksi tugas',
                              icon: Icon(Icons.more_vert, size: 20),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await _showEditTaskModal(task);
                                } else if (value == 'delete') {
                                  await _confirmAndDeleteTask(task);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 6),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 6),
                                      Text('Hapus'),
                                    ],
                                  ),
                                ),
                              ],
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
<<<<<<< HEAD
=======

class ChartData {
  final String x;
  final int y;
  final Color color;

  ChartData(this.x, this.y, this.color);
}
>>>>>>> f2e3d166f6881b2d555229faf4872a27c63e8582
