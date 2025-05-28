import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class NearbyAuthoritiesScreen extends StatefulWidget {
  const NearbyAuthoritiesScreen({super.key});

  @override
  _NearbyAuthoritiesScreenState createState() =>
      _NearbyAuthoritiesScreenState();
}

class _NearbyAuthoritiesScreenState extends State<NearbyAuthoritiesScreen>
    with SingleTickerProviderStateMixin {
  final List<AuthorityType> _authorityTypes = [
    AuthorityType(
      title: 'Police Stations',
      icon: Icons.local_police,
      color: const Color(0xFF3B82F6),
      lightColor: const Color(0xFFF0F9FF),
      description: 'Find nearby police stations for reporting crimes',
      searchQuery: 'police stations',
    ),
    AuthorityType(
      title: 'Fire Stations',
      icon: Icons.fire_truck,
      color: const Color(0xFFEF4444),
      lightColor: const Color(0xFFFEF2F2),
      description: 'Locate nearby fire stations for emergencies',
      searchQuery: 'fire stations',
    ),
    AuthorityType(
      title: 'Hospitals',
      icon: Icons.local_hospital,
      color: const Color(0xFF22C55E),
      lightColor: const Color(0xFFF0FDF4),
      description: 'Find emergency medical services and hospitals',
      searchQuery: 'hospitals',
    ),
    AuthorityType(
      title: 'Women Help Centers',
      icon: Icons.support_agent,
      color: const Color(0xFFEC4899),
      lightColor: const Color(0xFFFDF2F8),
      description: 'Women safety and support centers',
      searchQuery: 'women help centers',
    ),
    AuthorityType(
      title: 'Disaster Management',
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFF97316),
      lightColor: const Color(0xFFFFF7ED),
      description: 'Disaster management centers',
      searchQuery: 'disaster management',
    ),
    AuthorityType(
      title: 'Traffic Police',
      icon: Icons.traffic,
      color: const Color(0xFF6366F1),
      lightColor: const Color(0xFFEEF2FF),
      description: 'Traffic control and assistance',
      searchQuery: 'traffic police',
    ),
    AuthorityType(
      title: 'Child Helpline',
      icon: Icons.child_care,
      color: const Color(0xFFA855F7),
      lightColor: const Color(0xFFFAF5FF),
      description: 'Support for child safety',
      searchQuery: 'child helpline',
    ),
    AuthorityType(
      title: 'Cyber Crime Units',
      icon: Icons.computer,
      color: const Color(0xFF64748B),
      lightColor: const Color(0xFFF8FAFC),
      description: 'Digital and cyber crimes units',
      searchQuery: 'cyber crime unit',
    ),
  ];

  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardAnimations = List.generate(
      _authorityTypes.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            0.6 + index * 0.05,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _animationController.forward();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _hasLocationPermission = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _hasLocationPermission = false;
        });
        return;
      }

      setState(() {
        _hasLocationPermission = true;
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _isLoadingLocation = false;
        _hasLocationPermission = false;
      });
    }
  }

  Future<void> _openMaps(String query) async {
    if (_isLoadingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting your location...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_hasLocationPermission || _currentPosition == null) {
      _showLocationPermissionDialog();
      return;
    }

    String url;
    if (Platform.isIOS) {
      // Apple Maps URL scheme
      url =
          'maps://?q=$query&sll=${_currentPosition!.latitude},${_currentPosition!.longitude}&near=${_currentPosition!.latitude},${_currentPosition!.longitude}';
    } else {
      // Google Maps URL for Android
      url =
          'https://www.google.com/maps/search/?api=1&query=$query&query_place_id=near:${_currentPosition!.latitude},${_currentPosition!.longitude}';
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Fallback to Google Maps web
      String webUrl =
          'https://www.google.com/maps/search/$query/@${_currentPosition!.latitude},${_currentPosition!.longitude},14z';
      if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open maps. Please install a maps application.',
            ),
          ),
        );
      }
    }
  }

  void _showLocationPermissionDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'To find nearby authorities, we need access to your location. Please enable location services in your settings.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
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
              'Nearby Authorities',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationStatus(),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Authority Type',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find specialized local authorities for your specific needs',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0, // Adjusted for more height
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return FadeTransition(
                  opacity: _cardAnimations[index],
                  child: _buildAuthorityCard(_authorityTypes[index]),
                );
              }, childCount: _authorityTypes.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Important Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    'Availability may vary by location',
                    'The authorities shown may not all be available in every area. Results are based on your current location.',
                    Icons.location_on_outlined,
                    const Color(0xFFF0F9FF),
                    const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Emergency? Call directly',
                    'For immediate emergencies, always call emergency services directly at your local emergency number.',
                    Icons.phone_in_talk_outlined,
                    const Color(0xFFFEF2F2),
                    const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    if (_isLoadingLocation) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Getting your current location...',
                style: TextStyle(color: Colors.grey[800], fontSize: 14),
              ),
            ),
          ],
        ),
      );
    } else if (!_hasLocationPermission) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off, color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location permission required',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enable location to find nearby authorities',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
              },
              child: const Text(
                'Enable',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF22C55E), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your location is enabled. Tap any card to find nearby authorities.',
                style: TextStyle(color: Colors.grey[800], fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAuthorityCard(AuthorityType authority) {
    return Card(
      elevation: 0,
      color: authority.lightColor,
      shadowColor: authority.color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openMaps(authority.searchQuery),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Added to prevent overflow
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: authority.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(authority.icon, color: authority.color, size: 28),
              ),

              // Flexible spacing
              const Spacer(flex: 1),

              // Title
              Text(
                authority.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Description
              const SizedBox(height: 4),
              Text(
                authority.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1, // Limited to 1 line to prevent overflow
                overflow: TextOverflow.ellipsis,
              ),

              // Action row - Find Nearby
              const Spacer(flex: 1),
              Row(
                mainAxisSize:
                    MainAxisSize.min, // Keep this row as small as possible
                children: [
                  Text(
                    'Find Nearby',
                    style: TextStyle(
                      color: authority.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: authority.color,
                    size: 12,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String description,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
  ) {
    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthorityType {
  final String title;
  final IconData icon;
  final Color color;
  final Color lightColor;
  final String description;
  final String searchQuery;

  AuthorityType({
    required this.title,
    required this.icon,
    required this.color,
    required this.lightColor,
    required this.description,
    required this.searchQuery,
  });
}