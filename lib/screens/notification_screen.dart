import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/group_service.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi'),
        actions: [
          IconButton(
            icon: Icon(Icons.mark_email_read),
            onPressed: () {
              Provider.of<NotificationService>(context, listen: false)
                  .markAllAsRead('current_user_id'); // Ganti dengan user ID
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: Provider.of<NotificationService>(context)
            .getUserNotifications('current_user_id'), // Ganti dengan user ID
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<NotificationModel> notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return Center(
              child: Text('Tidak ada notifikasi'),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              NotificationModel notification = notifications[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: notification.isRead ? Colors.white : Colors.blue[50],
                child: ListTile(
                  title: Text(notification.title),
                  subtitle: Text(notification.message),
                  trailing: notification.type == 'group_invitation' && !notification.isRead
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                // Accept invitation: add user to group and remove notification
                                final groupService =
                                    Provider.of<GroupService>(context, listen: false);
                                final userId = 'current_user_id'; // TODO: replace with actual user id
                                if (notification.groupId != null) {
                                  await groupService.acceptInvitation(
                                      notification.id, notification.groupId!, userId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Berhasil bergabung ke grup')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Data grup tidak tersedia')),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                // Reject invitation: delete notification
                                final groupService =
                                    Provider.of<GroupService>(context, listen: false);
                                await groupService.rejectInvitation(notification.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Undangan ditolak')),
                                );
                              },
                            ),
                          ],
                        )
                      : null,
                  onTap: () {
                    Provider.of<NotificationService>(context, listen: false)
                        .markAsRead(notification.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}