import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
                _buildSectionTitle('Kavach Terms of Service'),
                _buildParagraph(
                  'Effective Date: April 28, 2025\n\n'
                  'These Terms of Service govern your use of the Kavach mobile application. By using the app, you agree to these terms. If you do not agree, please discontinue use.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('1. Acceptance of Terms'),
                _buildParagraph(
                  'By accessing or using Kavach, you agree to be bound by these Terms of Service, our Privacy Policy, and any additional guidelines provided in the app. These terms may be updated periodically, and continued use constitutes acceptance of changes.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('2. Use of the App'),
                _buildSubSectionTitle('Permitted Use'),
                _buildParagraph(
                  'Kavach is intended for reporting crimes, accessing safety resources, and managing emergency contacts. You agree to use the app only for lawful purposes and in compliance with local regulations.',
                ),
                _buildSubSectionTitle('Prohibited Activities'),
                _buildParagraph(
                  'You may not:\n'
                  '• Use the app to submit false or misleading reports\n'
                  '• Attempt to hack, modify, or disrupt the app’s functionality\n'
                  '• Use the app for commercial purposes without permission\n'
                  '• Violate the rights of other users or third parties',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('3. User Responsibilities'),
                _buildParagraph(
                  'You are responsible for:\n'
                  '• Providing accurate information during crime reporting\n'
                  '• Maintaining the confidentiality of your account credentials\n'
                  '• Ensuring your device is secure and updated\n'
                  '• Complying with all applicable laws and regulations',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('4. Intellectual Property'),
                _buildParagraph(
                  'All content, logos, and features in Kavach are the property of Kavach Technologies or its licensors. You may not reproduce, distribute, or create derivative works without explicit permission.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('5. Limitation of Liability'),
                _buildParagraph(
                  'Kavach is provided "as is" without warranties of any kind. We are not liable for:\n'
                  '• Inaccuracies in safety advice provided by Safety Buddy\n'
                  '• Delays or failures in crime report processing\n'
                  '• Damages arising from unauthorized access to your account\n'
                  '• Any indirect, incidental, or consequential damages',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('6. Termination'),
                _buildParagraph(
                  'We may suspend or terminate your access to Kavach if you violate these terms or engage in activities that harm the app or its users. You may discontinue use at any time by deleting the app.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('7. Governing Law'),
                _buildParagraph(
                  'These terms are governed by the laws of India. Any disputes will be resolved in the courts of New Delhi, India.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('8. Contact Us'),
                _buildParagraph(
                  'For questions about these Terms of Service, contact us at:\n'
                  'Email: support@kavachapp.com\n'
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