import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'live_stream_model.dart';
import 'live_screen.dart';
import 'video_player_screen.dart';

class LiveTabContent extends StatefulWidget {
  final CameraDescription? camera;

  const LiveTabContent({super.key, this.camera});

  @override
  State<LiveTabContent> createState() => _LiveTabContentState();
}

class _LiveTabContentState extends State<LiveTabContent> {
  List<LiveStream> _savedLiveStreams = [];

  @override
  void initState() {
    super.initState();
    _loadSavedStreams();
  }

  Future<void> _loadSavedStreams() async {
    final prefs = await SharedPreferences.getInstance();
    final streams = prefs.getString('live_streams') ?? '[]';
    print('Loaded streams from SharedPreferences: $streams');
    setState(() {
      _savedLiveStreams = LiveStream.decodeList(streams);
      print('Parsed streams: ${_savedLiveStreams.length} streams loaded');
    });
  }

  Future<void> _deleteStream(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final stream = _savedLiveStreams[index];
    try {
      print('Deleting video file: ${stream.videoPath}');
      await File(stream.videoPath).delete();
      if (await File(stream.thumbnailPath).exists()) {
        print('Deleting thumbnail file: ${stream.thumbnailPath}');
        await File(stream.thumbnailPath).delete();
      }
    } catch (e) {
      print('Error deleting files: $e');
    }
    _savedLiveStreams.removeAt(index);
    print('Removed stream at index $index. New length: ${_savedLiveStreams.length}');
    await prefs.setString('live_streams', LiveStream.encodeList(_savedLiveStreams));
    setState(() {});
  }

  Future<void> _editDescription(int index, String newDescription) async {
    final prefs = await SharedPreferences.getInstance();
    _savedLiveStreams[index] = LiveStream(
      videoPath: _savedLiveStreams[index].videoPath,
      thumbnailPath: _savedLiveStreams[index].thumbnailPath,
      timestamp: _savedLiveStreams[index].timestamp,
      tag: _savedLiveStreams[index].tag,
      description: newDescription,
      comments: _savedLiveStreams[index].comments,
    );
    print('Updated description for stream at index $index: $newDescription');
    await prefs.setString('live_streams', LiveStream.encodeList(_savedLiveStreams));
    setState(() {});
  }

  Future<void> _navigateToLiveScreen() async {
    print('Navigating to LiveStreamScreen...');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamScreen(camera: widget.camera),
      ),
    );

    if (result != null && mounted) {
      print('Received LiveStream from LiveStreamScreen: ${result.toJson()}');
      setState(() {
        _savedLiveStreams.insert(0, result);
        print('Added new stream. Total streams: ${_savedLiveStreams.length}');
      });
      await _loadSavedStreams();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('live_streams', LiveStream.encodeList(_savedLiveStreams));
      print('Saved updated streams to SharedPreferences.');
    } else {
      print('No LiveStream returned or widget not mounted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF17212D),
        title: const Text('Live Stream', style: TextStyle(color: Colors.white)),
      ),
      body: _savedLiveStreams.isEmpty
          ? _buildEmptyState()
          : _buildLiveStreamsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToLiveScreen,
        backgroundColor: const Color(0xFF003C71),
        icon: const Icon(Icons.stream, color: Colors.white),
        label: const Text('Start Live', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.live_tv_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Live Streams Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start a live stream to report incidents as they happen. Your saved streams will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToLiveScreen,
            icon: const Icon(Icons.stream),
            label: const Text('Go Live Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003C71),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStreamsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedLiveStreams.length,
      itemBuilder: (context, index) {
        final stream = _savedLiveStreams[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: File(stream.thumbnailPath).existsSync()
                          ? Image.file(
                              File(stream.thumbnailPath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.live_tv,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                            )
                          : Icon(
                              Icons.live_tv,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              videoPath: stream.videoPath,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003C71),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stream.tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF007AFF)),
                          onPressed: () {
                            _showEditDialog(index, stream.description);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteStream(index);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Live Report: ${stream.tag} Incident',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stream.description.isNotEmpty
                          ? stream.description
                          : 'No description provided',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recorded on ${DateFormat('MMM d, yyyy').format(stream.timestamp)} at ${DateFormat('h:mm a').format(stream.timestamp)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(int index, String currentDescription) {
    final controller = TextEditingController(text: currentDescription);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Description'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter description'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _editDescription(index, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}