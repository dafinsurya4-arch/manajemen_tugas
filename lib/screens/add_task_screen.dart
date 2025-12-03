import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';
import 'main_app.dart';
import '../screens/group_picker_screen.dart';
import '../models/group_model.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deadlineController = TextEditingController();
  GroupModel? _selectedGroup;

  String _status = 'tertunda';
  String _collaboration = 'individu';
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _deadlineController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      TaskModel task = TaskModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        deadline: _selectedDate!,
        status: _status,
        collaboration: _collaboration,
        userId: 'current_user_id', // Ganti dengan user ID
        groupId: _selectedGroup?.id,
        assignedTo: null,
        createdBy: 'current_user_id', // Ganti dengan user ID
        createdAt: DateTime.now(),
      );

      try {
        // Use actual authenticated user id if available
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          task = TaskModel(
            id: task.id,
            title: task.title,
            description: task.description,
            deadline: task.deadline,
            status: task.status,
            collaboration: task.collaboration,
            userId: currentUserId,
            groupId: task.groupId,
            assignedTo: null,
            createdBy: currentUserId,
            createdAt: task.createdAt,
          );
        }

        // If collaboration is kelompok, ensure a group was selected and the current user is the group's leader
        if (_collaboration == 'kelompok') {
          if (_selectedGroup == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Pilih kelompok terlebih dahulu')),
              );
            }
            return;
          }
          if (currentUserId != _selectedGroup!.leader) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Hanya ketua kelompok yang dapat menambahkan tugas kelompok',
                  ),
                ),
              );
            }
            return;
          }
        }

        await Provider.of<TaskService>(context, listen: false).addTask(task);

        // Show confirmation and navigate back to dashboard. If this screen
        // was presented as a pushed route, pop it. If not (e.g., it's a
        // tab), replace the whole route with MainApp to ensure the
        // dashboard is visible and we don't end up with a blank screen.
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tugas berhasil ditambahkan')));
        }

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainApp()),
          );
        }
      } catch (e) {
        print('Error saving task: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyimpan tugas: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Judul Tugas',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Judul tugas harus diisi';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi Tugas',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _deadlineController,
              decoration: InputDecoration(
                labelText: 'Deadline (DD/MM/YYYY)',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Deadline harus diisi';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Status Tugas',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'tertunda', child: Text('Tertunda')),
                DropdownMenuItem(
                  value: 'progres',
                  child: Text('Dalam Progress'),
                ),
                DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
              ],
              onChanged: (value) {
                setState(() {
                  _status = value!;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _collaboration,
              decoration: InputDecoration(
                labelText: 'Kolaborasi',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'individu', child: Text('Individu')),
                DropdownMenuItem(value: 'kelompok', child: Text('Kelompok')),
              ],
              onChanged: (value) {
                setState(() {
                  _collaboration = value!;
                });
              },
            ),
            SizedBox(height: 12),
            if (_collaboration == 'kelompok')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final selected = await Navigator.push<GroupModel?>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupPickerScreen(),
                          ),
                        );
                        if (selected != null) {
                          setState(() {
                            _selectedGroup = selected;
                          });
                        }
                      },
                      child: Text(
                        _selectedGroup == null
                            ? 'Pilih Kelompok'
                            : 'Kelompok: ${_selectedGroup!.name}',
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 24),
            ElevatedButton(onPressed: _saveTask, child: Text('Simpan Tugas')),
          ],
        ),
      ),
    );
  }
}
