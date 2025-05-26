import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 1,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.7),
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
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Color(0xFF000000),
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Kavach Privacy Policy'),
                _buildParagraph(
                  'Effective Date: April 28, 2025\n\n'
                  'Kavach is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this policy carefully.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('1. Information We Collect'),
                _buildSubSectionTitle('Personal Information'),
                _buildParagraph(
                  'We collect personal information you provide, such as your name, phone number, address, and Aadhaar number (masked for security). This information is used to verify your identity and process crime reports securely.',
                ),
                _buildSubSectionTitle('Location Data'),
                _buildParagraph(
                  'With your consent, we collect precise location data to enable features like Live Location Sharing and Safe Zones. You can disable location access at any time in your device settings.',
                ),
                _buildSubSectionTitle('Usage Data'),
                _buildParagraph(
                  'We collect information about how you interact with the app, including pages visited, features used, and crash reports. This data helps us improve the app’s performance and user experience.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('2. How We Use Your Information'),
                _buildParagraph(
                  'We use your information to:\n'
                  '• Process and verify crime reports\n'
                  '• Provide safety features like Safety Buddy and emergency alerts\n'
                  '• Improve app functionality and user experience\n'
                  '• Comply with legal obligations and ensure app security',
                ),
                _buildSubSectionTitle('Data Sharing'),
                _buildParagraph(
                  'We may share your information with:\n'
                  '• Law enforcement agencies for crime reporting purposes\n'
                  '• Trusted third-party service providers for analytics and support\n'
                  '• Emergency contacts with your explicit consent\n'
                  'We do not sell your personal information.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('3. Data Security'),
                _buildParagraph(
                  'We implement industry-standard security measures, including encryption and secure servers, to protect your data. However, no system is completely secure, and we cannot guarantee absolute security.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('4. Your Rights'),
                _buildParagraph(
                  'You have the right to:\n'
                  '• Access and update your personal information\n'
                  '• Request deletion of your data (subject to legal obligations)\n'
                  '• Opt out of location sharing and notifications\n'
                  'To exercise these rights, contact us at privacy@kavachapp.com.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('5. Children’s Privacy'),
                _buildParagraph(
                  'Kavach is not intended for users under 13. We do not knowingly collect personal information from children. If you believe we have collected such data, please contact us immediately.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('6. Changes to This Policy'),
                _buildParagraph(
                  'We may update this Privacy Policy periodically. Changes will be posted in the app, and significant updates will be notified via email or in-app alerts. Continued use of the app constitutes acceptance of the updated policy.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('7. Contact Us'),
                _buildParagraph(
                  'For questions or concerns about this Privacy Policy, contact us at:\n'
                  'Email: privacy@kavachapp.com\n'
                  'Phone: 1800-123-4567\n'
                  'Address: Kavach Technologies, 123 Safety Street, New Delhi, India',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111111),
        ),
      ),
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111111),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: Colors.grey[800],
      ),
    );
  }
}