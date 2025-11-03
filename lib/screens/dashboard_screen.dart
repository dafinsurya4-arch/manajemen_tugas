import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

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
      stream: Provider.of<TaskService>(context).getPersonalTasks(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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

        // Compute statistics from the live task list so the chart stays in sync
        final int completed = tasks.where((t) => t.status == 'selesai').length;
        final int inProgress = tasks.where((t) => t.status == 'progres').length;
        final int pending = tasks.where((t) => t.status == 'tertunda').length;

        final stats = {'completed': completed, 'inProgress': inProgress, 'pending': pending};

        // Build the full column: chart + controls + task list
        final chartWidget = Container(
          height: 200,
          padding: EdgeInsets.all(16),
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            series: <CartesianSeries<ChartData, String>>[
              ColumnSeries<ChartData, String>(
                dataSource: [
                  ChartData('Selesai', stats['completed']!, Colors.green),
                  ChartData('Progress', stats['inProgress']!, Colors.orange),
                  ChartData('Tertunda', stats['pending']!, Colors.red),
                ],
                xValueMapper: (ChartData data, _) => data.x,
                yValueMapper: (ChartData data, _) => data.y,
                color: Color.fromRGBO(8, 142, 255, 1),
                dataLabelSettings: DataLabelSettings(isVisible: true),
              )
            ],
          ),
        );

        return Column(
          children: [
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
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada tugas',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tambahkan tugas baru untuk memulai',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                                try {
                                  await Provider.of<TaskService>(context, listen: false)
                                      .updateTaskStatus(task.id, value);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Status diperbarui')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Gagal memperbarui status: $e')),
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
                            onTap: () {},
                          ),
                        );
                      },
                    ),
            ),
          ],
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