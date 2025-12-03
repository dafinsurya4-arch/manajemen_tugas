import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      } else {
        _isLoading = true;
      }

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = await authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        } else {
          _isLoading = false;
        }

        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Masuk gagal. Periksa email dan kata sandi.'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            print('SNACKBAR (late): Masuk gagal. Periksa email dan kata sandi.');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        } else {
          _isLoading = false;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          print('ERROR (late): Terjadi kesalahan: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black87, fontSize: 28),
                    children: [
                      TextSpan(text: 'Edu', style: TextStyle(fontWeight: FontWeight.normal)),
                      TextSpan(text: 'Track', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(maxWidth: 700),
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.login), text: 'Masuk'),
                          Tab(icon: Icon(Icons.person_add), text: 'Daftar'),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Use the TabController as a Listenable and an IndexedStack so the
                      // container height adapts to the currently visible child.
                      Builder(
                        builder: (context) {
                          final controller = DefaultTabController.of(context);
                          return AnimatedBuilder(
                            animation: controller,
                            builder: (context, child) {
                              final index = controller.index;
                              return IndexedStack(
                                index: index,
                                children: [
                                  // Login form (no title)
                                  SingleChildScrollView(
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          children: [
                                            SizedBox(height: 5),
                                            Text('Silakan masuk untuk melanjutkan', style: TextStyle(color: Colors.grey[700]), textAlign: TextAlign.center),
                                            SizedBox(height: 25),
                                            TextFormField(
                                              controller: _emailController,
                                              decoration: InputDecoration(
                                                labelText: 'Email',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(Icons.email),
                                                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                              ),
                                              keyboardType: TextInputType.emailAddress,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Email harus diisi';
                                                }
                                                if (!value.contains('@')) {
                                                  return 'Email tidak valid';
                                                }
                                                return null;
                                              },
                                            ),
                                            SizedBox(height: 16),
                                            TextFormField(
                                              controller: _passwordController,
                                              decoration: InputDecoration(
                                                labelText: 'Kata Sandi',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(Icons.lock),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscurePassword = !_obscurePassword;
                                                    });
                                                  },
                                                ),
                                                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                              ),
                                              obscureText: _obscurePassword,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Kata Sandi harus diisi';
                                                }
                                                return null;
                                              },
                                            ),
                                            SizedBox(height: 24),
                                            _isLoading
                                                ? CircularProgressIndicator()
                                                : SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: _login,
                                                      style: ElevatedButton.styleFrom(
                                                        padding: EdgeInsets.symmetric(vertical: 15),
                                                      ),
                                                      child: Text(
                                                        'Masuk',
                                                        style: TextStyle(fontSize: 16),
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Register form
                                  SingleChildScrollView(
                                    child: RegisterScreen(),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}