import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Updated onboarding pages with more Apple-like approach
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Broadcast Crime\nLive',
      description:
          'Share real-time incidents securely with authorities and emergency contacts when you need help.',
      image: CupertinoIcons.videocam_fill,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF34C759),
          Color(0xFF30B0C7),
        ], // Apple red to orange gradient
      ),
    ),
    OnboardingPage(
      title: 'Report Crime\nInstantly',
      description:
          'File detailed reports with a few taps and help keep your community informed and safe.',
      image: CupertinoIcons.exclamationmark_shield_fill,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5856D6), Color(0xFFAF52DE)], // Apple purple gradient
      ),
    ),
    OnboardingPage(
      title: 'Know Crime\nHotspots',
      description:
          'View detailed safety maps and receive notifications about high-risk areas nearby.',
      image: CupertinoIcons.map_fill,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFCC00),
          Color(0xFFFF9500),
        ], // Apple yellow to orange gradient
      ),
    ),
    OnboardingPage(
      title: 'Safety Buddy\nAssistance',
      description:
          'Get personalized safety recommendations and instant guidance when you need it most.',
      image: CupertinoIcons.chat_bubble_text_fill,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF64D2FF), Color(0xFF0A84FF)], // Apple blue gradient
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Set up system UI to match Apple styling
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Apple background color
      body: SafeArea(
        child: Column(
          children: [
            // Skip button - Apple style
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Navigate to SignUp Screen with Apple-style transition
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF007AFF), // Apple blue
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing:
                          -0.41, // Apple's characteristic letter spacing
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return buildPageContent(_pages[index]);
                },
              ),
            ),

            // Dots indicator - Apple style
            Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => buildDot(index),
                ),
              ),
            ),

            // Next/Continue button - Apple style
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: CupertinoButton(
                onPressed: () {
                  if (_currentPage == _pages.length - 1) {
                    // Navigate to the SignUp Screen with Apple-style transition
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves
                          .easeOutQuart, // Apple's characteristic animation curve
                    );
                  }
                },
                padding: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _pages[_currentPage].gradient.colors[0],
                        _pages[_currentPage].gradient.colors[1],
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      14,
                    ), // Apple's button corner radius
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Continue' : 'Next',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.41,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the content for each onboarding page - Apple style
  Widget buildPageContent(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: page.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.gradient.colors[1].withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(page.image, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 48),

          // Title - Apple SF Pro Display style
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700, // SF Pro Display Bold
              color: Color(0xFF1D1D1F), // Apple text color
              letterSpacing: -0.41,
              height: 1.1, // Apple's tight line height
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description - Apple SF Pro Text style
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400, // SF Pro Text Regular
              color: Color(0xFF86868B), // Apple secondary text color
              letterSpacing: -0.41,
              height: 1.3, // Apple paragraph spacing
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build the dots indicator for page view - Apple style
  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? _pages[_currentPage].gradient.colors[1]
            : const Color(0xFFDDDDDD), // Apple light gray for inactive
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData image;
  final LinearGradient gradient;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.gradient,
  });
}
