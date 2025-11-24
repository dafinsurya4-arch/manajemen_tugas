import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'dashboard_screen.dart';
import 'add_task_screen.dart';
import 'collaboration_screen.dart';
import 'notification_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _currentUserId;
  bool _isNavHidden = false;
  double _scrollAccumulator =
      0.0; // accumulate small scroll deltas so slow scrolls still trigger
  bool _isKeyboardVisible = false;
  DateTime? _navShowCooldownUntil;

  // track whether the current page has scrollable content (maxScrollExtent>0)
  bool _currentPageHasScrollableContent = false;

  // track whether current scroll position is at the top
  bool _isAtScrollTop = true;

  final List<Widget> _screens = [
    DashboardScreen(),
    AddTaskScreen(),
    CollaborationScreen(),
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _isKeyboardVisible = WidgetsBinding.instance.window.viewInsets.bottom > 0.0;
    super.initState();
    _getCurrentUser();

    // Focus changes can indicate keyboard hide/show — ensure nav reappears when focus is lost
    FocusManager.instance.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    // If there is no primary focus, the keyboard is likely closed; ensure nav appears
    if (FocusManager.instance.primaryFocus == null) {
      if (mounted) {
        setState(() {
          _isKeyboardVisible = false;
          _isNavHidden = false;
          // seed a negative accumulator to mimic a scroll-up and ensure nav shows
          _scrollAccumulator = -40.0;
          _navShowCooldownUntil = DateTime.now().add(
            Duration(milliseconds: 1000),
          );
        });
      }
      // short delayed reaffirmation to handle layout races
      Timer(Duration(milliseconds: 160), () {
        if (!mounted) return;
        if (DateTime.now().isBefore(_navShowCooldownUntil ?? DateTime.now())) {
          setState(() => _isNavHidden = false);
        }
      });
    }
  }

  @override
  void didChangeMetrics() {
    // Called when window metrics change (e.g. keyboard open/close)
    final isOpen = WidgetsBinding.instance.window.viewInsets.bottom > 0.0;
    if (isOpen != _isKeyboardVisible) {
      // If keyboard closed, make sure nav is visible immediately
      if (!isOpen) {
        if (mounted) {
          setState(() {
            _isKeyboardVisible = false;

            // behave like user scrolled up: seed negative accumulator so nav appears
            _isNavHidden = false;
            _scrollAccumulator = -40.0;
            _navShowCooldownUntil = DateTime.now().add(
              Duration(milliseconds: 1000),
            );
          });
        }
        // short delayed reaffirmation to handle layout races
        Timer(Duration(milliseconds: 160), () {
          if (!mounted) return;
          if (DateTime.now().isBefore(
            _navShowCooldownUntil ?? DateTime.now(),
          )) {
            setState(() => _isNavHidden = false);
          }
        });
      } else {
        // keyboard opened: keep nav visible while typing
        if (mounted) {
          setState(() {
            _isKeyboardVisible = true;
            _isNavHidden = false;
          });
        }
      }
    }
    super.didChangeMetrics();
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
            style: TextStyle(
              color: const Color.fromARGB(255, 255, 255, 255),
              fontSize: 20,
            ),
            children: [
              TextSpan(
                text: 'Edu',
                style: TextStyle(fontWeight: FontWeight.normal),
              ),
              TextSpan(
                text: 'Track',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          if (_currentUserId != null)
            StreamBuilder<int>(
              stream: Provider.of<NotificationService>(context)
                  .getUserNotifications(_currentUserId!)
                  .map(
                    (notifications) =>
                        notifications.where((n) => !n.isRead).length,
                  ),
              builder: (context, snapshot) {
                int unreadCount = snapshot.data ?? 0;
                return IconButton(
                  icon: Stack(
                    children: [
                      Icon(Icons.notifications, color: Colors.white),
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
                      MaterialPageRoute(
                        builder: (context) => NotificationScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          PopupMenuButton<String>(
            style: ButtonStyle(
              iconColor: MaterialStateProperty.all(Colors.white),
            ),
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
      body: Stack(
        children: [
          // main page content — listen for scrolls from any descendant Scrollable and hide/show nav
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // If keyboard is visible, don't hide nav on scroll — keep nav accessible while typing
                if (_isKeyboardVisible) return false;
                // update metrics state for each scroll notification
                final m = notification.metrics;
                _currentPageHasScrollableContent = m.maxScrollExtent > 0.0;
                // consider near-top as at most 2 px below minScrollExtent
                _isAtScrollTop = (m.pixels - m.minScrollExtent).abs() <= 2.0;

                if (notification is ScrollUpdateNotification) {
                  final dy = notification.scrollDelta ?? 0.0;

                  // Accumulate small deltas so slow/gradual scrolling still triggers hide/show.
                  // Positive dy = user scrolling down (content moves up), negative = scrolling up.
                  // ignore hiding while inside the cooldown window (e.g. just after keyboard closed)
                  if (_navShowCooldownUntil != null &&
                      DateTime.now().isBefore(_navShowCooldownUntil!)) {
                    return false;
                  }

                  if (dy > 0) {
                    // scrolling down - accumulate positive
                    if (_scrollAccumulator < 0) _scrollAccumulator = 0.0;
                    _scrollAccumulator += dy;
                    if (_scrollAccumulator > 24) {
                      if (!_isNavHidden) setState(() => _isNavHidden = true);
                      _scrollAccumulator = 0.0;
                    }
                  } else if (dy < 0) {
                    // scrolling up - accumulate negative
                    if (_scrollAccumulator > 0) _scrollAccumulator = 0.0;
                    _scrollAccumulator += dy; // negative
                    if (_scrollAccumulator < -24) {
                      if (_isNavHidden) setState(() => _isNavHidden = false);
                      _scrollAccumulator = 0.0;
                    }
                  }
                } else if (notification is ScrollEndNotification) {
                  // reset when scroll stops
                  _scrollAccumulator = 0.0;
                }
                return false; // allow other listeners to continue
              },
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) {
                  // user interacted — ensure nav is visible (useful on non-scrollable pages)
                  // Only show nav by touch if page is NOT scrollable OR it is at the top
                  final shouldShowByTouch =
                      !_currentPageHasScrollableContent || _isAtScrollTop;
                  if (_isNavHidden && shouldShowByTouch) {
                    setState(() {
                      _isNavHidden = false;
                      _navShowCooldownUntil = DateTime.now().add(
                        Duration(milliseconds: 500),
                      );
                    });
                  }
                },
                child: _screens[_currentIndex],
              ),
            ),
          ),

          // floating navigation container (slides out on scroll down)
          Positioned(
            left: 12,
            right: 12,
            bottom: 18,
            child: AnimatedSlide(
              offset: _isNavHidden ? const Offset(0, 2.2) : Offset.zero,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
              child: SafeArea(
                top: false,
                child: Material(
                  elevation: 12,
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF0D47A1),
                  child: Container(
                    height: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        _navItem(
                          icon: Icons.dashboard,
                          label: 'Beranda',
                          index: 0,
                        ),
                        _navItem(
                          icon: Icons.add_task,
                          label: 'Tambah Tugas',
                          index: 1,
                        ),
                        _navItem(
                          icon: Icons.group,
                          label: 'Kolaborasi',
                          index: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _currentIndex = index;
          // ensure nav is visible when switching pages (so pages without scroll show it)
          _isNavHidden = false;
        }),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.white70,
              size: 26,
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
