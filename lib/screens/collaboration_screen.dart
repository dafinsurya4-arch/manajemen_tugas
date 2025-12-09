import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/group_service.dart';
import '../models/group_model.dart';
import 'create_group_screen.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/task_service.dart';
import 'group_chat_screen.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  _CollaborationScreenState createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  Widget _buildGroupRoleChip(GroupModel group, String currentUid) {
    final role = group.leader == currentUid
        ? 'Ketua'
        : (group.members.contains(currentUid) ? 'Anggota' : 'Tidak Terdaftar');
    Color bg;
    switch (role) {
      case 'Ketua':
        bg = Colors.blue;
        break;
      case 'Anggota':
        bg = Colors.green;
        break;
      default:
        bg = Colors.grey;
    }
    return Chip(
      label: Text(
        role.toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: bg,
    );
  }

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
          listen: false,
        ).getUserGroups(user.groups);

        return Scaffold(
          body: StreamBuilder<List<GroupModel>>(
            stream: groupsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              final groups = snapshot.data!;
              final headerTitleStyle = TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              );
              final headerSubtitleStyle = TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              );

              Widget header = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 32),
                    Text('Kolaborasi Kelompok', style: headerTitleStyle),
                    SizedBox(height: 6),
                    Text(
                      'Kelola anggota kelompok dan diskusi proyek bersama',
                      style: headerSubtitleStyle,
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              );

              Widget actionsRow = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.group_add),
                      label: Text('Buat Kelompok'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateGroupScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  actionsRow,
                  SizedBox(height: 16),
                  Expanded(
                    child: groups.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Belum ada kelompok',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.group_add),
                                  label: Text('Buat Kelompok'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CreateGroupScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              final group = groups[index];
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.chat),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => GroupChatScreen(
                                                groupId: group.id,
                                                groupName: group.name,
                                                currentUid: user.uid,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    group.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (group.description.isNotEmpty)
                                        Text(
                                          group.description,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      SizedBox(height: 6),
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
                                              SizedBox(height: 6),
                                              Text(
                                                'Progres Kelompok:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child:
                                                        LinearProgressIndicator(
                                                          value:
                                                              percent / 100.0,
                                                          minHeight: 8,
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                        ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    '${percent.toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  _buildGroupRoleChip(
                                                    group,
                                                    user.uid,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => GroupDetailModal(
                                        group: group,
                                        currentUid: user.uid,
                                        parentContext: context,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => CreateGroupScreen()));
            },
          ),
        );
      },
    );
  }
}

class GroupDetailModal extends StatefulWidget {
  final GroupModel group;
  final String currentUid;
  final BuildContext parentContext;

  const GroupDetailModal({
    required this.group,
    required this.currentUid,
    required this.parentContext,
    super.key,
  });

  @override
  _GroupDetailModalState createState() => _GroupDetailModalState();
}

class _GroupDetailModalState extends State<GroupDetailModal>
    with TickerProviderStateMixin {
  late TextEditingController _inviteController;
  late TextEditingController _taskTitleController;
  late TextEditingController _deadlineController;
  late TextEditingController _taskDescriptionController;
  DateTime? _selectedDeadline;
  bool _showAddTaskPanel = false;
  bool _showInvitePanel = false;

  @override
  void initState() {
    super.initState();
    _inviteController = TextEditingController();
    _taskTitleController = TextEditingController();
    _deadlineController = TextEditingController();
    _taskDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _inviteController.dispose();
    _taskTitleController.dispose();
    _deadlineController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxModalHeight = screenHeight * 0.9;

    // Local header styles to match the 'Form Tambah Tugas' / 'Undang Anggota' texts
    final headerTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    // leader controls widget built separately for clarity
    final Widget leaderControls = widget.group.leader == widget.currentUid
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: Duration(milliseconds: 280),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showAddTaskPanel)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(),
                            Text('Form Tambah Tugas', style: headerTitleStyle),
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
                              controller: _taskDescriptionController,
                              decoration: InputDecoration(
                                hintText: 'Deskripsi tugas',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
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
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      final title = _taskTitleController.text
                                          .trim();
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

                                      final authService =
                                          Provider.of<AuthService>(
                                            widget.parentContext,
                                            listen: false,
                                          );
                                      final currentUid =
                                          authService.currentUser?.uid ?? '';

                                      final task = TaskModel(
                                        id: DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                        title: title,
                                        description: _taskDescriptionController
                                            .text
                                            .trim(),
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
                                        _taskDescriptionController.clear();
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
                      ),

                    if (_showInvitePanel)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(),
                            Text(
                              'Undang Anggota Baru:',
                              style: headerTitleStyle,
                            ),
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

                                    final groupService =
                                        Provider.of<GroupService>(
                                          widget.parentContext,
                                          listen: false,
                                        );
                                    final authService =
                                        Provider.of<AuthService>(
                                          widget.parentContext,
                                          listen: false,
                                        );
                                    final currentUid =
                                        authService.currentUser?.uid ?? '';

                                    final sent = await groupService.inviteUser(
                                      group.id,
                                      currentUid,
                                      email,
                                    );
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
                      ),
                  ],
                ),
              ),

              // toolbar with action buttons
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAddTaskPanel = !_showAddTaskPanel;
                          if (_showAddTaskPanel) _showInvitePanel = false;
                        });
                      },
                      icon: Icon(Icons.assignment_add),
                      label: Text('Tambah Tugas'),
                    ),
                    if (widget.group.leader == widget.currentUid) ...[
                      SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showInvitePanel = !_showInvitePanel;
                            if (_showInvitePanel) _showAddTaskPanel = false;
                          });
                        },
                        icon: Icon(Icons.person_add),
                        label: Text('Undang Anggota'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          )
        : Container();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          height: maxModalHeight,
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chat),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GroupChatScreen(
                                groupId: group.id,
                                groupName: group.name,
                                currentUid: widget.currentUid,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 8),
              Text(
                group.description,
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 8),

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
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 12),
                    ],
                  );
                },
              ),

              SizedBox(height: 8),
              Text('Anggota Kelompok:', style: headerTitleStyle),

              SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: group.members.length,
                  itemBuilder: (context, index) {
                    final memberId = group.members[index];
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(memberId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return ListTile(title: Text('Loading...'));
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final email =
                            userData?['email'] as String? ?? 'Unknown';
                        final fullName =
                            userData?['fullName'] as String? ?? 'Unknown';
                        return ListTile(
                          title: Text(fullName),
                          subtitle: Text(
                            email,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          trailing:
                              (widget.group.leader == widget.currentUid &&
                                  memberId != widget.currentUid)
                              ? IconButton(
                                  icon: Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('Keluarkan anggota'),
                                        content: Text(
                                          'Anggota akan dikeluarkan dari kelompok. Semua tugas kelompok yang diambil anggota ini akan dikembalikan menjadi belum diambil (unassigned). Lanjutkan?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: Text('Keluarkan'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await Provider.of<GroupService>(
                                        widget.parentContext,
                                        listen: false,
                                      ).removeMember(group.id, memberId);
                                      setState(
                                        () => group.members.removeAt(index),
                                      );
                                      ScaffoldMessenger.of(
                                        widget.parentContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Anggota dikeluarkan dan tugas yang diambil dikembalikan',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                )
                              : (memberId == widget.currentUid)
                              ? IconButton(
                                  icon: Icon(
                                    Icons.exit_to_app,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('Keluar dari kelompok'),
                                        content: Text(
                                          'Anda akan keluar dari kelompok. Semua tugas kelompok yang telah Anda ambil akan dikembalikan menjadi belum diambil (unassigned). Lanjutkan?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: Text('Keluar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await Provider.of<GroupService>(
                                        widget.parentContext,
                                        listen: false,
                                      ).leaveGroup(group.id, memberId);
                                      ScaffoldMessenger.of(
                                        widget.parentContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Anda keluar dari kelompok. Tugas yang Anda ambil dikembalikan.',
                                          ),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
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
              // Add a clear heading and description above the tasks list (modal kept cleaner; header is at page level)
              SizedBox(height: 12),
              Text('Tugas Kelompok:', style: headerTitleStyle),
              SizedBox(height: 8),

              Expanded(
                child: StreamBuilder<List<TaskModel>>(
                  stream: Provider.of<TaskService>(
                    widget.parentContext,
                    listen: false,
                  ).getGroupTasks(group.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Center(child: CircularProgressIndicator());
                    final tasks = snapshot.data!;
                    if (tasks.isEmpty)
                      return Center(child: Text('Belum ada tugas.'));
                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, tIndex) {
                        final task = tasks[tIndex];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(task.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.description,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
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
                                            ? Colors.red
                                            : task.status == 'progres'
                                            ? Colors.orange
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                task.assignedTo == null
                                    ? Text(
                                        'Belum diambil',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      )
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
                                          return Text(
                                            'Diambil oleh: $name',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                            trailing:
                                task.assignedTo == null &&
                                    group.members.contains(widget.currentUid)
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                    ),
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

              // leader controls or simple close button
              leaderControls,
            ],
          ),
        ),
      ),
    );
  }
}
