import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kavach_hackvortex/screens/signup_screen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;

  // Colors and styles to match settings screen
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

  // Admin stats
  int _reportsReviewed = 0;
  int _reportsAccepted = 0;
  int _reportsRejected = 0;
  int _newsReviewed = 0;
  int _newsMarkedGenuine = 0;
  int _newsMarkedFake = 0;
  int _incidentsAdded = 0;

  // Activity history
  final List<Map<String, dynamic>> _activityLog = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _reportsReviewed = 127;
      _reportsAccepted = 86;
      _reportsRejected = 41;
      _newsReviewed = 94;
      _newsMarkedGenuine = 67;
      _newsMarkedFake = 27;
      _incidentsAdded = 53;

      _activityLog.addAll([
        {
          'type': 'report',
          'action': 'Accepted report',
          'title': 'Traffic Violation',
          'time': DateTime.now().subtract(const Duration(hours: 2)),
        },
        {
          'type': 'news',
          'action': 'Marked news as fake',
          'title': 'Viral Social Media Post',
          'time': DateTime.now().subtract(const Duration(hours: 4)),
        },
        {
          'type': 'map',
          'action': 'Added incident',
          'title': 'Road Closure',
          'time': DateTime.now().subtract(const Duration(hours: 6)),
        },
        {
          'type': 'report',
          'action': 'Rejected report',
          'title': 'False Complaint',
          'time': DateTime.now().subtract(const Duration(hours: 7)),
        },
        {
          'type': 'news',
          'action': 'Marked news as genuine',
          'title': 'Government Announcement',
          'time': DateTime.now().subtract(const Duration(hours: 9)),
        },
      ]);

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Admin Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 1,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.7),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildProfileHeader()),
                  SliverToBoxAdapter(
                    child: _buildSection(
                      title: 'Activity Stats',
                      children: [_buildStatCards()],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSection(
                      title: 'Weekly Activity',
                      children: [_buildActivityChart()],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSection(
                      title: 'Recent Activity',
                      children: [_buildRecentActivityLog()],
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildFooter()),
                  SliverToBoxAdapter(child: _buildSignOutButton()),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
    );
  }

  Widget _buildProfileHeader() {
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
              color: Colors.blue.shade100,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 40, color: Colors.blue),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin User',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Senior Admin • Delhi Division',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Active'),
                    const SizedBox(width: 16),
                    Icon(Icons.verified, color: _primaryColor, size: 16),
                    const SizedBox(width: 4),
                    const Text('Verified'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Reports',
                  _reportsReviewed.toString(),
                  Icons.description,
                  Colors.blue,
                  'Accepted: $_reportsAccepted\nRejected: $_reportsRejected',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'News',
                  _newsReviewed.toString(),
                  Icons.newspaper,
                  Colors.orange,
                  'Genuine: $_newsMarkedGenuine\nFake: $_newsMarkedFake',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Incidents',
                  _incidentsAdded.toString(),
                  Icons.map,
                  Colors.green,
                  'Added to map',
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(title, style: _titleStyle),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: _subtitleStyle),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(),
        series: <CartesianSeries>[
          ColumnSeries<ChartData, String>(
            dataSource: [
              ChartData('M', 12, 8, 6),
              ChartData('T', 8, 10, 5),
              ChartData('W', 15, 6, 4),
              ChartData('T', 10, 9, 7),
              ChartData('F', 7, 12, 6),
              ChartData('S', 5, 3, 2),
              ChartData('S', 3, 2, 1),
            ],
            xValueMapper: (ChartData data, _) => data.day,
            yValueMapper: (ChartData data, _) => data.reports,
            name: 'Reports',
            color: Colors.blue,
            width: 0.8,
          ),
          ColumnSeries<ChartData, String>(
            dataSource: [
              ChartData('M', 12, 8, 6),
              ChartData('T', 8, 10, 5),
              ChartData('W', 15, 6, 4),
              ChartData('T', 10, 9, 7),
              ChartData('F', 7, 12, 6),
              ChartData('S', 5, 3, 2),
              ChartData('S', 3, 2, 1),
            ],
            xValueMapper: (ChartData data, _) => data.day,
            yValueMapper: (ChartData data, _) => data.news,
            name: 'News',
            color: Colors.orange,
            width: 0.8,
          ),
          ColumnSeries<ChartData, String>(
            dataSource: [
              ChartData('M', 12, 8, 6),
              ChartData('T', 8, 10, 5),
              ChartData('W', 15, 6, 4),
              ChartData('T', 10, 9, 7),
              ChartData('F', 7, 12, 6),
              ChartData('S', 5, 3, 2),
              ChartData('S', 3, 2, 1),
            ],
            xValueMapper: (ChartData data, _) => data.day,
            yValueMapper: (ChartData data, _) => data.incidents,
            name: 'Incidents',
            color: Colors.green,
            width: 0.8,
          ),
        ],
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
      ),
    );
  }

  Widget _buildRecentActivityLog() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _activityLog.length,
        itemBuilder: (context, index) {
          final activity = _activityLog[index];
          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getActivityColor(activity['type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _getActivityIcon(activity['type']),
                ),
                title: Text(activity['action'], style: _titleStyle),
                subtitle: Text(activity['title'], style: _subtitleStyle),
                trailing: Text(
                  _formatTimeAgo(activity['time']),
                  style: _subtitleStyle,
                ),
              ),
              if (index < _activityLog.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Divider(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'report':
        return Colors.blue;
      case 'news':
        return Colors.orange;
      case 'map':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Icon _getActivityIcon(String type) {
    switch (type) {
      case 'report':
        return const Icon(Icons.description, color: Colors.blue, size: 20);
      case 'news':
        return const Icon(Icons.newspaper, color: Colors.orange, size: 20);
      case 'map':
        return const Icon(Icons.map, color: Colors.green, size: 20);
      default:
        return const Icon(Icons.info, color: Colors.grey, size: 20);
    }
  }

  String _formatTimeAgo(DateTime date) {
    final Duration difference = DateTime.now().difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 40,
            color: _primaryColor.withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            'Kavach Admin Panel',
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
                    'Are you sure you want to sign out from Kavach Admin?',
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: const Text('Settings options will be available here.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class ChartData {
  final String day;
  final int reports;
  final int news;
  final int incidents;

  ChartData(this.day, this.reports, this.news, this.incidents);
}