import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:camera/camera.dart';
import '../main.dart';
import 'home_screen.dart';
import 'otp_verification_screen.dart';
import 'package:kavach_hackvortex/services/auth_service.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isFormFilled() {
    return _phoneController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _signUpWithPhone() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    print('Starting phone sign-up process...');

    try {
      final phoneNumber = '+91${_phoneController.text.trim()}';
      final password = _passwordController.text.trim();

      print('Phone number: $phoneNumber');
      print('Starting phone verification...');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // First, try to sign out any existing user
      try {
        await FirebaseAuth.instance.signOut();
        print('Successfully signed out any existing user');
      } catch (e) {
        print('No existing user to sign out: $e');
      }

      // Add a delay before verification to prevent rapid requests
      await Future.delayed(const Duration(seconds: 2));

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('Phone verification completed automatically');
          try {
            print('Signing in with phone credential...');
            final userCredential = await FirebaseAuth.instance
                .signInWithCredential(credential);

            if (userCredential.user == null) {
              throw Exception('Failed to sign in with phone');
            }
            print('Successfully signed in with phone');

            // Update password if needed
            if (password.isNotEmpty) {
              print('Updating password...');
              await userCredential.user?.updatePassword(password);
            }

            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              _navigateToHome();
            }
          } catch (e) {
            print('Phone verification completed error: $e');
            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              setState(() => _isLoading = false);
              Fluttertoast.showToast(
                msg: 'Error during verification: ${e.toString()}',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                backgroundColor: Colors.red.withOpacity(0.9),
                textColor: Colors.white,
                fontSize: 16.0,
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Phone verification failed: ${e.code} - ${e.message}');
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            setState(() => _isLoading = false);
            String message;
            switch (e.code) {
              case 'invalid-phone-number':
                message = 'The phone number is invalid.';
                break;
              case 'too-many-requests':
                message =
                    'Too many verification attempts. Please wait for 30 minutes before trying again.';
                break;
              case 'quota-exceeded':
                message = 'SMS quota exceeded. Please try again later.';
                break;
              case 'invalid-verification-code':
                message = 'Invalid verification code.';
                break;
              case 'session-expired':
                message = 'Session expired. Please try again.';
                break;
              case 'internal-error':
                message =
                    'Please try again in a few minutes. If the issue persists, try restarting the app.';
                break;
              default:
                message = 'An error occurred: ${e.message}';
            }
            Fluttertoast.showToast(
              msg: message,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.red.withOpacity(0.9),
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Verification code sent successfully');
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPVerificationScreen(
                  verificationId: verificationId,
                  phoneNumber: phoneNumber,
                  password: password,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto-retrieval timeout');
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            setState(() => _isLoading = false);
            Fluttertoast.showToast(
              msg: 'Auto-retrieval timeout. Please enter the code manually.',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.orange.withOpacity(0.9),
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('Phone sign-in error: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red.withOpacity(0.9),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  void _navigateToHome() async {
    final myApp = context.findAncestorWidgetOfExactType<MyApp>();
    final chatService = myApp?.chatService;

    if (chatService == null) {
      Fluttertoast.showToast(
        msg: "Error: Unable to access chat service.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red.withOpacity(0.9),
        textColor: Colors.white,
      );
      return;
    }

    CameraDescription? camera;
    try {
      final cameras = await availableCameras();
      camera = cameras.isNotEmpty ? cameras.first : null;
    } catch (e) {
      print('Error initializing camera: $e');
    }

    if (!mounted) return;

    Fluttertoast.showToast(
      msg: "Account created successfully!",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.white.withOpacity(0.9),
      textColor: Colors.black,
      fontSize: 16.0,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HomeScreen(camera: camera, chatService: chatService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leadingWidth: 80,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_back,
                color: Colors.blueAccent,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.phone_iphone,
                color: Color(0xFF1F2937),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Kavach',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Continue with your phone number',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildInputField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                          return 'Enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Create a password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        } else if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      isLast: true,
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading || !_isFormFilled()
                            ? null
                            : _signUpWithPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F2937),
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword ? _obscurePassword : false,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1F2937),
                  width: 1,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
            ),
            style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
            validator: validator,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}