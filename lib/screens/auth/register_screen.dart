import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _debugInfo = '';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  void _updateDebugInfo(String info) {
    // Only update state if this State object is still mounted.
    if (mounted) {
      setState(() {
        _debugInfo = info;
      });
    } else {
      // If we're already disposed, log the debug info instead of calling setState.
      print('DEBUG (late): $info');
      return;
    }
    print('DEBUG: $info');
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _updateDebugInfo('Kata Sandi tidak sama');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kata Sandi dan konfirmasi kata sandi tidak sama'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } else {
        _debugInfo = 'Memulai proses registrasi...';
      }

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = await authService.register(
          _fullNameController.text.trim(),
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

        if (user != null) {
          _updateDebugInfo('Registrasi BERHASIL!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registrasi berhasil!'),
              backgroundColor: Colors.green,
            ),
          );

          // Clear form
          _fullNameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();

          // Kembali ke login tab/screen setelah registrasi berhasil
          final tabController = DefaultTabController.maybeOf(context);
          if (tabController != null) {
            tabController.animateTo(0);
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } else {
          _updateDebugInfo('Registrasi GAGAL - user null');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registrasi gagal. Coba dengan email yang berbeda.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        } else {
          _isLoading = false;
        }
        _updateDebugInfo('Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan sistem: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          print('SNACKBAR (late): Terjadi kesalahan sistem: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Debug Info
              if (_debugInfo.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _debugInfo,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),

              SizedBox(height: 12),
              Text(
                'Silakan daftar untuk membuat akun',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18),
              TextFormField(
                controller: _fullNameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: Icon(Icons.person, color: Colors.white70),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama lengkap harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: Icon(Icons.email, color: Colors.white70),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email harus diisi';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kata Sandi harus diisi';
                  }
                  if (value.length < 6) {
                    return 'Kata Sandi minimal 6 karakter';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                ),
                obscureText: _obscureConfirm,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi kata sandi harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Sedang memproses...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
<<<<<<< HEAD
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Daftar', style: TextStyle(fontSize: 16)),
=======
                        ),
                        child: Text(
                          'Daftar',
                          style: TextStyle(fontSize: 16),
                        ),
>>>>>>> f2e3d166f6881b2d555229faf4872a27c63e8582
                      ),
                    ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
