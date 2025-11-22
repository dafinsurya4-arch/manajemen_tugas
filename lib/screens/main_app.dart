import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'dashboard_screen.dart';
import 'add_task_screen.dart';
import 'collaboration_screen.dart';
import 'notification_screen.dart';

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  String? _currentUserId;

  final List<Widget> _screens = [
    DashboardScreen(),
    AddTaskScreen(),
    CollaborationScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = authService.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.black, fontSize: 20),
            children: [
              TextSpan(text: 'Edu', style: TextStyle(fontWeight: FontWeight.normal)),
              TextSpan(text: 'Track', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          if (_currentUserId != null)
            StreamBuilder<int>(
              stream: Provider.of<NotificationService>(context)
                  .getUserNotifications(_currentUserId!)
                  .map((notifications) => notifications.where((n) => !n.isRead).length),
              builder: (context, snapshot) {
                int unreadCount = snapshot.data ?? 0;
                return IconButton(
                  icon: Stack(
                    children: [
                      Icon(Icons.notifications),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotificationScreen()),
                    );
                  },
                );
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authService.logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_task),
            label: 'Tambah Tugas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Kolaborasi',
          ),
        ],
      ),
    );
  }
}