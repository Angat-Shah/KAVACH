import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class TimelineEvent {
  final String time;
  final String description;

  TimelineEvent({required this.time, required this.description});
}

class Incident {
  final String emoji;
  final String type;
  final String location;
  final String time;
  final LatLng position;
  final List<TimelineEvent> timeline;

  Incident({
    required this.emoji,
    required this.type,
    required this.location,
    required this.time,
    required this.position,
    required this.timeline,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _controller;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  List<Incident> allIncidents = [];
  List<Incident> visibleIncidents = [];
  LatLng? _selectedAreaCenter;
  String? _selectedAreaName;
  Position? _currentPosition;
  String? _currentAreaName;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isLoading = false;

  final Map<String, String> emojiTypes = {
    'Animal': '🐺',
    'Assault': '👮‍♂️',
    'Break In': '🚨',
    'Earthquake': '🌍',
    'Gun': '🔫',
    'Harassment': '⚠️',
    'Hazard': '💥',
    'Helicopter': '🚁',
    'Missing Person': '🔎',
    'Protest': '📣',
    'Pursuit': '🏎️',
    'Rescue': '🚒',
    'Robbery/Theft': '💰',
    'Transit': '🚌',
    'Weapon': '🔪',
    'Weather': '⛈️',
    'Wildfire': '🔥',
  };

  @override
  void initState() {
    super.initState();
    _initializeIncidents();
    _initializeNotifications();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Initialize notifications
  void _initializeNotifications() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    _notificationsPlugin.initialize(initSettings);
    _requestNotificationPermission();
  }

  // Request notification permission
  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // Request location permission and start updates
  Future<void> _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationPermissionDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationPermissionDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationPermissionDialog();
      return;
    }

    // Start listening to location updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _updateCurrentArea(position);
    });
  }

  // Show dialog to enable location
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Required'),
        content: const Text('Please enable location services to receive safety updates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  // Update current area based on position
  Future<void> _updateCurrentArea(Position position) async {
    final newArea = await _getAreaName(LatLng(position.latitude, position.longitude));
    if (_currentAreaName != newArea && newArea != null) {
      setState(() {
        _currentAreaName = newArea;
      });
      final incidents = _getIncidentsInArea(LatLng(position.latitude, position.longitude));
      final safetyStatus = _getSafetyStatus(incidents);
      final tips = _getSafetyTips(incidents);
      // Show transition notification
      _showNotification(
        'Entered $newArea',
        'Safety Status: $safetyStatus\nTips: ${tips.join(", ")}',
        id: 0,
      );
      // Update persistent notification for current location status
      _showPersistentNotification(newArea, safetyStatus);
    }
  }

  // Show regular notification
  Future<void> _showNotification(String title, String body, {int id = 0}) async {
    const androidDetails = AndroidNotificationDetails(
      'safety_channel',
      'Safety Updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  // Show persistent notification for current location status
  Future<void> _showPersistentNotification(String areaName, String safetyStatus) async {
    const androidDetails = AndroidNotificationDetails(
      'safety_status_channel',
      'Current Location Safety Status',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Makes notification persistent
      showWhen: false,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notificationsPlugin.show(
      1, // Unique ID for persistent notification
      'Current Location: $areaName',
      'Safety Status: $safetyStatus',
      notificationDetails,
    );
  }

  Future<void> _initializeIncidents() async {
    setState(() => _isLoading = true);
    try {
      final String data = await rootBundle.loadString('assets/incidents_augmented.json');
      final List<dynamic> jsonResult = json.decode(data);

      allIncidents = jsonResult
          .map((item) => Incident(
                emoji: item['emoji'],
                type: item['type'],
                location: item['location'],
                time: item['time'],
                position: LatLng(item['lat'], item['lng']),
                timeline: (item['timeline'] as List)
                    .map((e) => TimelineEvent(time: e['time'], description: e['description']))
                    .toList(),
              ))
          .toList();

      visibleIncidents = List.from(allIncidents);
      _loadMarkers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load incidents: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMarkers() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = isDark ? await rootBundle.loadString('assets/map_style_dark.json') : null;
    _controller.setMapStyle(style);

    Set<Marker> tempMarkers = {};
    for (var incident in visibleIncidents) {
      final icon = await _emojiToBitmapDescriptor(incident.emoji, isDark);
      tempMarkers.add(
        Marker(
          markerId: MarkerId(incident.emoji + incident.position.toString()),
          position: incident.position,
          icon: icon,
          onTap: () => _showIncidentDetails(incident),
        ),
      );
    }
    setState(() => _markers = tempMarkers);
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371; // in km
    final dLat = _degToRad(p2.latitude - p1.latitude);
    final dLng = _degToRad(p2.longitude - p1.longitude);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(p1.latitude)) * cos(_degToRad(p2.latitude)) * (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  Future<BitmapDescriptor> _emojiToBitmapDescriptor(String emoji, bool isDark) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..color = isDark ? Colors.black : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(64, 64), 60, paint);

      final textPainter = TextPainter(
        text: TextSpan(text: emoji, style: const TextStyle(fontSize: 48)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(32, 32));
      final picture = recorder.endRecording();
      final image = await picture.toImage(128, 128);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    } catch (e) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  void _showIncidentDetails(Incident incident) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final dividerColor = isDark ? Colors.grey[700] : Colors.grey[300];

    final distanceMi = _currentPosition != null
        ? (_calculateDistance(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              incident.position,
            ) *
            0.621371)
            .toStringAsFixed(1)
        : "0.6";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: subtitleColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        "$distanceMi mi · ${incident.location}",
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          incident.type,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            incident.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    "104 notified · 26 views",
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                ),
                Divider(height: 24, thickness: 1, color: dividerColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "Timeline",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                ...incident.timeline.map((event) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Text(
                                event.time,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subtitleColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: subtitleColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 40,
                                  color: dividerColor,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              event.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                Divider(height: 24, thickness: 1, color: dividerColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "In this area",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                ...allIncidents.where((e) {
                  if (e == incident) return false;
                  final distance = _calculateDistance(incident.position, e.position);
                  return distance <= 50;
                }).map((nearby) {
                  final distance = _calculateDistance(incident.position, nearby.position).toStringAsFixed(1);
                  return ListTile(
                    title: Text(
                      nearby.type,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      "$distance km · ${nearby.location}",
                      style: TextStyle(
                        color: subtitleColor,
                      ),
                    ),
                    trailing: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(nearby.emoji)),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _controller.animateCamera(CameraUpdate.newLatLng(nearby.position));
                      _showIncidentDetails(nearby);
                    },
                  );
                }),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  void _fitToAllMarkers() {
    if (_markers.isEmpty) return;
    final bounds = _createBoundsFromMarkers(_markers);
    _controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  LatLngBounds _createBoundsFromMarkers(Set<Marker> markers) {
    final latitudes = markers.map((m) => m.position.latitude).toList();
    final longitudes = markers.map((m) => m.position.longitude).toList();
    return LatLngBounds(
      southwest: LatLng(latitudes.reduce((a, b) => a < b ? a : b), longitudes.reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(latitudes.reduce((a, b) => a > b ? a : b), longitudes.reduce((a, b) => a > b ? a : b)),
    );
  }

  void _addNewIncident() async {
    final selectedType = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: emojiTypes.entries.map((entry) {
          return ListTile(
            leading: Text(entry.value, style: const TextStyle(fontSize: 24)),
            title: Text(entry.key),
            onTap: () => Navigator.pop(context, entry.key),
          );
        }).toList(),
      ),
    );

    if (selectedType != null) {
      final emoji = emojiTypes[selectedType]!;
      final latLng = await _controller.getLatLng(const ScreenCoordinate(x: 200, y: 400));
      final newIncident = Incident(
        emoji: emoji,
        type: selectedType,
        location: 'Dropped by user',
        time: TimeOfDay.now().format(context),
        position: latLng,
        timeline: [
          TimelineEvent(
            time: TimeOfDay.now().format(context),
            description: 'User reported a $selectedType incident.',
          ),
        ],
      );
      setState(() {
        allIncidents.add(newIncident);
        visibleIncidents = List.from(allIncidents);
      });
      _loadMarkers();
    }
  }

  void _removeDroppedIncidents() {
    setState(() {
      allIncidents.removeWhere((incident) => incident.location == 'Dropped by user');
      visibleIncidents = List.from(allIncidents);
    });
    _loadMarkers();
  }

  void _filterByType(String? selectedType) {
    setState(() {
      if (selectedType == null || selectedType == 'All') {
        visibleIncidents = List.from(allIncidents);
      } else {
        visibleIncidents = allIncidents.where((e) => e.type == selectedType).toList();
      }
    });
    _loadMarkers();
  }

  void _searchIncident() {
    showSearch(
      context: context,
      delegate: _IncidentSearchDelegate(
        incidents: allIncidents,
        onSelected: (incident) {
          _controller.animateCamera(CameraUpdate.newLatLng(incident.position));
          _showIncidentDetails(incident);
        },
      ),
    );
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.all_inclusive, size: 24),
                  title: const Text('All'),
                  onTap: () {
                    Navigator.pop(context);
                    _filterByType('All');
                  },
                ),
                ...emojiTypes.entries.map((entry) {
                  return ListTile(
                    leading: Text(entry.value, style: const TextStyle(fontSize: 24)),
                    title: Text(entry.key),
                    onTap: () {
                      Navigator.pop(context);
                      _filterByType(entry.key);
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Select and highlight an area
  void _selectArea(LatLng position) async {
    final placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      final tappedPoint = position;
      bool isInsidePolygon = false;
      for (var polygon in _polygons) {
        if (_isPointInPolygon(tappedPoint, polygon.points)) {
          isInsidePolygon = true;
          break;
        }
      }
      if (isInsidePolygon) {
        setState(() {
          _polygons.clear();
          _selectedAreaCenter = null;
          _selectedAreaName = null;
        });
      } else {
        final areaName = placemarks.first.locality ?? 'Selected Area';
        final incidents = _getIncidentsInArea(position);
        final safetyStatus = _getSafetyStatus(incidents);
        final color = _getSafetyColor(safetyStatus);

        // Create an irregular polygon with increased opacity and zIndex
        final points = _generateIrregularPolygon(position, 0.015); // Increased radius
        setState(() {
          _polygons = {
            Polygon(
              polygonId: PolygonId(areaName),
              points: points,
              fillColor: color.withOpacity(safetyStatus == 'Neutral' ? 0.5 : 0.3),
              strokeColor: color,
              strokeWidth: 2,
              zIndex: 1,
            ),
          };
          _selectedAreaCenter = position;
          _selectedAreaName = areaName;
        });
        _controller.animateCamera(CameraUpdate.newLatLngZoom(position, 12));
        _showSafetyReport();
      }
    }
  }

  // Generate irregular polygon points
  List<LatLng> _generateIrregularPolygon(LatLng center, double radius) {
    const segments = 8;
    final points = <LatLng>[];
    final random = Random();
    for (var i = 0; i < segments; i++) {
      final angle = 2 * pi * i / segments;
      final variation = radius * (0.8 + random.nextDouble() * 0.4);
      final lat = center.latitude + variation * cos(angle);
      final lng = center.longitude + variation * sin(angle);
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  // Get incidents in an area
  List<Incident> _getIncidentsInArea(LatLng center) {
    return allIncidents.where((incident) {
      final distance = _calculateDistance(center, incident.position);
      return distance <= 10; // 10 km radius
    }).toList();
  }

  // Get safety status
  String _getSafetyStatus(List<Incident> incidents) {
    if (incidents.isEmpty) return 'Safe';
    final incidentCount = incidents.length;
    final severeTypes = ['Gun', 'Assault', 'Robbery/Theft', 'Weapon'];
    final naturalTypes = ['Earthquake', 'Wildfire', 'Weather'];
    final severeCount = incidents.where((i) => severeTypes.contains(i.type)).length;
    final naturalCount = incidents.where((i) => naturalTypes.contains(i.type)).length;

    if (incidentCount > 10 || severeCount > 3) return 'Unsafe';
    if (naturalCount > 2 && severeCount == 0 && incidentCount <= 5) return 'Neutral';
    return 'Safe';
  }

  // Get safety color
  Color _getSafetyColor(String status) {
    switch (status) {
      case 'Safe':
        return Colors.green;
      case 'Neutral':
        return Colors.yellow.shade700;
      case 'Unsafe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get top incidents
  List<MapEntry<String, int>> _getTopIncidents(List<Incident> incidents) {
    final incidentCounts = <String, int>{};
    for (var incident in incidents) {
      incidentCounts[incident.type] = (incidentCounts[incident.type] ?? 0) + 1;
    }
    final sorted = incidentCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  }

  // Get safety tips
  List<String> _getSafetyTips(List<Incident> incidents) {
    final topIncidents = _getTopIncidents(incidents);
    if (topIncidents.isEmpty) return ['No specific precautions needed'];
    final topType = topIncidents.first.key;
    return SafetyReport.precautionTips[topType] ?? ['Stay vigilant', 'Report suspicious activity'];
  }

  // Get area name using reverse geocoding
  Future<String?> _getAreaName(LatLng position) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return placemark.locality ?? placemark.subLocality ?? placemark.name ?? 'Unknown Area';
      }
      return 'Unknown Area';
    } catch (e) {
      return 'Unknown Area';
    }
  }

  // Show safety report
  void _showSafetyReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final backgroundColor = isDark ? Colors.black : Colors.white;
          final textColor = isDark ? Colors.white : Colors.black;
          final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

          String mainCity = _currentAreaName ?? 'Unknown City';
          List<Incident> selectedIncidents = _selectedAreaCenter != null
              ? _getIncidentsInArea(_selectedAreaCenter!)
              : [];
          List<Incident> currentIncidents = _currentPosition != null
              ? _getIncidentsInArea(LatLng(_currentPosition!.latitude, _currentPosition!.longitude))
              : [];
          String selectedSafetyStatus = _getSafetyStatus(selectedIncidents);
          String currentSafetyStatus = _getSafetyStatus(currentIncidents);

          return SingleChildScrollView(
            controller: scrollController,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: subtitleColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          mainCity,
                          style: TextStyle(
                            fontSize: 14,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[600]!),
                          ),
                          child: SafetyReport(
                            areaName: _selectedAreaName ?? 'Selected Area',
                            incidents: selectedIncidents,
                            isCurrentLocation: false,
                            center: _selectedAreaCenter ?? const LatLng(20.5937, 78.9629),
                            emojiTypes: emojiTypes,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[600]!),
                          ),
                          child: SafetyReport(
                            areaName: _currentAreaName ?? 'Current Location',
                            incidents: currentIncidents,
                            isCurrentLocation: true,
                            center: _currentPosition != null
                                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                                : const LatLng(20.5937, 78.9629),
                            emojiTypes: emojiTypes,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629),
              zoom: 2.5,
            ),
            onMapCreated: (controller) {
              _controller = controller;
              _loadMarkers();
            },
            markers: _markers,
            polygons: _polygons,
            myLocationEnabled: _currentPosition != null,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onTap: (position) async {
              final placemarks = await geocoding.placemarkFromCoordinates(
                position.latitude,
                position.longitude,
              );
              if (placemarks.isNotEmpty) {
                final tappedPoint = position;
                bool isInsidePolygon = false;
                for (var polygon in _polygons) {
                  if (_isPointInPolygon(tappedPoint, polygon.points)) {
                    isInsidePolygon = true;
                    break;
                  }
                }
                if (isInsidePolygon) {
                  setState(() {
                    _polygons.clear();
                    _selectedAreaCenter = null;
                    _selectedAreaName = null;
                  });
                } else {
                  setState(() {
                    _selectedAreaName = placemarks.first.locality ?? 'Selected Area';
                    _selectedAreaCenter = position;
                  });
                  _selectArea(position);
                }
              }
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 70,
            left: 16,
            child: FloatingActionButton(
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              onPressed: _fitToAllMarkers,
              shape: const CircleBorder(),
              child: Icon(Icons.zoom_out_map, color: isDark ? Colors.white : Colors.black),
            ),
          ),
          Positioned(
            top: 70,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  onPressed: _searchIncident,
                  shape: const CircleBorder(),
                  child: Icon(Icons.search, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  onPressed: _addNewIncident,
                  shape: const CircleBorder(),
                  child: Icon(Icons.add, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  onPressed: _showFilterMenu,
                  shape: const CircleBorder(),
                  child: Icon(Icons.filter_list, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  onPressed: _showSafetyReport,
                  shape: const CircleBorder(),
                  child: Icon(Icons.report, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  onPressed: _removeDroppedIncidents,
                  shape: const CircleBorder(),
                  child: Icon(Icons.delete, color: isDark ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Check if a point is inside a polygon
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersections = 0;
    for (int i = 0; i < polygon.length; i++) {
      final vertex1 = polygon[i];
      final vertex2 = polygon[(i + 1) % polygon.length];
      if (_rayCastIntersect(point, vertex1, vertex2)) {
        intersections++;
      }
    }
    return (intersections % 2 == 1);
  }

  bool _rayCastIntersect(LatLng point, LatLng vertex1, LatLng vertex2) {
    if (vertex1.latitude > vertex2.latitude) {
      final temp = vertex1;
      vertex1 = vertex2;
      vertex2 = temp;
    }
    if (point.latitude < vertex1.latitude || point.latitude > vertex2.latitude) return false;
    if (point.latitude == vertex1.latitude && point.longitude >= vertex1.longitude) return false;
    if (point.latitude == vertex2.latitude && point.longitude <= vertex2.longitude) return false;

    final m = (vertex2.longitude - vertex1.longitude) / (vertex2.latitude - vertex1.latitude);
    final xIntersect = vertex1.longitude + m * (point.latitude - vertex1.latitude);
    return point.longitude <= xIntersect;
  }
}

// Safety Report Widget
class SafetyReport extends StatelessWidget {
  final String areaName;
  final List<Incident> incidents;
  final bool isCurrentLocation;
  final LatLng center;
  final Map<String, String> emojiTypes;

  const SafetyReport({
    super.key,
    required this.areaName,
    required this.incidents,
    required this.isCurrentLocation,
    required this.center,
    required this.emojiTypes,
  });

  static const Map<String, List<String>> precautionTips = {
    'Robbery/Theft': [
      'Keep valuables out of sight',
      'Travel in groups when possible',
      'Be aware of your surroundings',
    ],
    'Assault': [
      'Avoid isolated areas',
      'Stay in well-lit areas at night',
      'Trust your instincts',
    ],
    'Gun': [
      'Report suspicious activity immediately',
      'Avoid confrontations',
      'Know emergency exits',
    ],
    'Harassment': [
      'Document incidents',
      'Report to authorities',
      'Use safe routes',
    ],
    'Earthquake': [
      'Know safe spots (under sturdy furniture)',
      'Have an emergency kit',
      'Stay away from windows',
    ],
    'Wildfire': [
      'Create a defensible space',
      'Have an evacuation plan',
      'Monitor air quality',
    ],
    'Weather': [
      'Check weather forecasts',
      'Avoid flooded areas',
      'Prepare emergency supplies',
    ],
  };

  String _calculateSafetyStatus(List<Incident> incidents) {
    if (incidents.isEmpty) return 'Safe';
    final incidentCount = incidents.length;
    final severeTypes = ['Gun', 'Assault', 'Robbery/Theft', 'Weapon'];
    final naturalTypes = ['Earthquake', 'Wildfire', 'Weather'];
    final severeCount = incidents.where((i) => severeTypes.contains(i.type)).length;
    final naturalCount = incidents.where((i) => naturalTypes.contains(i.type)).length;

    if (incidentCount > 10 || severeCount > 3) return 'Unsafe';
    if (naturalCount > 2 && severeCount == 0 && incidentCount <= 5) return 'Neutral';
    return 'Safe';
  }

  List<MapEntry<String, int>> _getTopIncidents(List<Incident> incidents) {
    final incidentCounts = <String, int>{};
    for (var incident in incidents) {
      incidentCounts[incident.type] = (incidentCounts[incident.type] ?? 0) + 1;
    }
    final sorted = incidentCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  }

  List<String> _getPrecautionTips(List<MapEntry<String, int>> topIncidents) {
    if (topIncidents.isEmpty) return ['No specific precautions needed'];
    final topType = topIncidents.first.key;
    return precautionTips[topType] ?? ['Stay vigilant', 'Report suspicious activity'];
  }

  Color _getSafetyColor(String status) {
    switch (status) {
      case 'Safe':
        return Colors.green;
      case 'Neutral':
        return Colors.yellow.shade700;
      case 'Unsafe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final safetyStatus = _calculateSafetyStatus(incidents);
    final topIncidents = _getTopIncidents(incidents);
    final precautionTips = _getPrecautionTips(topIncidents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isCurrentLocation ? 'Current Location: $areaName' : 'Selected Area: $areaName',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getSafetyColor(safetyStatus),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                safetyStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (safetyStatus == 'Safe' && incidents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'You are totally safe! ✨',
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (topIncidents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Incidents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...topIncidents.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emojiTypes[entry.key] ?? '❓',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${entry.key}: ${entry.value} incidents',
                            style: TextStyle(fontSize: 16, color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precaution Tips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              ...precautionTips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '• $tip',
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Incidents',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              ...incidents.take(5).map(
                    (incident) => ListTile(
                      leading: Text(
                        incident.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        incident.type,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${incident.location} • ${incident.time}',
                        style: TextStyle(color: subtitleColor),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IncidentSearchDelegate extends SearchDelegate<Incident?> {
  final List<Incident> incidents;
  final Function(Incident) onSelected;

  _IncidentSearchDelegate({
    required this.incidents,
    required this.onSelected,
  });

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    final results = incidents.where(
      (e) =>
          e.type.toLowerCase().contains(query.toLowerCase()) ||
          e.location.toLowerCase().contains(query.toLowerCase()) ||
          e.emoji.contains(query) ||
          e.timeline.any((t) => t.description.toLowerCase().contains(query.toLowerCase())),
    ).toList();

    return ListView(
      children: results.map((e) {
        return ListTile(
          leading: Text(e.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(e.type),
          subtitle: Text('${e.location} · ${e.time}'),
          onTap: () {
            close(context, e);
            onSelected(e);
          },
        );
      }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = incidents.where(
      (e) =>
          e.type.toLowerCase().contains(query.toLowerCase()) ||
          e.location.toLowerCase().contains(query.toLowerCase()) ||
          e.emoji.contains(query) ||
          e.timeline.any((t) => t.description.toLowerCase().contains(query.toLowerCase())),
    ).toList();

    return ListView(
      children: suggestions.map((e) {
        return ListTile(
          leading: Text(e.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(e.type),
          subtitle: Text('${e.location} · ${e.time}'),
          onTap: () {
            close(context, e);
            onSelected(e);
          },
        );
      }).toList(),
    );
  }
}