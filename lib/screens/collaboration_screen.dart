import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/group_service.dart';
import '../models/group_model.dart';
import 'create_group_screen.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  _CollaborationScreenState createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<UserModel?>(
      stream: authService.userDataStream,
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = userSnapshot.data!;

        // Body stream for groups
        final groupsStream = Provider.of<GroupService>(
          context,
        ).getUserGroups(user.groups);

        return Scaffold(
          body: StreamBuilder<List<GroupModel>>(
            stream: groupsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              List<GroupModel> groups = snapshot.data!;

              if (groups.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada kelompok',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateGroupScreen(),
                            ),
                          );
                        },
                        child: Text('Buat Kelompok'),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24),
                    Text(
                      'Kolaborasi Kelompok',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Kelola anggota kelompok dan diskusi proyek bersama',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateGroupScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.group_add),
                        label: Text('Buat Kelompok'),
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final GroupModel group = groups[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(group.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(group.description),
                                  SizedBox(height: 6),

                                  // Progress indicator for group tasks
                                  StreamBuilder<double>(
                                    stream: Provider.of<TaskService>(
                                      context,
                                      listen: false,
                                    ).getGroupProgress(group.id),
                                    builder: (ctx, snap) {
                                      final percent = (snap.hasData)
                                          ? snap.data!.clamp(0.0, 100.0)
                                          : 0.0;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          LinearProgressIndicator(
                                            value: percent / 100.0,
                                            minHeight: 6,
                                            backgroundColor: Colors.grey[300],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '${percent.toStringAsFixed(0)}% selesai',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                              trailing: group.leader == user.uid
                                  ? Chip(
                                      label: Text('Ketua'),
                                      backgroundColor: Colors.blue,
                                    )
                                  : Chip(
                                      label: Text('Anggota'),
                                      backgroundColor: Colors.green,
                                    ),
                              onTap: () =>
                                  _showGroupDetail(context, group, user.uid),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showGroupDetail(
    BuildContext parentContext,
    GroupModel group,
    String currentUid,
  ) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      builder: (modalContext) {
        return GroupDetailModal(
          parentContext: parentContext,
          group: group,
          currentUid: currentUid,
        );
      },
    );
  }
}

class GroupDetailModal extends StatefulWidget {
  final BuildContext parentContext;
  final GroupModel group;
  final String currentUid;

  const GroupDetailModal({
    super.key,
    required this.parentContext,
    required this.group,
    required this.currentUid,
  });

  @override
  _GroupDetailModalState createState() => _GroupDetailModalState();
}

class _GroupDetailModalState extends State<GroupDetailModal> {
  late TextEditingController _inviteController;
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  DateTime? _selectedDeadline;
  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _inviteController = TextEditingController();
  }

  @override
  void dispose() {
    _inviteController.dispose();
    _taskTitleController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxModalHeight = screenHeight * 0.9;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          height: maxModalHeight,
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(group.description),
                SizedBox(height: 8),

                // Group progress indicator in modal
                StreamBuilder<double>(
                  stream: Provider.of<TaskService>(
                    widget.parentContext,
                    listen: false,
                  ).getGroupProgress(group.id),
                  builder: (context, snap) {
                    final percent = (snap.hasData)
                        ? snap.data!.clamp(0.0, 100.0)
                        : 0.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: percent / 100.0,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Progres kelompok: ${percent.toStringAsFixed(0)}% Selesai',
                        ),
                        SizedBox(height: 12),
                      ],
                    );
                  },
                ),
                SizedBox(height: 16),
                Text(
                  'Anggota Kelompok:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                // Members list - fixed height with scroll
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: group.members.length,
                    itemBuilder: (context, index) {
                      String memberId = group.members[index];
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(memberId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return ListTile(
                              title: Text('Loading...'),
                              leading: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final userData =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          final email =
                              userData?['email'] as String? ?? 'Unknown';
                          final fullName =
                              userData?['fullName'] as String? ?? 'Unknown';

                          return ListTile(
                            title: Text(fullName),
                            subtitle: Text(email),
                            trailing:
                                group.leader == widget.currentUid &&
                                    memberId != widget.currentUid
                                ? IconButton(
                                    icon: Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      Provider.of<GroupService>(
                                        widget.parentContext,
                                        listen: false,
                                      ).removeMember(group.id, memberId);
                                      setState(() {
                                        group.members.removeAt(index);
                                      });
                                    },
                                  )
                                : memberId == widget.currentUid
                                ? IconButton(
                                    icon: Icon(
                                      Icons.exit_to_app,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () {
                                      Provider.of<GroupService>(
                                        widget.parentContext,
                                        listen: false,
                                      ).leaveGroup(group.id, memberId);
                                      Navigator.of(context).pop();
                                    },
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),

                SizedBox(height: 12),
                Text(
                  'Tugas Kelompok:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),

                // Tasks list - fixed height with scroll
                SizedBox(
                  height: 250,
                  child: StreamBuilder<List<TaskModel>>(
                    stream: Provider.of<TaskService>(
                      widget.parentContext,
                      listen: false,
                    ).getGroupTasks(group.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final tasks = snapshot.data!;
                      if (tasks.isEmpty) {
                        return Center(child: Text('Belum ada tugas.'));
                      }
                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, tIndex) {
                          final task = tasks[tIndex];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(task.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task.description),
                                  Row(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Chip(
                                          label: Text(
                                            task.status == 'tertunda'
                                                ? 'Tertunda'
                                                : task.status == 'progres'
                                                ? 'Dalam Progres'
                                                : 'Selesai',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor:
                                              task.status == 'tertunda'
                                              ? Colors.orange
                                              : task.status == 'progres'
                                              ? Colors.blue
                                              : Colors.green,
                                        ),
                                      ),
                                      if (task.assignedTo == widget.currentUid)
                                        PopupMenuButton<String>(
                                          icon: Icon(Icons.more_vert, size: 20),
                                          onSelected: (String newStatus) async {
                                            try {
                                              await Provider.of<TaskService>(
                                                widget.parentContext,
                                                listen: false,
                                              ).updateTaskStatus(
                                                task.id,
                                                newStatus,
                                              );
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                widget.parentContext,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Status tugas diperbarui',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                widget.parentContext,
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
                                              value: 'tertunda',
                                              child: Text('Tertunda'),
                                              enabled:
                                                  task.status != 'tertunda',
                                            ),
                                            PopupMenuItem(
                                              value: 'progres',
                                              child: Text('Dalam Progres'),
                                              enabled: task.status != 'progres',
                                            ),
                                            PopupMenuItem(
                                              value: 'selesai',
                                              child: Text('Selesai'),
                                              enabled: task.status != 'selesai',
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Deadline: ${DateFormat('dd/MM/yyyy').format(task.deadline)}',
                                  ),
                                  SizedBox(height: 4),
                                  task.assignedTo == null
                                      ? Text('Belum diambil')
                                      : StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(task.assignedTo)
                                              .snapshots(),
                                          builder: (ctx, asnSnap) {
                                            if (!asnSnap.hasData) {
                                              return Text('Loading...');
                                            }
                                            final userMap =
                                                asnSnap.data!.data()
                                                    as Map<String, dynamic>?;
                                            final name =
                                                userMap?['fullName']
                                                    as String? ??
                                                'Unknown';
                                            return Text('Diambil oleh: $name');
                                          },
                                        ),
                                ],
                              ),
                              trailing:
                                  task.assignedTo == null &&
                                      group.members.contains(widget.currentUid)
                                  ? ElevatedButton(
                                      child: Text('Ambil'),
                                      onPressed: () async {
                                        try {
                                          await Provider.of<TaskService>(
                                            widget.parentContext,
                                            listen: false,
                                          ).updateTaskAssignment(
                                            task.id,
                                            widget.currentUid,
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            widget.parentContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Tugas diambil'),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            widget.parentContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Gagal mengambil tugas: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 12),
                if (group.leader == widget.currentUid)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(),
                      Text('Tambah Tugas (Ketua):'),
                      SizedBox(height: 8),
                      TextField(
                        controller: _taskTitleController,
                        decoration: InputDecoration(
                          hintText: 'Judul tugas',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _deadlineController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Pilih deadline',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDeadline(context),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final title = _taskTitleController.text.trim();
                                if (title.isEmpty ||
                                    _selectedDeadline == null) {
                                  ScaffoldMessenger.of(
                                    widget.parentContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Isi judul dan pilih deadline',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final authService = Provider.of<AuthService>(
                                  widget.parentContext,
                                  listen: false,
                                );
                                final currentUid =
                                    authService.currentUser?.uid ?? '';

                                final task = TaskModel(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  title: title,
                                  description: '',
                                  deadline: _selectedDeadline!,
                                  status: 'tertunda',
                                  collaboration: 'kelompok',
                                  userId: currentUid,
                                  groupId: group.id,
                                  assignedTo: null,
                                  createdBy: currentUid,
                                  createdAt: DateTime.now(),
                                );

                                try {
                                  await Provider.of<TaskService>(
                                    widget.parentContext,
                                    listen: false,
                                  ).addTask(task);
                                  if (!mounted) return;
                                  _taskTitleController.clear();
                                  _deadlineController.clear();
                                  _selectedDeadline = null;
                                  ScaffoldMessenger.of(
                                    widget.parentContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Tugas berhasil ditambahkan',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(
                                    widget.parentContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Gagal menambahkan tugas: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text('Tambah Tugas'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (group.leader == widget.currentUid)
                  Column(
                    children: [
                      Divider(),
                      Text('Undang Anggota Baru:'),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inviteController,
                              decoration: InputDecoration(
                                hintText: 'Email pengguna',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send),
                            onPressed: () async {
                              final email = _inviteController.text.trim();
                              if (email.isEmpty) {
                                ScaffoldMessenger.of(
                                  widget.parentContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Masukkan email terlebih dahulu',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final groupService = Provider.of<GroupService>(
                                widget.parentContext,
                                listen: false,
                              );
                              final authService = Provider.of<AuthService>(
                                widget.parentContext,
                                listen: false,
                              );
                              final currentUid =
                                  authService.currentUser?.uid ?? '';

                              // perform invite
                              final sent = await groupService.inviteUser(
                                group.id,
                                currentUid,
                                email,
                              );

                              // Only interact with controller or show UI if still mounted
                              if (!mounted) return;

                              _inviteController.clear();
                              ScaffoldMessenger.of(
                                widget.parentContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    sent
                                        ? 'Undangan telah dikirim'
                                        : 'Pengguna dengan email tersebut tidak ditemukan',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
