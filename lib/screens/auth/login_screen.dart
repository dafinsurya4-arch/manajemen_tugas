import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showForm = false;

  TabController? _tabController;
  final GlobalKey _loginKey = GlobalKey();
  final GlobalKey _registerKey = GlobalKey();

  double _loginHeight = 0;
  double _registerHeight = 0;
  double _targetHeight = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateMeasuredHeights(),
    );
    // Delay the form visibility slightly so we can fade it in
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showForm = true);
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) setState(() => _isLoading = false);

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Masuk gagal. Periksa email dan kata sandi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTabChanged() {
    if (_tabController == null) return;
    if (!_tabController!.indexIsChanging) return;
    final h = _tabController!.index == 0 ? _loginHeight : _registerHeight;
    if (h > 0) {
      setState(() => _targetHeight = h);
    } else {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateMeasuredHeights(),
      );
    }
  }

  void _updateMeasuredHeights() {
    double measure(GlobalKey k) {
      final ctx = k.currentContext;
      if (ctx == null) return 0;
      final r = ctx.findRenderObject();
      if (r is RenderBox) return r.size.height;
      return 0;
    }

    final l = measure(_loginKey);
    final r = measure(_registerKey);

    setState(() {
      _loginHeight = l;
      _registerHeight = r;
      final currentIndex = _tabController?.index ?? 0;
      _targetHeight = currentIndex == 0
          ? (_loginHeight > 0 ? _loginHeight : _targetHeight)
          : (_registerHeight > 0 ? _registerHeight : _targetHeight);
      if (_targetHeight == 0) _targetHeight = 360;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.25, 0.75, 1.0],
            colors: [
              const Color(0xFF64B5F6),
              const Color(0xFF0D47A1),
              const Color(0xFF0D47A1),
              const Color(0xFF64B5F6),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSlide(
                  offset: _showForm ? Offset.zero : Offset(0, 0.03),
                  duration: Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: _showForm ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontFamily: 'Product Sans',
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
                        SizedBox(height: 8),
                        Text(
                          'Kelola tugas pribadi dan kelompok dengan mudah',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                AnimatedSlide(
                  offset: _showForm ? Offset.zero : Offset(0, 0.03),
                  duration: Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: _showForm ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 700),
                      margin: EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(0, 0, 0, 0),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: EdgeInsets.all(20),
                            color: Colors.white.withOpacity(0.12),
                            child: Column(
                              children: [
                                SizedBox.shrink(),
                                TabBar(
                                  controller: _tabController,
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.white70,
                                  indicatorColor: Colors.white,
                                  tabs: [
                                    Tab(text: 'Masuk'),
                                    Tab(text: 'Daftar'),
                                  ],
                                ),
                                SizedBox(height: 12),
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                  height: _targetHeight > 0
                                      ? _targetHeight
                                      : null,
                                  child: IndexedStack(
                                    index: _tabController?.index ?? 0,
                                    children: [
                                      Container(
                                        key: _loginKey,
                                        child: SingleChildScrollView(
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Form(
                                              key: _formKey,
                                              child: Column(
                                                children: [
                                                  SizedBox(height: 12),
                                                  Text(
                                                    'Silakan masuk untuk melanjutkan',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  SizedBox(height: 18),
                                                  TextFormField(
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                    controller:
                                                        _emailController,
                                                    decoration: InputDecoration(
                                                      labelText: 'Email',
                                                      labelStyle: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Colors
                                                                      .white24,
                                                                ),
                                                          ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                      prefixIcon: Icon(
                                                        Icons.email,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                    keyboardType: TextInputType
                                                        .emailAddress,
                                                    validator: (v) {
                                                      if (v == null ||
                                                          v.isEmpty) {
                                                        return 'Email harus diisi';
                                                      }
                                                      if (!v.contains('@')) {
                                                        return 'Email tidak valid';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                  SizedBox(height: 16),
                                                  TextFormField(
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                    controller:
                                                        _passwordController,
                                                    decoration: InputDecoration(
                                                      labelText: 'Kata Sandi',
                                                      labelStyle: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Colors
                                                                      .white24,
                                                                ),
                                                          ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                      prefixIcon: Icon(
                                                        Icons.lock,
                                                        color: Colors.white70,
                                                      ),
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                          _obscurePassword
                                                              ? Icons.visibility
                                                              : Icons
                                                                    .visibility_off,
                                                          color: Colors.white70,
                                                        ),
                                                        onPressed: () => setState(
                                                          () => _obscurePassword =
                                                              !_obscurePassword,
                                                        ),
                                                      ),
                                                    ),
                                                    obscureText:
                                                        _obscurePassword,
                                                    validator: (v) {
                                                      if (v == null ||
                                                          v.isEmpty) {
                                                        return 'Kata Sandi harus diisi';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                  SizedBox(height: 20),
                                                  _isLoading
                                                      ? Column(
                                                          children: [
                                                            CircularProgressIndicator(
                                                              valueColor:
                                                                  AlwaysStoppedAnimation(
                                                                    Colors
                                                                        .white,
                                                                  ),
                                                            ),
                                                            SizedBox(
                                                              height: 12,
                                                            ),
                                                          ],
                                                        )
                                                      : SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: ElevatedButton(
                                                            onPressed: _login,
                                                            style: ElevatedButton.styleFrom(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        15,
                                                                  ),
                                                              backgroundColor:
                                                                  const Color(
                                                                    0xFF0D47A1,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              'Masuk',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                  SizedBox(height: 16),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      Container(
                                        key: _registerKey,
                                        child: SingleChildScrollView(
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: RegisterScreen(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
