import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'signup_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'report_issue_screen.dart';
import 'help_center_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _liveLocationEnabled = true;
  bool _notificationsEnabled = true;
  final String _currentLanguage = 'English';
  final String _appearance = 'Light';
  User? _user;

  final Color _primaryColor = const Color(0xFF007AFF);
  final Color _backgroundColor = const Color(0xFFF2F2F7);
  final Color _cardColor = Colors.white;
  final TextStyle _headerStyle = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1C1C1E),
  );
  final TextStyle _titleStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1C1C1E),
  );
  final TextStyle _subtitleStyle = const TextStyle(
    fontSize: 14,
    color: Color(0xFF8E8E93),
  );

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Fluttertoast.showToast(
      msg: "Signed out successfully!",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.white.withOpacity(0.9),
      textColor: Colors.black,
      fontSize: 16.0,
    );
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  Future<void> _navigateToEditProfile() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const EditProfileScreen()),
    );
    // Reload user data after returning from EditProfileScreen
    if (mounted) {
      await _user?.reload();
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 1,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.7),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildProfileSection()),
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Account',
              children: [
                _buildListTile(
                  title: 'Emergency Contacts',
                  icon: CupertinoIcons.phone_badge_plus,
                  showDivider: true,
                  onTap: () {},
                ),
                _buildListTile(
                  title: 'ID Verification',
                  icon: CupertinoIcons.checkmark_shield,
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Safety',
              children: [
                _buildSwitchTile(
                  title: 'Live Location Sharing',
                  subtitle:
                      'Allow trusted contacts to see your location during emergencies',
                  icon: CupertinoIcons.location_circle,
                  value: _liveLocationEnabled,
                  onChanged: (value) {
                    setState(() => _liveLocationEnabled = value);
                  },
                ),
                _buildListTile(
                  title: 'Safe Zones',
                  icon: CupertinoIcons.map,
                  subtitle: '3 zones configured',
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Preferences',
              children: [
                _buildSwitchTile(
                  title: 'Notifications',
                  subtitle: 'Alerts, sounds and badges',
                  icon: CupertinoIcons.bell,
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                _buildListTile(
                  title: 'Appearance',
                  icon: CupertinoIcons.sun_max,
                  trailing: Text(_appearance, style: _subtitleStyle),
                  showDivider: true,
                  onTap: () {},
                ),
                _buildListTile(
                  title: 'Language',
                  icon: CupertinoIcons.globe,
                  trailing: Text(_currentLanguage, style: _subtitleStyle),
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Support',
              children: [
                _buildListTile(
                  title: 'Help Center',
                  icon: CupertinoIcons.question_circle,
                  showDivider: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const HelpCenterScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  title: 'Report an Issue',
                  icon: CupertinoIcons.exclamationmark_circle,
                  showDivider: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const ReportIssueScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  title: 'Privacy Policy',
                  icon: CupertinoIcons.doc_text,
                  showDivider: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _buildFooter()),
          SliverToBoxAdapter(child: _buildSignOutButton()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    String displayName = _user?.displayName ?? 'User';
    String email = _user?.email ?? 'No email';
    String? photoUrl = _user?.photoURL;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _primaryColor.withOpacity(0.2),
                width: 3,
              ),
              image: DecorationImage(
                image:
                    photoUrl != null
                        ? NetworkImage(photoUrl)
                        : const AssetImage('assets/images/profile.jpg')
                            as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 16,
                    ),
                    minimumSize: const Size(0, 0),
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _navigateToEditProfile,
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    String? subtitle,
    bool showDivider = true,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _primaryColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _titleStyle),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(subtitle, style: _subtitleStyle),
                        ),
                    ],
                  ),
                ),
                trailing ??
                    const Icon(
                      CupertinoIcons.chevron_right,
                      color: CupertinoColors.systemGrey,
                      size: 18,
                    ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _titleStyle),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(subtitle, style: _subtitleStyle),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: value,
                activeTrackColor: _primaryColor,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 68),
          child: Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Image.asset(
            'assets/images/SHIELD_LOGO-NOBG.png',
            height: 40,
            color: _primaryColor.withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            'Kavach App',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.2.0 (45)',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const TermsOfServiceScreen(),
                    ),
                  );
                },
                child: Text(
                  'Terms of Service',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
              Text(
                '•',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        onPressed: () {
          showCupertinoDialog(
            context: context,
            builder:
                (context) => CupertinoAlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text(
                    'Are you sure you want to sign out from Kavach?',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: _signOut,
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.square_arrow_left,
              size: 18,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
