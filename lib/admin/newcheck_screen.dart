import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- Models ---
enum NewsStatus { pending, genuine, fake }

class News {
  final String id;
  final String title;
  final String description;
  final String source;
  final DateTime date;
  final String imageUrl;
  final NewsStatus status;
  final bool isVideo;
  final String? videoUrl;

  const News({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.date,
    required this.imageUrl,
    required this.status,
    required this.isVideo,
    this.videoUrl,
  });

  News copyWith({
    String? id,
    String? title,
    String? description,
    String? source,
    DateTime? date,
    String? imageUrl,
    NewsStatus? status,
    bool? isVideo,
    String? videoUrl,
  }) {
    return News(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      source: source ?? this.source,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      isVideo: isVideo ?? this.isVideo,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}

// --- Widgets ---
class NewsCard extends StatelessWidget {
  final News news;
  final VoidCallback onTap;

  const NewsCard({super.key, required this.news, required this.onTap});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    String hours = date.hour.toString().padLeft(2, '0');
    String minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Color _getStatusColor(NewsStatus status) {
    switch (status) {
      case NewsStatus.pending:
        return CupertinoColors.systemOrange;
      case NewsStatus.genuine:
        return CupertinoColors.systemGreen;
      case NewsStatus.fake:
        return CupertinoColors.systemRed;
    }
  }

  String _getStatusText(NewsStatus status) {
    switch (status) {
      case NewsStatus.pending:
        return 'Pending';
      case NewsStatus.genuine:
        return 'Genuine';
      case NewsStatus.fake:
        return 'Fake';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? CupertinoColors.systemGrey6.darkColor
                  : CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    news.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color:
                              isDarkMode
                                  ? CupertinoColors.systemGrey4.darkColor
                                  : CupertinoColors.systemGrey4,
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.photo,
                              size: 40,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                  ),
                  if (news.isVideo)
                    Container(
                      color: CupertinoColors.black.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: CupertinoColors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.play_fill,
                            color: CupertinoColors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(news.status).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _getStatusText(news.status),
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color:
                          isDarkMode
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color:
                          isDarkMode
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey2,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.news,
                        size: 16,
                        color:
                            isDarkMode
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey2,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          news.source,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color:
                                isDarkMode
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.systemGrey2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.time,
                        size: 16,
                        color:
                            isDarkMode
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey2,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDate(news.date)} ${_formatTime(news.date)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color:
                              isDarkMode
                                  ? CupertinoColors.systemGrey
                                  : CupertinoColors.systemGrey2,
                        ),
                      ),
                    ],
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

// --- Main Screen ---
class NewsCheckScreen extends StatefulWidget {
  const NewsCheckScreen({super.key});

  @override
  State<NewsCheckScreen> createState() => _NewsCheckScreenState();
}

class _NewsCheckScreenState extends State<NewsCheckScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<News> _pendingNews = [];
  List<News> _genuineNews = [];
  List<News> _fakeNews = [];

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    String hours = date.hour.toString().padLeft(2, '0');
    String minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Color _getStatusColor(NewsStatus status) {
    switch (status) {
      case NewsStatus.pending:
        return CupertinoColors.systemOrange;
      case NewsStatus.genuine:
        return CupertinoColors.systemGreen;
      case NewsStatus.fake:
        return CupertinoColors.systemRed;
    }
  }

  String _getStatusText(NewsStatus status) {
    switch (status) {
      case NewsStatus.pending:
        return 'Pending';
      case NewsStatus.genuine:
        return 'Genuine';
      case NewsStatus.fake:
        return 'Fake';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _pendingNews = [
        News(
          id: '1',
          title: 'New Tax Policy Announced',
          description: 'Government announces changes to tax structure',
          source: 'Daily News',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          imageUrl: 'https://picsum.photos/seed/news1/800/400',
          status: NewsStatus.pending,
          isVideo: false,
        ),
        News(
          id: '2',
          title: 'Flood Alert in Southern Districts',
          description: 'Heavy rainfall expected over the weekend',
          source: 'Weather Channel',
          date: DateTime.now().subtract(const Duration(hours: 6)),
          imageUrl: 'https://picsum.photos/seed/news2/800/400',
          status: NewsStatus.pending,
          isVideo: true,
          videoUrl: 'https://example.com/video1.mp4',
        ),
      ];
      _genuineNews = [
        News(
          id: '3',
          title: 'Hospital Opens New Wing',
          description: 'City hospital expands capacity with new facility',
          source: 'Health Times',
          date: DateTime.now().subtract(const Duration(days: 1)),
          imageUrl: 'https://picsum.photos/seed/news3/800/400',
          status: NewsStatus.genuine,
          isVideo: false,
        ),
      ];
      _fakeNews = [
        News(
          id: '4',
          title: 'Alien Sighting Reported',
          description: 'Alleged UFO sighting turns out to be weather balloon',
          source: 'Unknown Blog',
          date: DateTime.now().subtract(const Duration(days: 2)),
          imageUrl: 'https://picsum.photos/seed/news4/800/400',
          status: NewsStatus.fake,
          isVideo: false,
        ),
      ];
      _isLoading = false;
    });
  }

  void _showNewsDetail(News news) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildNewsDetailSheet(news),
    );
  }

  Widget _buildNewsDetailSheet(News news) {
  final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
  final size = MediaQuery.of(context).size;

  return Container(
    height: size.height * 0.85,
    decoration: BoxDecoration(
      color: isDarkMode ? CupertinoColors.systemBackground.darkColor : CupertinoColors.systemBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Removed the top margin container to eliminate the gap
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        news.isVideo
                            ? Container(
                                color: CupertinoColors.black,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      news.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                    ),
                                    Center(
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.play_fill,
                                          color: CupertinoColors.white,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Image.network(
                                news.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: isDarkMode ? CupertinoColors.systemGrey4.darkColor : CupertinoColors.systemGrey4,
                                  child: const Icon(
                                    CupertinoIcons.photo,
                                    size: 64,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(news.status).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _getStatusText(news.status),
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDarkMode ? CupertinoColors.black.withOpacity(0.5) : CupertinoColors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                CupertinoIcons.xmark,
                                color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      news.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                        letterSpacing: -0.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.news,
                          size: 16,
                          color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            news.source,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                              decoration: TextDecoration.none,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          CupertinoIcons.time,
                          size: 16,
                          color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatDate(news.date)} ${_formatTime(news.date)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      news.description,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                        height: 1.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Additional details about this news article would provide further context and insights into the reported event. This section could include in-depth analysis, background, or related information to give a comprehensive understanding.',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                        height: 1.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ],
          ),
        ),
        if (news.status == NewsStatus.pending)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onPressed: () {
                        _updateNewsStatus(news, NewsStatus.fake);
                        Navigator.pop(context);
                      },
                      color: CupertinoColors.systemRed,
                      child: const Text(
                        'Mark as Fake',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onPressed: () {
                        _updateNewsStatus(news, NewsStatus.genuine);
                        Navigator.pop(context);
                      },
                      color: CupertinoColors.systemGreen,
                      child: const Text(
                        'Mark as Genuine',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: () => Navigator.of(context).pop(),
                color: CupertinoColors.activeBlue,
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

  void _updateNewsStatus(News news, NewsStatus newStatus) {
    setState(() {
      _pendingNews.removeWhere((item) => item.id == news.id);
      _genuineNews.removeWhere((item) => item.id == news.id);
      _fakeNews.removeWhere((item) => item.id == news.id);
      final updatedNews = news.copyWith(status: newStatus);
      if (newStatus == NewsStatus.genuine) {
        _genuineNews.add(updatedNews);
      } else {
        _fakeNews.add(updatedNews);
      }

      final overlay = OverlayEntry(
        builder:
            (context) => _buildToastNotification(
              message:
                  'News marked as ${newStatus == NewsStatus.genuine ? 'genuine' : 'fake'}',
              isSuccess: newStatus == NewsStatus.genuine,
            ),
      );
      Overlay.of(context).insert(overlay);
      Future.delayed(const Duration(seconds: 2), () => overlay.remove());
    });
  }

  Widget _buildToastNotification({
    required String message,
    required bool isSuccess,
  }) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSuccess
                            ? CupertinoColors.systemGreen.withOpacity(0.95)
                            : CupertinoColors.systemRed.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSuccess
                            ? CupertinoIcons.check_mark_circled
                            : CupertinoIcons.xmark_circle,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor:
          isDarkMode
              ? CupertinoColors.systemBackground.darkColor
              : CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Kavach',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor:
            isDarkMode
                ? CupertinoColors.systemBackground.darkColor
                : CupertinoColors.systemBackground,
        border: null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? CupertinoColors.systemBackground.darkColor
                        : CupertinoColors.systemBackground,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(
                      isDarkMode ? 0.2 : 0.1,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedIndex,
                backgroundColor:
                    isDarkMode
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemGrey6,
                thumbColor:
                    isDarkMode
                        ? CupertinoColors.systemBackground
                        : CupertinoColors.white,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Pending',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Genuine',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Fake',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                },
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedIndex = value;
                    });
                  }
                },
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CupertinoActivityIndicator(radius: 16),
                      )
                      : _buildNewsList(_getNewsForCurrentTab()),
            ),
          ],
        ),
      ),
    );
  }

  List<News> _getNewsForCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _pendingNews;
      case 1:
        return _genuineNews;
      case 2:
        return _fakeNews;
      default:
        return [];
    }
  }

  Widget _buildNewsList(List<News> newsList) {
    if (newsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.news,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No news articles found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: newsList.length,
      itemBuilder: (context, index) {
        final news = newsList[index];
        return NewsCard(news: news, onTap: () => _showNewsDetail(news));
      },
    );
  }
}
