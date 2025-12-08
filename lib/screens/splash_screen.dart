import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showContent = false;
  @override
  void initState() {
    super.initState();
    _navigateToNext();
    // Small delay before showing content so we can animate appearance
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  _navigateToNext() {
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showContent = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Create a diagonal background gradient from light-blue -> dark-blue -> light-blue
    return Scaffold(
<<<<<<< HEAD
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.25, 0.75, 1.0],
            colors: [
              // light blue at top-left
              const Color(0xFF64B5F6),
              // dark blue in the middle
              const Color(0xFF0D47A1),
              const Color(0xFF0D47A1),
              // back to light blue at bottom-right
              const Color(0xFF64B5F6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSlide(
                offset: _showContent ? Offset.zero : const Offset(0, 0.05),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  child: Icon(Icons.assignment, size: 80, color: Colors.white),
                ),
=======
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 80, color: Colors.white),
            SizedBox(height: 20),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Edu',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  TextSpan(
                    text: 'Track',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
>>>>>>> f2e3d166f6881b2d555229faf4872a27c63e8582
              ),
              SizedBox(height: 20),
              AnimatedSlide(
                offset: _showContent ? Offset.zero : const Offset(0, 0.05),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Edu',
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Product Sans',
                          ),
                        ),
                        TextSpan(
                          text: 'Track',
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Product Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              AnimatedSlide(
                offset: _showContent ? Offset.zero : const Offset(0, 0.05),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
