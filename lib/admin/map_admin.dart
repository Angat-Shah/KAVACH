import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Model: Timeline Event
class TimelineEvent {
  String time;
  String description;

  TimelineEvent({required this.time, required this.description});
}

// Model: Incident
class Incident {
  String emoji;
  String type;
  String location;
  String time;
  LatLng position;
  List<TimelineEvent> timeline;

  Incident({
    required this.emoji,
    required this.type,
    required this.location,
    required this.time,
    required this.position,
    required this.timeline,
  });
}

class MapAdmin extends StatefulWidget {
  const MapAdmin({super.key});

  @override
  _MapAdminState createState() => _MapAdminState();
}

class _MapAdminState extends State<MapAdmin> {
  late GoogleMapController _controller;
  Set<Marker> _markers = {};
  List<Incident> allIncidents = [];
  List<Incident> visibleIncidents = [];

  LatLng? _selectedLocation;
  String? _selectedEmoji;
  String _selectedType = '';
  final List<TimelineEvent> _timeline = [];
  final TextEditingController _timelineDescController = TextEditingController();

  final Map<String, String> emojiTypes = {
    'Animal': '🐾',
    'Assault': '👊',
    'Break In': '🪟',
    'Earthquake': '🏔',
    'Gun': '🔫',
    'Harassment': '😡',
    'Hazard': '⚠',
    'Helicopter': '🚁',
    'Missing Person': '🔍',
    'Protest': '📢',
    'Pursuit': '🏃',
    'Rescue': '🛟',
    'Robbery/Theft': '🥷',
    'Transit': '🚌',
    'Weapon': '🔪',
    'Weather': '☁',
    'Wildfire': '🌳',
  };

  Incident? _editingIncident; // For tracking if we are editing existing one

  @override
  void initState() {
    super.initState();
    _initializeIncidents();
  }

  Future<void> _initializeIncidents() async {
    final String data = await rootBundle.loadString('assets/incidents_augmented.json');
    final List<dynamic> jsonResult = json.decode(data);

    allIncidents = jsonResult.map((item) => Incident(
      emoji: item['emoji'],
      type: item['type'],
      location: item['location'],
      time: item['time'],
      position: LatLng(item['lat'], item['lng']),
      timeline: (item['timeline'] as List).map((e) =>
        TimelineEvent(time: e['time'], description: e['description'])).toList(),
    )).toList();

    visibleIncidents = List.from(allIncidents);
    _loadMarkers();
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
    setState(() {
      _markers = tempMarkers;
    });
  }

  Future<BitmapDescriptor> _emojiToBitmapDescriptor(String emoji, bool isDark) async {
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
  }

  void _onLongPress(LatLng position) {
    _editingIncident = null;
    _selectedLocation = position;
    _selectedEmoji = null;
    _selectedType = '';
    _timeline.clear();
    _showAddIncidentForm();
  }

  void _showAddIncidentForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal indicator line at top
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Distance info (for new incidents, show placeholder)
                Text(
                  _editingIncident != null ? "0.6 mi · Dropped by admin" : "Location selected",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Incident title - large and bold
                Text(
                  _editingIncident != null ? _editingIncident!.type : (_selectedType.isEmpty ? "New Incident" : _selectedType),
                  style: const TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Stats info (for existing incidents only)
                if (_editingIncident != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0, bottom: 20),
                    child: Text(
                      "104 notified · 26 views",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),
                const Divider(),
                
                // Timeline header
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    "Timeline",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Timeline events with time indicator and vertical line
                ..._timeline.map((event) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time column
                    SizedBox(
                      width: 80,
                      child: Text(
                        event.time,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    
                    // Vertical line with dot
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (_timeline.last != event)
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                      ],
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Description
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 12),
                        child: Text(
                          event.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                )),
                
                const SizedBox(height: 16),
                
                // Add new timeline event inputs
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _timelineDescController,
                      decoration: InputDecoration(
                        hintText: 'Add new timeline event',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Add event button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          final now = TimeOfDay.now();
                          if (_timelineDescController.text.isNotEmpty) {
                            setModalState(() {
                              _timeline.add(TimelineEvent(
                                time: now.format(context),
                                description: _timelineDescController.text,
                              ));
                              _timelineDescController.clear();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Add Event', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Incident Type Selection
                const Text(
                  "Incident Type",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                GestureDetector(
                  onTap: () async {
                    final selected = await showModalBottomSheet<String>(
                      context: context,
                      builder: (context) => ListView(
                        children: emojiTypes.entries.map((entry) => ListTile(
                          title: Text('${entry.value} ${entry.key}', style: const TextStyle(fontSize: 18)),
                          onTap: () => Navigator.pop(context, entry.key),
                        )).toList(),
                      ),
                    );
                    
                    if (selected != null) {
                      setModalState(() {
                        _selectedEmoji = emojiTypes[selected];
                        _selectedType = selected;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedEmoji ?? '🔍',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedType.isEmpty ? 'Select Incident Type' : _selectedType,
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedType.isEmpty ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Save button
                ElevatedButton(
                  onPressed: () {
                    if (_selectedLocation == null || _selectedEmoji == null || _selectedType.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please complete all fields')));
                      return;
                    }

                    if (_editingIncident != null) {
                      _editingIncident!.emoji = _selectedEmoji!;
                      _editingIncident!.type = _selectedType;
                      _editingIncident!.timeline = List.from(_timeline);
                    } else {
                      final newIncident = Incident(
                        emoji: _selectedEmoji!,
                        type: _selectedType,
                        location: 'Unknown Location',
                        time: TimeOfDay.now().format(context),
                        position: _selectedLocation!,
                        timeline: List.from(_timeline),
                      );
                      allIncidents.add(newIncident);
                    }

                    visibleIncidents = List.from(allIncidents);
                    _loadMarkers();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _editingIncident != null ? 'Update Incident' : 'Save Incident',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIncidentDetails(Incident incident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal indicator line at top
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Distance info
              Text(
                "0.6 mi · Dropped by user",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              
              // Incident title with emoji
              Row(
                children: [
                  Text(
                    incident.type,
                    style: const TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Warning icon in dark circle - use emoji as proper icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(25),
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
              
              // Stats info
              Padding(
                padding: const EdgeInsets.only(top: 6.0, bottom: 20),
                child: Text(
                  "104 notified · 26 views",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              const Divider(),
              
              // Timeline header
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "Timeline",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Timeline events with time indicator and vertical line
              ...incident.timeline.map((e) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time column
                  SizedBox(
                    width: 80,
                    child: Text(
                      e.time,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  // Vertical line with dot
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (incident.timeline.last != e)
                        Container(
                          width: 2,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                    ],
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Description
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0, bottom: 12),
                      child: Text(
                        e.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              )),
              
              const SizedBox(height: 24),
              
              // Section title
              const Text(
                "In this area",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Nearby incidents list - find actual nearby incidents from the list
              ...getNearbyIncidents(incident, 3).map((nearbyIncident) => 
                _buildNearbyIncident(
                  nearbyIncident.type, 
                  "${_calculateDistance(incident.position, nearbyIncident.position).toStringAsFixed(1)} km · ${nearbyIncident.location}",
                  nearbyIncident.emoji,
                  () => _showIncidentDetails(nearbyIncident)
                )
              ),
              
              const SizedBox(height: 24),
              
              // Edit button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editIncident(incident);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Edit Incident',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to calculate distance between two points
  double _calculateDistance(LatLng pos1, LatLng pos2) {
    // Approximate radius of earth in km
    const radius = 6371.0;
    double lat1 = pos1.latitude * pi / 180;
    double lon1 = pos1.longitude * pi / 180;
    double lat2 = pos2.latitude * pi / 180;
    double lon2 = pos2.longitude * pi / 180;
    
    double dlon = lon2 - lon1;
    double dlat = lat2 - lat1;
    
    double a = pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }
  
  // Find nearby incidents excluding the current one
  List<Incident> getNearbyIncidents(Incident current, int limit) {
    var sorted = allIncidents
        .where((inc) => inc != current)
        .toList()
        ..sort((a, b) => _calculateDistance(current.position, a.position)
            .compareTo(_calculateDistance(current.position, b.position)));
    
    return sorted.take(limit).toList();
  }

  // Helper method to build nearby incidents items
  Widget _buildNearbyIncident(String type, String distance, String emoji, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    distance,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editIncident(Incident incident) {
    setState(() {
      _editingIncident = incident;
      _selectedLocation = incident.position;
      _selectedEmoji = incident.emoji;
      _selectedType = incident.type;
      _timeline.clear();
      _timeline.addAll(incident.timeline);
    });
    _showAddIncidentForm();
  }

  void _filterByType(String? selectedType) {
    if (selectedType == null || selectedType == 'All') {
      visibleIncidents = List.from(allIncidents);
    } else {
      visibleIncidents = allIncidents.where((e) => e.type == selectedType).toList();
    }
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
      builder: (context) => ListView(
        children: ['All', ...emojiTypes.keys].map((type) {
          return ListTile(
            title: Text(type),
            onTap: () {
              Navigator.pop(context);
              _filterByType(type);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Map'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _searchIncident),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterMenu),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(20.5937, 78.9629),
          zoom: 4,
        ),
        onMapCreated: (controller) {
          _controller = controller;
          _loadMarkers();
        },
        markers: _markers,
        myLocationEnabled: true,
        zoomControlsEnabled: false,
        onLongPress: _onLongPress,
      ),
    );
  }
}

// ---------------------- Search Delegate --------------------
class _IncidentSearchDelegate extends SearchDelegate<Incident?> {
  final List<Incident> incidents;
  final Function(Incident) onSelected;

  _IncidentSearchDelegate({required this.incidents, required this.onSelected});

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) {
    final results = incidents.where((e) =>
      e.type.toLowerCase().contains(query.toLowerCase()) ||
      e.location.toLowerCase().contains(query.toLowerCase()) ||
      e.emoji.contains(query)
    );
    return ListView(
      children: results.map((e) {
        return ListTile(
          leading: Text(e.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(e.type),
          subtitle: Text('${e.location} • ${e.time}'),
          onTap: () {
            close(context, e);
            onSelected(e);
          },
        );
      }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}