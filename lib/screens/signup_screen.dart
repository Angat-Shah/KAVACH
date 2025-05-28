import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'phone_screen.dart';
import 'email_screen.dart';
import 'login_screen.dart';
import '../main.dart';
import 'package:kavach_hackvortex/services/auth_service.dart';
import 'home_screen.dart';
import 'package:camera/camera.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      print('Starting Google Sign-In process...');

      // Initialize GoogleSignIn with platform-specific configuration
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: Platform.isIOS
            ? '28593247285-aagtr369vh3hk1c8jh3arsijf521pj6o.apps.googleusercontent.com'
            : '28593247285-ln7h3dfdmp1r0da804ia00v7cjter5n8.apps.googleusercontent.com',
        serverClientId:
            '28593247285-t3pd1ju7q11bj65cs8d9bqardmkh4h0g.apps.googleusercontent.com',
      );

      // First, sign out any existing Google session
      try {
        await googleSignIn.signOut();
        print('Successfully signed out from previous session');
      } catch (e) {
        print('Error signing out from previous session: $e');
      }

      print('Attempting to sign in with Google...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('User cancelled the sign-in');
        setState(() => _isLoading = false);
        return;
      }
      print('Successfully got Google user: ${googleUser.email}');

      print('Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }
      print('Successfully got authentication tokens');

      print('Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in with Firebase...');
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to sign in with Google');
      }
      print('Successfully signed in with Firebase');

      final myApp = context.findAncestorWidgetOfExactType<MyApp>();
      final chatService = myApp?.chatService;

      if (!mounted || chatService == null) {
        print('Error: Chat service not available');
        setState(() => _isLoading = false);
        return;
      }

      // Initialize camera
      CameraDescription? camera;
      try {
        final cameras = await availableCameras();
        camera = cameras.isNotEmpty ? cameras.first : null;
        print('Camera initialized successfully');
      } catch (e) {
        print('Error initializing camera: $e');
      }

      if (!mounted) return;

      print('Navigating to HomeScreen...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(camera: camera, chatService: chatService),
        ),
      );
    } catch (e, stackTrace) {
      print('Google Sign-In error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  alignment: Alignment.center,
                  child: Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF007AFF), Color(0xFF0056B3)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ClassicShieldIcon(size: 90, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics:
                        const NeverScrollableScrollPhysics(), // 👈 disables scrolling completely
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose a sign up method',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF86868B),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildAppleButton(
                            onTap: () => _navigateWithLoading(context, 'login'),
                            label: 'Sign in with Apple',
                            icon: CupertinoIcons.person_fill,
                          ),
                          const SizedBox(height: 16),
                          _buildSecondaryButton(
                            onTap: _signUpWithGoogle,
                            label: 'Sign in with Google',
                            icon: FontAwesomeIcons.google,
                          ),
                          const SizedBox(height: 16),
                          _buildSecondaryButton(
                            onTap: () => _navigateWithLoading(context, 'email'),
                            label: 'Sign up with Email',
                            icon: CupertinoIcons.mail_solid,
                          ),
                          const SizedBox(height: 16),
                          _buildSecondaryButton(
                            onTap: () => _navigateWithLoading(context, 'phone'),
                            label: 'Sign up with Phone',
                            icon: CupertinoIcons.phone_fill,
                          ),
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: () => _navigateWithLoading(context, 'login'),
                            child: const Text.rich(
                              TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Color(0xFF86868B),
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                      color: Color(0xFF0066CC),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text.rich(
                              TextSpan(
                                text: 'By continuing, you agree to our ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF86868B),
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(color: Color(0xFF0066CC)),
                                  ),
                                  TextSpan(
                                    text:
                                        ' and acknowledge that you have read our ',
                                  ),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(color: Color(0xFF0066CC)),
                                  ),
                                  TextSpan(
                                    text:
                                        ' to learn how we collect, use, and share your data.',
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
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

  Widget _buildAppleButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
  }) {
    return CupertinoButton(
      onPressed: _isLoading ? null : onTap,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
  }) {
    return CupertinoButton(
      onPressed: _isLoading ? null : onTap,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD2D2D7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1D1D1F), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1D1D1F),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateWithLoading(BuildContext context, String route) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CupertinoActivityIndicator(radius: 15)),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    Navigator.pop(context);

    final myApp = context.findAncestorWidgetOfExactType<MyApp>();
    final chatService = myApp?.chatService;

    if (chatService == null) return;

    switch (route) {
      case 'phone':
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const PhoneScreen()),
        );
        break;
      case 'email':
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const EmailScreen()),
        );
        break;
      case 'login':
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const LoginScreen()),
        );
        break;
    }
  }
}

class ClassicShieldIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ClassicShieldIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: ClassicShieldPainter(color: color),
    );
  }
}

class ClassicShieldPainter extends CustomPainter {
  final Color color;

  ClassicShieldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path shieldPath = Path();
    shieldPath.moveTo(size.width * 0.5, size.height * 0.1);
    shieldPath.lineTo(size.width * 0.15, size.height * 0.25);
    shieldPath.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.9,
    );
    shieldPath.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.7,
      size.width * 0.85,
      size.height * 0.25,
    );
    shieldPath.lineTo(size.width * 0.5, size.height * 0.1);
    shieldPath.close();

    canvas.drawPath(shieldPath, fillPaint);

    final Path innerPath = Path();
    innerPath.moveTo(size.width * 0.5, size.height * 0.25);
    innerPath.lineTo(size.width * 0.3, size.height * 0.4);
    innerPath.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.6,
      size.width * 0.5,
      size.height * 0.7,
    );
    innerPath.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.6,
      size.width * 0.7,
      size.height * 0.4,
    );
    innerPath.lineTo(size.width * 0.5, size.height * 0.25);
    innerPath.close();

    final Paint innerPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, innerPaint);

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.48),
      size.width * 0.06,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}