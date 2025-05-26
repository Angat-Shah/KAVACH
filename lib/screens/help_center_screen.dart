import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
          'Help Center',
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
                _buildSectionTitle('Welcome to Kavach Help Center'),
                _buildParagraph(
                  'The Kavach Help Center is designed to assist you in navigating the app, reporting issues, and ensuring your safety. Below, you’ll find detailed guides, FAQs, and contact options to get the support you need.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Frequently Asked Questions'),
                _buildSubSectionTitle('How do I report a crime?'),
                _buildParagraph(
                  'To report a crime, navigate to the "Report a Crime" section from the home screen. Fill out the personal information form, including your Aadhaar number for verification, and proceed to the incident details screen. Ensure all details are accurate before submission. The process is designed to be secure and compliant with local regulations.',
                ),
                _buildSubSectionTitle('How does Safety Buddy work?'),
                _buildParagraph(
                  'Safety Buddy is an AI-powered chatbot that provides real-time safety advice and emergency guidance. Access it from the main menu, type your query, or select from predefined prompts like "Report an emergency" or "First aid basics." The chatbot uses advanced algorithms to deliver accurate responses tailored to your needs.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('App Guides'),
                _buildSubSectionTitle('Setting Up Emergency Contacts'),
                _buildParagraph(
                  'Go to Settings > Account > Emergency Contacts to add trusted contacts. These individuals can receive alerts during emergencies if Live Location Sharing is enabled. Ensure you have their consent before adding them. You can configure up to five contacts with verified phone numbers.',
                ),
                _buildSubSectionTitle('Configuring Safe Zones'),
                _buildParagraph(
                  'Safe Zones allow you to designate areas where you feel secure, such as home or work. Navigate to Settings > Safety > Safe Zones to set up to three zones. The app will notify you if you exit these zones during an emergency, enhancing your safety.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Contact Support'),
                _buildParagraph(
                  'If you need further assistance, our support team is available 24/7. Email us at support@kavachapp.com or call our toll-free number 1800-123-4567. For urgent issues, use the "Report an Issue" option in Settings to submit a detailed report directly to our team.',
                ),
                _buildSubSectionTitle('Live Chat Support'),
                _buildParagraph(
                  'Our live chat feature connects you with a support agent instantly. Available from 9 AM to 9 PM IST, this service ensures quick resolution of technical or safety-related queries. Access it via the "Chat with Us" button in the app’s support section.',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Troubleshooting'),
                _buildParagraph(
                  'If the app crashes or fails to load, ensure you’re using the latest version (check Settings > About). Clear the app cache from your device settings, restart the app, and verify your internet connection. For persistent issues, contact support with your device details and app version.',
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