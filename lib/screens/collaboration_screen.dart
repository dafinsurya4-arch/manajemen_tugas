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
          return Scaffold(
            appBar: AppBar(title: Text('Kolaborasi')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = userSnapshot.data!;

        // Body stream for groups
        final groupsStream = Provider.of<GroupService>(
          context,
        ).getUserGroups(user.groups);

        return Scaffold(
          appBar: AppBar(
            title: Text('Kolaborasi'),
            actions: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
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
                  icon: Icon(Icons.add),
                  label: Text('Buat Kelompok'),
                ),
              ),
            ],
          ),
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

              return ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  GroupModel group = groups[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(group.name),
                      subtitle: Text(group.description),
                      trailing: group.leader == user.uid
                          ? Chip(
                              label: Text('Ketua'),
                              backgroundColor: Colors.blue,
                            )
                          : Chip(
                              label: Text('Anggota'),
                              backgroundColor: Colors.green,
                            ),
                      onTap: () {
                        _showGroupDetail(context, group, user.uid);
                      },
                    ),
                  );
                },
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
    Key? key,
    required this.parentContext,
    required this.group,
    required this.currentUid,
  }) : super(key: key);

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

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(group.description),
                SizedBox(height: 16),
                Text(
                  'Anggota Kelompok:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
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
                // List group tasks
                StreamBuilder<List<TaskModel>>(
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
                      return Text('Belum ada tugas.');
                    }
                    return Column(
                      children: tasks.map((task) {
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
                                      margin: EdgeInsets.symmetric(vertical: 4),
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
                                            enabled: task.status != 'tertunda',
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
                                          if (!asnSnap.hasData)
                                            return Text('Loading...');
                                          final userMap =
                                              asnSnap.data!.data()
                                                  as Map<String, dynamic>?;
                                          final name =
                                              userMap?['fullName'] as String? ??
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
                      }).toList(),
                    );
                  },
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
