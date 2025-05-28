import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kavach/screens/chatbot_screen.dart';
import 'package:kavach/services/chat_service.dart';

class ChatIntroScreen extends StatelessWidget {
  final ChatService chatService;

  const ChatIntroScreen({super.key, required this.chatService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0xFF000000).withOpacity(0.7),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            const Text(
              'Safety Buddy',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meet Safety Buddy',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111111),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your 24/7 personal safety assistant. Get instant help, safety tips and emergency guidance with our AI-powered chatbot.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) =>
                                ChatScreen(chatService: chatService),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17272D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.chat_bubble_text,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Start New Chat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What Safety Buddy Can Do',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111111),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore the powerful features of your safety assistant.',
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    _buildFeatureCard(
                      title: 'Emergency Guidance',
                      icon: CupertinoIcons.exclamationmark_shield,
                      description:
                          'Get step-by-step instructions during crises like fires, accidents or medical emergencies.',
                      iconColor: const Color(0xFFFF3B30),
                    ),
                    _buildFeatureCard(
                      title: 'Safety Tips',
                      icon: CupertinoIcons.lightbulb,
                      description:
                          'Receive personalized safety advice for home, travel or public spaces.',
                      iconColor: const Color(0xFF34C759),
                    ),
                    _buildFeatureCard(
                      title: 'Quick Reporting',
                      icon: CupertinoIcons.exclamationmark_triangle,
                      description:
                          'Report incidents or suspicious activities directly through chat.',
                      iconColor: const Color(0xFFFF9500),
                    ),
                    _buildFeatureCard(
                      title: 'Resource Finder',
                      icon: CupertinoIcons.location,
                      description:
                          'Locate nearby hospitals, police stations or safe zones instantly.',
                      iconColor: const Color(0xFF5AC8FA),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Safety Tips',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111111),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stay prepared with these essential tips.',
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildTipCard(
                      title: 'Emergency Contacts',
                      description:
                          'Save local emergency numbers and share your location with trusted contacts.',
                      icon: CupertinoIcons.person_crop_circle_badge_exclam,
                      backgroundColor: const Color(0xFFF2F2F7),
                      iconColor: const Color(0xFF5856D6),
                    ),
                    _buildTipCard(
                      title: 'Stay Alert',
                      description:
                          'Be aware of your surroundings and avoid isolated areas at night.',
                      icon: CupertinoIcons.eye,
                      backgroundColor: const Color(0xFFF2F2F7),
                      iconColor: const Color(0xFF007AFF),
                    ),
                    _buildTipCard(
                      title: 'Safety Plan',
                      description:
                          'Create a safety plan with escape routes and meeting points.',
                      icon: CupertinoIcons.map,
                      backgroundColor: const Color(0xFFF2F2F7),
                      iconColor: const Color(0xFFFF9500),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111111),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    _buildFAQItem(
                      question: 'How does Safety Buddy work?',
                      answer:
                          'Safety Buddy uses AI to provide real-time safety advice, emergency guidance or resource information based on your queries.',
                    ),
                    _buildFAQItem(
                      question: 'Is my conversation private?',
                      answer:
                          'Yes, your chats are encrypted and secure, to protect your privacy.',
                    ),
                    _buildFAQItem(
                      question: 'Can I report crimes anonymously?',
                      answer:
                          'Yes, you can report incidents anonymously through the chatbot.',
                    ),
                    _buildFAQItem(
                      question: 'What if I need urgent help?',
                      answer:
                          'For emergencies, use the "Report an Emergency" option to get immediate guidance and connect to local services.',
                    ),
                    _buildFAQItem(
                      question: 'How often is Safety Buddy updated?',
                      answer:
                          'Safety Buddy is regularly updated with the latest safety protocols and resources.',
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Kavach - Your Safety Companion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Built for your security and peace of mind.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required String description,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard({
    required String title,
    required String description,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.light(primary: Colors.grey[800]!),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
          trailing: const Icon(CupertinoIcons.chevron_down, size: 16),
          backgroundColor: const Color(0xFFF2F2F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}