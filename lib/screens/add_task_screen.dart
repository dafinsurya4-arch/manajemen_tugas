import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';
import 'main_app.dart';
// Collaboration/group selection removed: tasks created here will always be 'individu'

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
  String _status = 'tertunda';
  // Collaboration fixed to 'individu' for this screen
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
        collaboration: 'individu',
        userId: 'current_user_id', // Ganti dengan user ID
        groupId: null,
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

        // This screen only allows individual tasks, so no group validation performed

        await Provider.of<TaskService>(context, listen: false).addTask(task);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title and subtitle above the task form
            SizedBox(height: 16),
            Text(
              'Form Tambah Tugas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Tambah, dan simpan tugas Anda di sini',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 32),
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
              value: _status,
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
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
              icon: Icon(Icons.assignment_add),
              label: Text('Simpan Tugas'),
            ),
          ],
        ),
      ),
    );
  }
}
