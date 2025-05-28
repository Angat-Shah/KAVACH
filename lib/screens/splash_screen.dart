import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'package:camera/camera.dart';
import '../services/chat_service.dart';

class SplashScreen extends StatefulWidget {
  final ChatService chatService;
  const SplashScreen({super.key, required this.chatService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _backgroundBrightnessAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.8, end: 1.05),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.05, end: 1.0),
            weight: 40,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuart),
          ),
        );

    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.03),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.03, end: 1.0),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
          ),
        );

    _glowAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 16.0),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 16.0, end: 12.0),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
          ),
        );

    _backgroundBrightnessAnimation = Tween<double>(begin: 0.0, end: 0.2)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();

    _navigateBasedOnAuthState();
  }

  Future<void> _navigateBasedOnAuthState() async {
    await Future.delayed(const Duration(milliseconds: 3300));
    if (!mounted) return;

    // Initialize camera
    CameraDescription? camera;
    try {
      final cameras = await availableCameras();
      camera = cameras.isNotEmpty ? cameras.first : null;
    } catch (e) {
      print('Error initializing camera: $e');
    }

    final user = FirebaseAuth.instance.currentUser;
    Widget nextScreen;
    if (user != null) {
      nextScreen = HomeScreen(camera: camera, chatService: widget.chatService);
    } else {
      nextScreen = const OnboardingScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, 0.0),
                radius: 1.8,
                colors: [
                  Color.lerp(
                    Colors.black,
                    const Color(0xFF1A1A1A),
                    _backgroundBrightnessAnimation.value,
                  )!,
                  Colors.black,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: _logoOpacityAnimation.value,
                    child: Transform.scale(
                      scale: _logoScaleAnimation.value * _pulseAnimation.value,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.width * 0.5,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/LOGO-NOBG.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}