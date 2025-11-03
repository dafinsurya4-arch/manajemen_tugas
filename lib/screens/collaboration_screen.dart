import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/group_service.dart';
import '../models/group_model.dart';
import 'create_group_screen.dart';

class CollaborationScreen extends StatefulWidget {
  @override
  _CollaborationScreenState createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GroupModel>>(
      stream: Provider.of<GroupService>(context).getUserGroups([]), // Ganti dengan list group IDs user
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
                      MaterialPageRoute(builder: (context) => CreateGroupScreen()),
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
                trailing: group.leader == 'current_user_id' // Ganti dengan user ID
                    ? Chip(label: Text('Ketua'), backgroundColor: Colors.blue)
                    : Chip(label: Text('Anggota'), backgroundColor: Colors.green),
                onTap: () {
                  _showGroupDetail(context, group);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showGroupDetail(BuildContext context, GroupModel group) {
    final TextEditingController _inviteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.8,
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
                        return ListTile(
                          title: Text(memberId), // Ganti dengan nama user
                          trailing: group.leader == 'current_user_id' && memberId != 'current_user_id'
                              ? IconButton(
                                  icon: Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () {
                                    Provider.of<GroupService>(context, listen: false)
                                        .removeMember(group.id, memberId);
                                    // Optimistically update UI
                                    setModalState(() {
                                      group.members.removeAt(index);
                                    });
                                  },
                                )
                              : memberId == 'current_user_id'
                                  ? IconButton(
                                      icon: Icon(Icons.exit_to_app, color: Colors.orange),
                                      onPressed: () {
                                        Provider.of<GroupService>(context, listen: false)
                                            .leaveGroup(group.id, memberId);
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  : null,
                        );
                      },
                    ),
                  ),
                  if (group.leader == 'current_user_id')
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Masukkan email terlebih dahulu')),
                                  );
                                  return;
                                }

                                final groupService =
                                    Provider.of<GroupService>(context, listen: false);
                                await groupService.inviteUser(group.id, 'current_user_id', email);
                                _inviteController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Undangan terkirim')),
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
          );
        });
      },
    ).whenComplete(() {
      _inviteController.dispose();
    });
  }
}