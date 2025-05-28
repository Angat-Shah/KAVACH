import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:kavach/services/verhoeff.dart';
import 'complaint_form_screen2.dart';

class PersonalInformationScreen extends StatefulWidget {
  final CameraDescription? camera;
  const PersonalInformationScreen({super.key, this.camera});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();

  // Validation states
  bool _isAadhaarValid = false;
  String? _aadhaarError;
  String? _maskedAadhaar;
  bool _isPhoneValid = false;
  String? _phoneError;
  bool _isFormValid = false;
  bool _consentGiven = false;

  // Track field interaction
  final Map<String, bool> _fieldTouched = {
    'fullName': false,
    'phone': false,
    'address': false,
    'aadhaar': false,
  };

  // Debouncer for real-time validations
  late final Debouncer<String> _aadhaarDebouncer;
  late final Debouncer<String> _phoneDebouncer;

  @override
  void initState() {
    super.initState();
    // Initialize debouncers
    _aadhaarDebouncer = Debouncer<String>(
      const Duration(milliseconds: 500),
      initialValue: '',
      onChanged: _validateAadhaar,
    );
    _phoneDebouncer = Debouncer<String>(
      const Duration(milliseconds: 500),
      initialValue: '',
      onChanged: _validatePhone,
    );

    // Add listeners for form field changes
    _fullNameController.addListener(() {
      if (_fieldTouched['fullName']!) {
        _updateFormValidity();
      }
    });
    _phoneController.addListener(() {
      if (_fieldTouched['phone']!) {
        _phoneDebouncer.setValue(_phoneController.text.replaceAll(' ', ''));
        _updateFormValidity();
      }
    });
    _addressController.addListener(() {
      if (_fieldTouched['address']!) {
        _updateFormValidity();
      }
    });
    _idNumberController.addListener(() {
      if (_fieldTouched['aadhaar']!) {
        _aadhaarDebouncer.setValue(
          _idNumberController.text.replaceAll(' ', ''),
        );
        _updateFormValidity();
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _idNumberController.dispose();
    _aadhaarDebouncer.cancel();
    _phoneDebouncer.cancel();
    super.dispose();
  }

  // Mask Aadhaar number
  String _maskAadhaar(String aadhaar) {
    if (aadhaar.length != 12) return aadhaar;
    return 'XXXX-XXXX-${aadhaar.substring(8)}';
  }

  // Format Aadhaar input
  String _formatAadhaar(String value) {
    String digits = value.replaceAll(' ', '');
    if (digits.length > 12) {
      digits = digits.substring(0, 12);
    }
    StringBuffer formatted = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted.write(' ');
      }
      formatted.write(digits[i]);
    }
    return formatted.toString();
  }

  // Format Phone input
  String _formatPhone(String value) {
    String digits = value.replaceAll(' ', '');
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }
    StringBuffer formatted = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5) {
        formatted.write(' ');
      }
      formatted.write(digits[i]);
    }
    return formatted.toString();
  }

  // Validate Aadhaar number
  void _validateAadhaar(String value) {
    value = value.replaceAll(' ', '');
    if (!_fieldTouched['aadhaar']!) return;

    setState(() {
      _aadhaarError = null;
      _isAadhaarValid = false;
      _maskedAadhaar = null;
    });

    if (value.isEmpty) {
      setState(() {
        _aadhaarError = 'Please enter your Aadhaar number';
      });
      _updateFormValidity();
      return;
    }

    if (!RegExp(r'^\d{12}$').hasMatch(value)) {
      setState(() {
        _aadhaarError = 'Aadhaar number must be 12 digits';
      });
      _updateFormValidity();
      return;
    }

    // Verify checksum using Verhoeff algorithm
    bool isValid = Verhoeff.validate(value);
    setState(() {
      _isAadhaarValid = isValid;
      if (isValid) {
        _maskedAadhaar = _maskAadhaar(value);
      } else {
        _aadhaarError = 'Invalid Aadhaar number';
      }
    });
    _updateFormValidity();
  }

  // Validate phone number
  void _validatePhone(String value) {
    if (!_fieldTouched['phone']!) return;

    setState(() {
      _phoneError = null;
      _isPhoneValid = false;
    });

    if (value.isEmpty) {
      setState(() {
        _phoneError = 'Please enter your phone number';
      });
      _updateFormValidity();
      return;
    }

    if (!RegExp(r'^\+?\d{10,12}$').hasMatch(value)) {
      setState(() {
        _phoneError = 'Enter a valid phone number (10-12 digits)';
      });
      _updateFormValidity();
      return;
    }

    setState(() {
      _isPhoneValid = true;
    });
    _updateFormValidity();
  }

  // Update form validity
  void _updateFormValidity() {
    final isFormFieldsValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _isFormValid =
          isFormFieldsValid &&
          _isAadhaarValid &&
          _isPhoneValid &&
          _consentGiven;
    });
  }

  // Handle form submission
  void _onSubmit() {
    _fieldTouched.updateAll((key, value) => true); // Mark all fields as touched
    if (_formKey.currentState!.validate() &&
        _isAadhaarValid &&
        _isPhoneValid &&
        _consentGiven) {
      final userData = {
        'fullName': _fullNameController.text,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
        'idNumber':
            _maskedAadhaar!, // Assert non-null since _isAadhaarValid ensures it
      };
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => IncidentDetailsScreen(
                key: const ValueKey('IncidentDetailsScreen'),
                camera: widget.camera,
                userData: userData,
              ),
        ),
      );
    } else if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide consent to proceed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Report a Crime',
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Step 1 of 2 : Contact Information',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildInputField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (!_fieldTouched['fullName']!) return null;
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                          return 'Name can only contain letters and spaces';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      maxLength: 11, // 10 digits + 1 space
                      onChanged: (value) {
                        final formatted = _formatPhone(value);
                        if (formatted != value) {
                          _phoneController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                              offset: formatted.length,
                            ),
                          );
                        }
                        _fieldTouched['phone'] = true;
                        _updateFormValidity();
                      },
                      validator: (value) {
                        if (!_fieldTouched['phone']!) return null;
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (_phoneError != null) {
                          return _phoneError;
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter your address',
                      prefixIcon: Icons.location_on_outlined,
                      validator: (value) {
                        if (!_fieldTouched['address']!) return null;
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        if (value.length < 5) {
                          return 'Address must be at least 5 characters';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      controller: _idNumberController,
                      label: 'Aadhaar Number',
                      hint: 'Enter your 12-digit Aadhaar number',
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      maxLength: 14, // 12 digits + 2 spaces
                      onChanged: (value) {
                        final formatted = _formatAadhaar(value);
                        if (formatted != value) {
                          _idNumberController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                              offset: formatted.length,
                            ),
                          );
                        }
                        _fieldTouched['aadhaar'] = true;
                        _updateFormValidity();
                      },
                      validator: (value) {
                        if (!_fieldTouched['aadhaar']!) return null;
                        if (value == null || value.isEmpty) {
                          return 'Please enter your Aadhaar number';
                        }
                        if (_aadhaarError != null) {
                          return _aadhaarError;
                        }
                        return null;
                      },
                      isLast: true,
                    ),
                    if (_isAadhaarValid && _maskedAadhaar != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Masked Aadhaar: $_maskedAadhaar',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: _consentGiven,
                          activeColor: const Color(0xFF000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _consentGiven = value ?? false;
                              _updateFormValidity();
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'I consent to provide my Aadhaar number for identity verification',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isFormValid ? _onSubmit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F2937),
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
    bool isLast = false,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
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
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 20),
              counterText: '',
            ),
            style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
            validator: (value) => validator(value),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged:
                onChanged ??
                (value) {
                  final fieldKey =
                      controller == _fullNameController
                          ? 'fullName'
                          : controller == _phoneController
                          ? 'phone'
                          : controller == _addressController
                          ? 'address'
                          : 'aadhaar';
                  _fieldTouched[fieldKey] = true;
                  _updateFormValidity();
                },
            onTap: () {
              // Do not mark as touched on initial tap
            },
          ),
        ],
      ),
    );
  }
}