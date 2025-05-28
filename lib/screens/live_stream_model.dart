import 'dart:convert';

class LiveStream {
  final String videoPath;
  final String thumbnailPath;
  final DateTime timestamp;
  final String tag;
  final String description;
  final List<Comment> comments;

  LiveStream({
    required this.videoPath,
    required this.thumbnailPath,
    required this.timestamp,
    required this.tag,
    required this.description,
    required this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'timestamp': timestamp.toIso8601String(),
      'tag': tag,
      'description': description,
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    return LiveStream(
      videoPath: json['videoPath'] as String? ?? '',
      thumbnailPath: json['thumbnailPath'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      tag: json['tag'] as String? ?? 'Other',
      description: json['description'] as String? ?? '',
      comments: (json['comments'] as List<dynamic>?)?.map((commentJson) => Comment.fromJson(commentJson as Map<String, dynamic>)).toList() ?? [],
    );
  }

  static String encodeList(List<LiveStream> streams) {
    return jsonEncode(streams.map((stream) => stream.toJson()).toList());
  }

  static List<LiveStream> decodeList(String streams) {
    try {
      final List<dynamic> decoded = jsonDecode(streams) as List<dynamic>;
      return decoded.map((json) => LiveStream.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error decoding live streams: $e');
      return []; // Return an empty list if decoding fails
    }
  }
}

class Comment {
  final String username;
  final String message;
  final DateTime timestamp;

  Comment({
    required this.username,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      username: json['username'] as String? ?? 'Unknown',
      message: json['message'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}