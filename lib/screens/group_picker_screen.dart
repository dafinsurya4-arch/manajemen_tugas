import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/group_service.dart';
import '../models/group_model.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// Simple screen to let the user pick one of their groups.
class GroupPickerScreen extends StatelessWidget {
  const GroupPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Pilih Kelompok')),
      body: StreamBuilder<UserModel?>(
        stream: authService.userDataStream,
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final user = userSnap.data!;

          return StreamBuilder<List<GroupModel>>(
            stream: Provider.of<GroupService>(
              context,
              listen: false,
            ).getUserGroups(user.groups),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              final groups = snap.data!;
              if (groups.isEmpty) {
                return Center(
                  child: Text('Anda tidak tergabung di kelompok manapun'),
                );
              }

              return ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final g = groups[index];
                  return Card(
                    child: ListTile(
                      title: Text(g.name),
                      subtitle: Text(g.description),
                      trailing: g.leader == user.uid
                          ? Chip(label: Text('Ketua'))
                          : null,
                      onTap: () {
                        Navigator.of(context).pop(g);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
