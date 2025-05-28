import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';

// --- Models ---
enum ReportStatus { pending, accepted, rejected }

class Report {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final ReportStatus status;
  final String pdfUrl;

  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.status,
    required this.pdfUrl,
  });

  Report copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    ReportStatus? status,
    String? pdfUrl,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      status: status ?? this.status,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }
}

// --- Widgets ---
class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onPdfTap;
  final VoidCallback onCardTap;

  const ReportCard({
    super.key,
    required this.report,
    required this.onPdfTap,
    required this.onCardTap,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    String hours = date.hour.toString().padLeft(2, '0');
    String minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return CupertinoColors.systemOrange;
      case ReportStatus.accepted:
        return CupertinoColors.systemGreen;
      case ReportStatus.rejected:
        return CupertinoColors.systemRed;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.accepted:
        return 'Accepted';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report.status).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(report.status),
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(report.date),
                    style: TextStyle(
                      color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.location_solid,
                    size: 16,
                    color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      report.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onPdfTap,
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.doc_text,
                          size: 16,
                          color: CupertinoColors.activeBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View PDF',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.activeBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Main Screen ---
class ReportCheckScreen extends StatefulWidget {
  const ReportCheckScreen({super.key});

  @override
  State<ReportCheckScreen> createState() => _ReportCheckScreenState();
}

class _ReportCheckScreenState extends State<ReportCheckScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<Report> _pendingReports = [];
  List<Report> _acceptedReports = [];
  List<Report> _rejectedReports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _pendingReports = [
        Report(
          id: '1',
          title: 'Suspicious Activity',
          description: 'Someone suspicious lurking around residential area',
          location: 'Park Street, Sector 12',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          status: ReportStatus.pending,
          pdfUrl: '',
        ),
        Report(
          id: '2',
          title: 'Vehicle Theft',
          description: 'Car stolen from parking lot',
          location: 'Main Road, Sector 5',
          date: DateTime.now().subtract(const Duration(hours: 5)),
          status: ReportStatus.pending,
          pdfUrl: '',
        ),
      ];
      _acceptedReports = [
        Report(
          id: '3',
          title: 'Traffic Violation',
          description: 'Multiple vehicles running red light',
          location: 'Central Junction',
          date: DateTime.now().subtract(const Duration(days: 1)),
          status: ReportStatus.accepted,
          pdfUrl: '',
        ),
      ];
      _rejectedReports = [
        Report(
          id: '4',
          title: 'False Alarm',
          description: 'Reported noise disturbance was just construction',
          location: 'Housing Complex',
          date: DateTime.now().subtract(const Duration(days: 2)),
          status: ReportStatus.rejected,
          pdfUrl: '',
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _viewReportPdf(BuildContext context, String pdfUrl) async {
    try {
      debugPrint('Attempting to open PDF with URL: $pdfUrl');
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      File file = File(tempPath);
      debugPrint('Temporary file path: $tempPath');

      if (pdfUrl.isNotEmpty) {
        debugPrint('Downloading PDF from URL...');
        final response = await http.get(Uri.parse(pdfUrl));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          debugPrint('PDF downloaded and written to file');
        } else {
          throw Exception('Failed to download PDF: Status ${response.statusCode}');
        }
      } else {
        debugPrint('Generating sample PDF...');
        final pdf = pw.Document();
        pw.Font? font;
        try {
          final fontData = await DefaultAssetBundle.of(context).load('assets/fonts/Roboto-Regular.ttf');
          font = pw.Font.ttf(fontData);
          debugPrint('Roboto font loaded successfully');
        } catch (e) {
          debugPrint('Failed to load Roboto font: $e');
          font = pw.Font.helvetica(); // Fallback to default font
        }
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Center(
              child: pw.Text(
                'Sample PDF Report',
                style: pw.TextStyle(font: font, fontSize: 24),
              ),
            ),
          ),
        );
        final pdfBytes = await pdf.save();
        await file.writeAsBytes(pdfBytes);
        debugPrint('Sample PDF generated and written to file');
      }

      // Verify file exists and is not empty
      if (await file.exists()) {
        final fileSize = await file.length();
        debugPrint('File exists with size: $fileSize bytes');
        if (fileSize == 0) {
          throw Exception('PDF file is empty');
        }
      } else {
        throw Exception('PDF file does not exist at $tempPath');
      }

      // Try opening with url_launcher
      debugPrint('Attempting to open PDF with url_launcher...');
      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('PDF opened successfully with url_launcher');
      } else {
        debugPrint('url_launcher failed, trying OpenFile...');
        // Fallback to OpenFile
        final result = await OpenFile.open(file.path);
        debugPrint('OpenFile result: ${result.message}');
        if (result.type != ResultType.done) {
          throw Exception('Failed to open PDF with OpenFile: ${result.message}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error opening PDF: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorAlert('Failed to open PDF: $e');
    }
  }

  void _showErrorAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showReportOptions(Report report) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        message: Text(
          report.description,
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
        ),
        actions: [
          if (report.status == ReportStatus.pending) ...[
            CupertinoActionSheetAction(
              onPressed: () {
                _updateReportStatus(report, ReportStatus.accepted);
                Navigator.pop(context);
              },
              child: const Text(
                'Accept Report',
                style: TextStyle(color: CupertinoColors.systemGreen),
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                _updateReportStatus(report, ReportStatus.rejected);
                Navigator.pop(context);
              },
              isDestructiveAction: true,
              child: const Text('Reject Report'),
            ),
          ],
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _viewReportPdf(context, report.pdfUrl);
            },
            child: const Text(
              'View PDF Report',
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _updateReportStatus(Report report, ReportStatus newStatus) {
    setState(() {
      _pendingReports.removeWhere((r) => r.id == report.id);
      _acceptedReports.removeWhere((r) => r.id == report.id);
      _rejectedReports.removeWhere((r) => r.id == report.id);
      final updatedReport = report.copyWith(status: newStatus);

      if (newStatus == ReportStatus.accepted) {
        _acceptedReports.add(updatedReport);
      } else {
        _rejectedReports.add(updatedReport);
      }

      final overlay = OverlayEntry(
        builder: (context) => _buildToastNotification(
          message: 'Report ${newStatus == ReportStatus.accepted ? 'accepted' : 'rejected'}',
          isSuccess: newStatus == ReportStatus.accepted,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? CupertinoColors.systemGreen.withOpacity(0.9)
                        : CupertinoColors.systemRed.withOpacity(0.9),
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
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDarkMode ? CupertinoColors.systemBackground.darkColor : CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Kavach',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: isDarkMode ? CupertinoColors.systemBackground.darkColor : CupertinoColors.systemBackground,
        border: null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? CupertinoColors.systemBackground.darkColor : CupertinoColors.systemBackground,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedIndex,
                backgroundColor: isDarkMode ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.systemGrey6,
                thumbColor: isDarkMode ? CupertinoColors.systemBackground : CupertinoColors.white,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Pending', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Accepted', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Rejected', style: TextStyle(fontWeight: FontWeight.w600)),
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
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator(radius: 16))
                  : _buildReportList(_getReportsForCurrentTab()),
            ),
          ],
        ),
      ),
    );
  }

  List<Report> _getReportsForCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _pendingReports;
      case 1:
        return _acceptedReports;
      case 2:
        return _rejectedReports;
      default:
        return [];
    }
  }

  Widget _buildReportList(List<Report> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text_search,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No reports found',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return ReportCard(
          report: report,
          onPdfTap: () => _viewReportPdf(context, report.pdfUrl),
          onCardTap: () => _showReportOptions(report),
        );
      },
    );
  }
}