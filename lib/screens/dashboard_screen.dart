import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';
import '../services/group_service.dart';
import '../models/group_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return Center(child: Text('Silakan login untuk melihat dashboard'));
    }

    // Render the chart and the task list from a single stream so they stay
    // in sync. The StreamBuilder is inside _buildTaskList() which returns the
    // full column (chart + refresh + list).
    return _buildTaskList();
  }

  Widget _buildTaskList() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return Center(child: Text('Silakan login'));

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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class ChartData {
  final String x;
  final int y;
  final Color color;

  ChartData(this.x, this.y, this.color);
}
