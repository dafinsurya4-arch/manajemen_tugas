import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/group_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.signOut();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<TaskService>(create: (_) => TaskService()),
        Provider<GroupService>(create: (_) => GroupService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'EduTrack',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // Always show the SplashLauncher on cold app start. AuthWrapper
        // should not display the splashscreen during auth state waits or
        // during login transitions — we'll show a lightweight loading UI
        // instead when auth stream / user lookups are pending.
        home: SplashLauncher(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplashLauncher extends StatefulWidget {
  @override
  _SplashLauncherState createState() => _SplashLauncherState();
}

class _SplashLauncherState extends State<SplashLauncher> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() async {
    // Show splash for 2 seconds, then navigate to the auth wrapper.
    await Future.delayed(Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen();
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Avoid re-showing the splash while the auth stream warms up
          // after login/changes. Use a small loading indicator instead.
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: _getUserData(authService, snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                // Likewise, show the same small loading UI while we fetch
                // user profile data rather than the full splash screen.
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (userSnapshot.hasData && userSnapshot.data != null) {
                return MainApp();
              }
              
              return LoginScreen();
            },
          );
        }
        
        return LoginScreen();
      },
    );
  }

  Future<UserModel?> _getUserData(AuthService authService, String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}