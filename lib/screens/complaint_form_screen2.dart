import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'home_screen.dart';
import 'package:camera/camera.dart';
import '../main.dart';

class IncidentDetailsScreen extends StatefulWidget {
  final CameraDescription? camera;
  final Map<String, String> userData;

  const IncidentDetailsScreen({
    super.key,
    required this.camera,
    required this.userData,
  });

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, bool> _fieldTouched = {
    'incidentType': false,
    'date': false,
    'time': false,
    'location': false,
    'description': false,
  };

  String? _selectedIncidentType;
  DateTime? _incidentDateTime;
  final List<File> _evidenceImages = [];
  bool _confirmationChecked = false;
  bool _isSubmitting = false;
  bool _isFormValid = false;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _incidentTypes = [
    'Theft',
    'Assault',
    'Fraud',
    'Vandalism',
    'Harassment',
    'Cybercrime',
    'Domestic Violence',
    'Public Nuisance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _locationController.addListener(_updateFormValidity);
    _descriptionController.addListener(_updateFormValidity);
    _updateFormValidity();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _incidentDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007AFF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C2526),
              surface: Color(0xFFF2F2F7),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFF007AFF)),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Color(0xFFF2F2F7)),
          ),
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [child!, SizedBox(height: 16)],
              ),
            ),
          ),
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _incidentDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _incidentDateTime?.hour ?? DateTime.now().hour,
          _incidentDateTime?.minute ?? DateTime.now().minute,
        );
        _dateController.text = DateFormat('MMM dd, yyyy').format(pickedDate);
        _timeController.text =
            _incidentDateTime != null
                ? DateFormat('hh:mm a').format(_incidentDateTime!)
                : '';
      });
      if (_timeController.text.isEmpty) _selectTime();
      _updateFormValidity();
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime:
          _incidentDateTime != null
              ? TimeOfDay.fromDateTime(_incidentDateTime!)
              : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007AFF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C2526),
              surface: Color(0xFFF2F2F7),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFF007AFF)),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Color(0xFFF2F2F7)),
          ),
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [child!, SizedBox(height: 16)],
              ),
            ),
          ),
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _incidentDateTime = DateTime(
          _incidentDateTime?.year ?? DateTime.now().year,
          _incidentDateTime?.month ?? DateTime.now().month,
          _incidentDateTime?.day ?? DateTime.now().day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _timeController.text = DateFormat('hh:mm a').format(_incidentDateTime!);
      });
      _updateFormValidity();
    }
  }

  Future<void> _pickImage() async {
    if (_evidenceImages.length >= 5) {
      _showSnackBar('Maximum 5 images can be uploaded', Colors.red);
      return;
    }
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image != null) {
      final fileSize = await File(image.path).length();
      if (fileSize > 5 * 1024 * 1024) {
        _showSnackBar('Image size must be less than 5MB', Colors.red);
        return;
      }

      final extension = image.path.toLowerCase().split('.').last;
      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        _showSnackBar(
          'Only JPG, JPEG, or PNG images are supported',
          Colors.red,
        );
        return;
      }

      setState(() {
        _evidenceImages.add(File(image.path));
      });
      _updateFormValidity();
    }
  }

  Future<String> _generatePDF() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final reportId = 'RPT-${DateFormat('yyyyMMdd-HHmm').format(now)}';

    // Helper function to create a page content
    pw.Widget buildPageContent() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Kavach Crime Report',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1F2937),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Official Incident Report',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColor.fromInt(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              pw.Text(
                'ID: $reportId',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1F2937),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 1, color: PdfColor.fromInt(0xFFE5E7EB)),
          pw.SizedBox(height: 24),
          pw.Text(
            'Report Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF1F2937),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(now)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xFF6B7280),
                ),
              ),
              pw.Text(
                'Status: Pending',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xFF6B7280),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Contact Information',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF1F2937),
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Full Name', widget.userData['fullName'] ?? ''),
          _buildInfoRow('Phone', widget.userData['phoneNumber'] ?? ''),
          _buildInfoRow('Address', widget.userData['address'] ?? ''),
          _buildInfoRow('Masked Aadhaar', widget.userData['idNumber'] ?? ''),
          pw.SizedBox(height: 24),
          pw.Text(
            'Incident Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF1F2937),
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Type', _selectedIncidentType ?? ''),
          _buildInfoRow(
            'Date & Time',
            _incidentDateTime != null
                ? DateFormat('MMM dd, yyyy hh:mm a').format(_incidentDateTime!)
                : '',
          ),
          _buildInfoRow('Location', _locationController.text),
          _buildInfoRow(
            'Description',
            _descriptionController.text,
            isMultiline: true,
          ),
        ],
      );
    }

    // Add main content
    final mainContent = buildPageContent();
    final pageTheme = pw.PageTheme(
      margin: pw.EdgeInsets.all(40),
      buildBackground:
          (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: PdfColor.fromInt(0xFFFFFFFF)),
          ),
    );

    // Add first page
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (pw.Context context) => [mainContent],
      ),
    );

    // Add evidence pages for images
    if (_evidenceImages.isNotEmpty) {
      const imagesPerPage = 2; // Display up to 2 images per page
      for (int i = 0; i < _evidenceImages.length; i += imagesPerPage) {
        final pageImages = _evidenceImages.skip(i).take(imagesPerPage).toList();

        pdf.addPage(
          pw.Page(
            pageTheme: pageTheme,
            build:
                (pw.Context context) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Evidence',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF1F2937),
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    ...pageImages.asMap().entries.map((entry) {
                      final index = i + entry.key;
                      final imageFile = entry.value;
                      final image = pw.MemoryImage(imageFile.readAsBytesSync());
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Evidence ${index + 1} (Image)',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Image(
                            image,
                            width: 300,
                            height: 300,
                            fit: pw.BoxFit.contain,
                          ),
                          pw.SizedBox(height: 16),
                        ],
                      );
                    }),
                  ],
                ),
          ),
        );
      }
    }

    // Add authorization page
    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Authorization',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1F2937),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'This report is officially filed through the Kavach Safety Platform. The information provided is verified and authorized for submission. Filing false reports may result in legal consequences.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromInt(0xFF6B7280),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Kavach Safety Platform',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/kavach_$reportId.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  pw.Widget _buildInfoRow(
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1F2937),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColor.fromInt(0xFF1F2937),
              ),
              maxLines: isMultiline ? null : 1,
            ),
          ),
        ],
      ),
    );
  }

  void _updateFormValidity() {
    final isFormFieldsValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _isFormValid =
          isFormFieldsValid &&
          _selectedIncidentType != null &&
          _incidentDateTime != null &&
          _locationController.text.isNotEmpty &&
          _descriptionController.text.isNotEmpty &&
          _confirmationChecked;
    });
  }

  Future<void> _submitReport() async {
    _fieldTouched.updateAll((key, value) => true);
    _updateFormValidity();
    if (!_isFormValid) {
      if (!_confirmationChecked) {
        _showSnackBar('Please confirm the information', Colors.red);
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final pdfPath = await _generatePDF();
      final myApp = context.findAncestorWidgetOfExactType<MyApp>();
      final chatService = myApp?.chatService;

      if (chatService == null) throw Exception('ChatService not available');

      final reportData = {
        'reportId':
            'KAVACH-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}',
        'pdfPath': pdfPath,
        'incidentType': _selectedIncidentType,
        'dateTime': _incidentDateTime?.toIso8601String(),
        'location': _locationController.text,
        'description': _descriptionController.text,
        'evidenceCount': _evidenceImages.length,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': user.uid,
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .doc(reportData['reportId'] as String) // Explicit cast to String
          .set(reportData);

      _showSnackBar('Report submitted successfully! PDF saved.', Colors.green);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  HomeScreen(camera: widget.camera, chatService: chatService),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF1F2937),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Kavach',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child:
              _isSubmitting
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1F2937)),
                  )
                  : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Report a Crime',
                                        style: TextStyle(
                                          color: Color(0xFF1F2937),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Step 2 of 2: Incident Details',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'Incident Type',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.category_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                                hint: Text(
                                  'Select incident type',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                  ),
                                ),
                                value: _selectedIncidentType,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey,
                                ),
                                isExpanded: true,
                                style: const TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 15,
                                ),
                                items:
                                    _incidentTypes.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedIncidentType = newValue;
                                    _fieldTouched['incidentType'] =
                                        _selectedIncidentType != null;
                                  });
                                  _updateFormValidity();
                                },
                                validator: (value) {
                                  if (!_fieldTouched['incidentType']!) {
                                    return null;
                                  }
                                  return value == null
                                      ? 'Please select an incident type'
                                      : null;
                                },
                                autovalidateMode: AutovalidateMode.disabled,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Date of Incident',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'Select date',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF007AFF),
                                    width: 1,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF1F2937),
                              ),
                              onTap: _selectDate,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  _fieldTouched['date'] = true;
                                }
                                _updateFormValidity();
                              },
                              validator: (value) {
                                if (!_fieldTouched['date']!) return null;
                                return value!.isEmpty
                                    ? 'Please select a date'
                                    : null;
                              },
                              autovalidateMode: AutovalidateMode.disabled,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Time of Incident',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _timeController,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'Select time',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF007AFF),
                                    width: 1,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(
                                  Icons.access_time,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF1F2937),
                              ),
                              onTap: _selectTime,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  _fieldTouched['time'] = true;
                                }
                                _updateFormValidity();
                              },
                              validator: (value) {
                                if (!_fieldTouched['time']!) return null;
                                return value!.isEmpty
                                    ? 'Please select a time'
                                    : null;
                              },
                              autovalidateMode: AutovalidateMode.disabled,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Location',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                hintText: 'Enter location of the incident',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF007AFF),
                                    width: 1,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF1F2937),
                              ),
                              validator: (value) {
                                if (!_fieldTouched['location']!) return null;
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the location';
                                }
                                if (value.length < 5) {
                                  return 'Location must be at least 5 characters';
                                }
                                return null;
                              },
                              autovalidateMode: AutovalidateMode.disabled,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  _fieldTouched['location'] = true;
                                }
                                _updateFormValidity();
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Incident Description',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Describe what happened in detail',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF007AFF),
                                    width: 1,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF1F2937),
                              ),
                              validator: (value) {
                                if (!_fieldTouched['description']!) return null;
                                if (value == null || value.isEmpty) {
                                  return 'Please describe the incident';
                                }
                                if (value.length < 20) {
                                  return 'Description must be at least 20 characters';
                                }
                                return null;
                              },
                              autovalidateMode: AutovalidateMode.disabled,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  _fieldTouched['description'] = true;
                                }
                                _updateFormValidity();
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Upload Evidence (Optional, up to 5 images)',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: [
                                ..._evidenceImages.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final image = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      width: double.infinity,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.file(
                                              image,
                                              width: double.infinity,
                                              height: 160,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red[400],
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _evidenceImages.removeAt(
                                                    index,
                                                  );
                                                });
                                                _updateFormValidity();
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                if (_evidenceImages.length < 5)
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      width: double.infinity,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_outlined,
                                              color: Colors.grey,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Tap to upload image (${_evidenceImages.length}/5)',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'JPEG, PNG, or JPG up to 5MB',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.scale(
                                  scale: 1.1,
                                  child: Checkbox(
                                    value: _confirmationChecked,
                                    onChanged: (value) {
                                      setState(() {
                                        _confirmationChecked = value ?? false;
                                      });
                                      _updateFormValidity();
                                    },
                                    activeColor: const Color(0xFF1F2937),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'I confirm that the information provided is true and accurate to the best of my knowledge. I understand that filing a false report may lead to legal consequences.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isFormValid && !_isSubmitting
                                        ? _submitReport
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F2937),
                                  disabledBackgroundColor: Colors.grey[300],
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Submit Report',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
        ),
      ),
    );
  }
}
