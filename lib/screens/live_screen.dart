import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as video_thumbnail;
import 'live_stream_model.dart';

class LiveStreamScreen extends StatefulWidget {
  final CameraDescription? camera;

  const LiveStreamScreen({super.key, this.camera});

  @override
  _LiveStreamScreenState createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isRecording = false;
  String? _videoPath;
  String _tag = 'Other';
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  
  final List<String> _tags = [
    'Animal',
    'Assault',
    'Breakin',
    'Earthquake',
    'Gun',
    'Harassment',
    'Hazard',
    'Helicopter',
    'Missing Person',
    'Protest',
    'Pursuit',
    'Rescue',
    'Robbery or Theft',
    'Transit',
    'Weapon',
    'Weather',
    'Wildfire',
    'Other',
  ];
  late String _thumbnailPath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    if (widget.camera == null) {
      print('Camera is null, cannot initialize.');
      return;
    }
    try {
      _controller = CameraController(widget.camera!, ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        print('Camera initialized successfully.');
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<String> _getFilePath(String prefix) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    print('Video file path: $path');
    return path;
  }

  Future<String> _getThumbnailPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';
    print('Thumbnail file path: $path');
    return path;
  }

  void _startTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    setState(() {
      _recordingDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Camera controller not initialized, cannot start recording.');
      return;
    }
    try {
      _videoPath = await _getFilePath('video');
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
      _startTimer();
      print('Recording started. Video path: $_videoPath');
    } catch (e) {
      print('Error starting recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      print('Camera controller not recording, cannot stop.');
      return;
    }

    try {
      print('Stopping video recording...');
      _stopTimer();
      final XFile videoFile = await _controller!.stopVideoRecording();
      _videoPath = videoFile.path;
      print('Video recorded successfully at: $_videoPath');

      // Validate video file
      final videoFileExists = await File(_videoPath!).exists();
      print('Video file exists: $videoFileExists');
      if (!videoFileExists) {
        throw Exception('Video file was not saved correctly at $_videoPath');
      }
      final file = File(_videoPath!);
      await file.length();
      print('Video file validated successfully. Size: ${await file.length()} bytes');

      // Generate thumbnail
      print('Generating thumbnail...');
      _thumbnailPath = await video_thumbnail.VideoThumbnail.thumbnailFile(
        video: _videoPath!,
        thumbnailPath: (await getApplicationDocumentsDirectory()).path,
        imageFormat: video_thumbnail.ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      ) ?? await _getThumbnailPath();
      print('Thumbnail generated at: $_thumbnailPath');
      final thumbnailFileExists = await File(_thumbnailPath).exists();
      print('Thumbnail file exists: $thumbnailFileExists');

      // Create LiveStream object (without comments and description)
      final liveStream = LiveStream(
        videoPath: _videoPath!,
        thumbnailPath: _thumbnailPath,
        timestamp: DateTime.now(),
        tag: _tag,
        description: '', // Since description is removed, set to empty
        comments: [],   // Since comments are removed, set to empty list
      );
      print('LiveStream object created: ${liveStream.toJson()}');

      // Save to SharedPreferences with error handling
      print('Saving to SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      List<LiveStream> streamList = [];
      
      // Attempt to load existing streams
      final streams = prefs.getString('live_streams') ?? '[]';
      try {
        streamList = LiveStream.decodeList(streams);
      } catch (e) {
        print('Failed to decode existing streams: $e');
        await prefs.setString('live_streams', '[]');
        print('Reset live_streams in SharedPreferences to []');
        streamList = [];
      }

      streamList.insert(0, liveStream);
      final saveResult = await prefs.setString('live_streams', LiveStream.encodeList(streamList));
      print('SharedPreferences save successful: $saveResult');

      // Verify saved data
      final updatedStreams = prefs.getString('live_streams') ?? '[]';
      print('Verified streams in SharedPreferences: $updatedStreams');

      if (mounted) {
        print('Navigating back with LiveStream object...');
        Navigator.pop(context, liveStream);
      }
    } catch (e, stackTrace) {
      print('Error stopping recording: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save livestream: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isRecording = false;
      });
      print('Recording stopped. isRecording: $_isRecording');
    }
  }

  @override
  void dispose() {
    print('Disposing LiveStreamScreen...');
    _pulseAnimationController.dispose();
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF007AFF),
              ),
              const SizedBox(height: 16),
              Text(
                'Preparing camera...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF007AFF),
          secondary: Color(0xFF007AFF),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Column(
            children: [
              Text(
                'Live Stream',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (_isRecording)
                Text(
                  _formatDuration(_recordingDuration),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          centerTitle: true,
          actions: [
            if (_isRecording)
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedBuilder(
                  animation: _pulseAnimationController,
                  builder: (context, child) {
                    return Container(
                      width: 36,
                      height: 36,
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
        body: Stack(
          children: [
            // Camera Preview
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
            
            // UI Overlay
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const Spacer(),
                      
                      // Recording Controls
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Category Dropdown
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _tag,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  dropdownColor: Colors.black87,
                                  items: _tags.map((tag) {
                                    return DropdownMenuItem(
                                      value: tag,
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _tag = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Recording Button
                            Center(
                              child: GestureDetector(
                                onTap: _isRecording ? _stopRecording : _startRecording,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _isRecording ? 56 : 72,
                                  height: _isRecording ? 56 : 72,
                                  decoration: BoxDecoration(
                                    color: _isRecording ? Colors.red : Color(0xFF007AFF),
                                    shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                                    borderRadius: _isRecording ? BorderRadius.circular(16) : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isRecording ? Colors.red : Color(0xFF007AFF)).withOpacity(0.3),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isRecording ? Icons.stop_rounded : Icons.videocam_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Button Label
                            Center(
                              child: Text(
                                _isRecording ? 'Stop Recording' : 'Start Recording',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Status Indicators
            if (_isRecording)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.red, size: 12),
                        const SizedBox(width: 8),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
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
}