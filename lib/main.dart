import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kavach_hackvortex/firebase_options.dart';
import 'package:kavach_hackvortex/screens/home_screen.dart';
import 'package:kavach_hackvortex/screens/splash_screen.dart';
import 'package:kavach_hackvortex/screens/signup_screen.dart';
import 'package:camera/camera.dart';
import 'package:kavach_hackvortex/services/chat_service.dart';
import 'dart:io' show Platform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

late ChatService globalChatService;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await dotenv.load(fileName: "assets/.env");
  final chatService = await ChatService.create();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MyApp(chatService: chatService));
}

class MyApp extends StatefulWidget {
  final ChatService chatService;
  const MyApp({super.key, required this.chatService});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<CameraDescription?> _camera;

  @override
  void initState() {
    super.initState();
    _camera = _initializeCamera();
  }

  Future<CameraDescription?> _initializeCamera() async {
    try {
      if (Platform.isIOS && await _isSimulator()) {
        print('Running on iOS Simulator, skipping camera initialization.');
        return null; // Simulator proceeds without camera
      }
      final cameras = await availableCameras();
      return cameras.isNotEmpty ? cameras.first : null;
    } catch (e) {
      print('Error initializing camera: $e');
      return null;
    }
  }

  Future<bool> _isSimulator() async {
    return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CameraDescription?>(
      future: _camera,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        // Always proceed to HomeScreen, even if camera is null
        return MaterialApp(
          title: 'Kavach',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (authSnapshot.hasData) {
                return HomeScreen(
                  camera: snapshot.data,
                  chatService: widget.chatService,
                );
              }
              return SplashScreen(chatService: widget.chatService);
            },
          ),
          debugShowCheckedModeBanner: false,
          routes: {'/signup': (context) => const SignUpScreen()},
        );
      },
    );
  }
}

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'https://www.googleapis.com/auth/contacts.readonly'],
);

Future<UserCredential> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign in was cancelled');

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (e) {
    print('Error signing in with Google: $e');
    throw Exception('Failed to sign in with Google: $e');
  }
}