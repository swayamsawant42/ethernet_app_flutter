import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import '../services/api_service.dart';

// --- ETHERNETXPRESS BRAND COLORS (from your main.dart) ---
// These aren't strictly needed here, but good for reference
const Color exPrimaryBlue = Color(0xFF1E407A);
const Color exPrimaryTeal = Color(0xFF30A8B5);

class NewSubscriptionPage extends StatefulWidget {
  const NewSubscriptionPage({super.key});

  @override
  _NewSubscriptionPageState createState() => _NewSubscriptionPageState();
}

class _NewSubscriptionPageState extends State<NewSubscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _otherSourceController = TextEditingController();

  String _selectedSource = 'Field Visits';
  String _selectedServiceType = 'SME';
  bool _showOtherField = false;
  bool _isSubmitting = false;

  bool get _isFormValid {
    if (_selectedSource == 'Other' &&
        _otherSourceController.text.trim().isEmpty) {
      return false;
    }
    if (_nameController.text.trim().isEmpty) return false;
    final phone = _phoneController.text.trim();
    if (phone.length != 10 || int.tryParse(phone) == null) return false;
    if (_addressController.text.trim().isEmpty) return false;
    if (_areaController.text.trim().isEmpty) return false;
    return true;
  }

  // --- NO LOGIC CHANGES ---
  String _generateLeadId() {
    final r = Random();
    final sixDigits = r.nextInt(900000) + 100000;
    return 'LD${sixDigits.toString()}';
  }

  Future<void> _saveOffline() async {
    final prefs = await SharedPreferences.getInstance();
    final lead = {
      'id': _generateLeadId(),
      'source': _selectedSource == 'Other'
          ? _otherSourceController.text.trim()
          : _selectedSource,
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'serviceType': _selectedServiceType,
      'area': _areaController.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'offline',
    };
    final existing = prefs.getStringList('offline_leads') ?? [];
    existing.add(lead.toString());
    await prefs.setStringList('offline_leads', existing);
  }

  Future<Map<String, dynamic>> _submitToDestinations() async {
    try {
      // Get the final source value (either selected or "Other" text)
      final finalSource = _selectedSource == 'Other'
          ? _otherSourceController.text.trim()
          : _selectedSource;

      // Call the API to create the lead
      final result = await _apiService.createLead(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        source: finalSource,
        serviceType: _selectedServiceType,
      );

      if (result != null) {
        // Success - API call worked
        // API response structure: { success: true, data: { id: ..., unique_id: ... } }
        final data = result['data'] ?? result;
        final leadId = data['unique_id'] ?? result['unique_id'] ?? result['uniqueId'] ?? data['id']?.toString() ?? _generateLeadId();
        // Extract database id (the actual integer ID from the database)
        final dbId = data['id'] ?? result['id'];
        return {
          'google': true,
          'platform': true,
          'leadId': leadId.toString(),
          'leadDbId': dbId != null ? (dbId is int ? dbId : int.tryParse(dbId.toString())) : null,
        };
      } else {
        // API call failed
        return {
          'google': false,
          'platform': false,
          'error': 'Failed to create lead. Please check your connection and try again.',
        };
      }
    } catch (e) {
      print("Error submitting lead: $e");
      return {
        'google': false,
        'platform': false,
        'error': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  Future<void> _onSaveOffline() async {
    if (!_isFormValid) return;
    setState(() => _isSubmitting = true);
    await _saveOffline();
    final leadId = _generateLeadId();
    setState(() {
      _isSubmitting = false;
    });
    _navigateToSuccess(leadId, google: false, platform: false, isOffline: true);
  }

  Future<void> _onSubmit() async {
    if (!_isFormValid) return;
    setState(() => _isSubmitting = true);
    
    try {
      final results = await _submitToDestinations();
      
      // Get lead ID from API response or generate one
      String leadId = _generateLeadId();
      if (results.containsKey('leadId') && results['leadId'] != null) {
        leadId = results['leadId'].toString();
      }
      
      setState(() {
        _isSubmitting = false;
      });
      
      if (results['google'] == true && results['platform'] == true) {
        // Success - clear form and navigate
        _nameController.clear();
        _phoneController.clear();
        _addressController.clear();
        _areaController.clear();
        _otherSourceController.clear();
        _selectedSource = 'Field Visits';
        _selectedServiceType = 'SME';
        _showOtherField = false;
        
        // Get database ID from results if available
        final leadDbId = results['leadDbId'] as int?;
        
        _navigateToSuccess(
          leadId,
          google: true,
          platform: true,
          isOffline: false,
          leadDbId: leadDbId,
        );
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                results['error'] ?? 'Failed to submit lead. Please try again.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToSuccess(
    String leadId, {
    required bool google,
    required bool platform,
    required bool isOffline,
    int? leadDbId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeadSuccessPage(
          leadId: leadId,
          googleSuccess: google,
          platformSuccess: platform,
          leadDbId: leadDbId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _otherSourceController.dispose();
    super.dispose();
  }
  // --- END OF LOGIC ---

  void _onFieldChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // --- THEME DATA ---
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    // ---

    final isButtonsEnabled = _isFormValid && !_isSubmitting;

    return Scaffold(
      // backgroundColor removed, theme will handle it
      appBar: AppBar(
        // backgroundColor, leading icon color, and title textStyle
        // are now all handled by the appBarTheme in main.dart
        title: const Text('New Subscription'),
        centerTitle: true,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- Replaced styled Container with themed Card ---
              Card(
                // All styling (color, shadow, radius) comes from cardTheme
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Using theme text styles ---
                        Text('Lead Details', style: textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Capture new customer information',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),

                        Text('Source *', style: textTheme.titleSmall),
                        const SizedBox(height: 6),
                        // --- Dropdown now uses inputDecorationTheme ---
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.white, // Explicitly white background
                          initialValue: _selectedSource,
                          items: ['Field Visits', 'Events', 'Personal', 'Other']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (val) {
                            _selectedSource = val ?? 'Field Visits';
                            _showOtherField = _selectedSource == 'Other';
                            _onFieldChanged();
                          },
                          // decoration removed, theme will apply it
                        ),
                        const SizedBox(height: 12),

                        if (_showOtherField) ...[
                          // --- TextFormField now uses inputDecorationTheme ---
                          TextFormField(
                            controller: _otherSourceController,
                            onChanged: (_) => _onFieldChanged(),
                            decoration: const InputDecoration(
                              hintText: 'Mention source',
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        Text('Customer Name *', style: textTheme.titleSmall),
                        const SizedBox(height: 6),
                        // --- TextFormField now uses inputDecorationTheme ---
                        TextFormField(
                          controller: _nameController,
                          onChanged: (_) => _onFieldChanged(),
                          decoration: const InputDecoration(
                            hintText: 'Enter customer name',
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text('Phone Number *', style: textTheme.titleSmall),
                        const SizedBox(height: 6),
                        // --- TextFormField now uses inputDecorationTheme ---
                        TextFormField(
                          controller: _phoneController,
                          onChanged: (_) => _onFieldChanged(),
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: 'Enter 10-digit phone number',
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text('Address *', style: textTheme.titleSmall),
                        const SizedBox(height: 6),
                        // --- TextFormField now uses inputDecorationTheme ---
                        TextFormField(
                          controller: _addressController,
                          onChanged: (_) => _onFieldChanged(),
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Enter full address',
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text('Service Type *', style: textTheme.titleSmall),
                        const SizedBox(height: 6),
                        // --- Dropdown now uses inputDecorationTheme ---
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.white, // Explicitly white background
                          value: _selectedServiceType,
                          items: ['SME', 'BROADBAND', 'LEASEDLINE']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (val) {
                            _selectedServiceType = val ?? 'SME';
                            _onFieldChanged();
                          },
                          // decoration removed, theme will apply it
                        ),
                        const SizedBox(height: 12),

                        Text('Area *', style: textTheme.titleSmall),
                        const SizedBox(height: 6),
                        // --- TextFormField now uses inputDecorationTheme ---
                        TextFormField(
                          controller: _areaController,
                          onChanged: (_) => _onFieldChanged(),
                          decoration: const InputDecoration(
                            hintText: 'Enter area/location',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // --- "Info" box styled with theme colors ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  // Using surfaceVariant for info box background
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surface, // White
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dual Destination Sync',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lead will be sent to both Google Sheet and Lead Platform',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- Buttons ---
              Row(
                children: [
                  Expanded(
                    // --- Styled OutlinedButton ---
                    child: SizedBox(
                      height: 50, // Match ElevatedButton theme padding
                      child: OutlinedButton(
                        onPressed: isButtonsEnabled ? _onSaveOffline : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : const Text('Save Offline'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // --- Themed ElevatedButton ---
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isButtonsEnabled ? _onSubmit : null,
                        // style removed, elevatedButtonTheme will apply
                        child: _isSubmitting
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  color: colorScheme.onPrimary,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------
// Success Page
// ------------------------------------
class LeadSuccessPage extends StatefulWidget {
  final String leadId;
  final bool googleSuccess;
  final bool platformSuccess;
  final int? leadDbId;

  const LeadSuccessPage({
    super.key,
    required this.leadId,
    required this.googleSuccess,
    required this.platformSuccess,
    this.leadDbId,
  });

  @override
  State<LeadSuccessPage> createState() => _LeadSuccessPageState();
}

class _LeadSuccessPageState extends State<LeadSuccessPage> {
  final ApiService _apiService = ApiService();
  bool _isSendingLink = false;

  Future<void> _sendCustomerDetailsLink() async {
    if (widget.leadDbId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lead ID not available. Cannot send link.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSendingLink = true;
    });

    try {
      final result = await _apiService.sendCustomerDetailsFrom(widget.leadDbId!);
      
      if (mounted) {
        setState(() {
          _isSendingLink = false;
        });

        if (result != null && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Customer details link sent successfully!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result?['message'] ?? 'Failed to send link. Please try again.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingLink = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending link: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // --- Replaced Container with themed Card ---
  Widget _statusBox(
    String title,
    bool ok,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      // Using Card for consistent styling
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ok
                ? Container(
                    height: 26,
                    width: 26,
                    decoration: BoxDecoration(
                      // Using theme color
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.check,
                      // Using theme color
                      color: colorScheme.onPrimary,
                      size: 18,
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- THEME DATA ---
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    // ---

    return Scaffold(
      // backgroundColor removed, theme will handle it
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // --- Styled with brand "Secondary" color ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // Using brand secondary color
                  color: colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 36,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Lead Captured', style: textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Your Lead has been recorded',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Lead ID', style: textTheme.titleSmall),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        widget.leadId,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Submission Status',
                        style: textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _statusBox(
                      'Google Sheet',
                      widget.googleSuccess,
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 8),
                    _statusBox(
                      'Lead Platform',
                      widget.platformSuccess,
                      colorScheme,
                      textTheme,
                    ),

                    const SizedBox(height: 20),

                    // Send Link Button (only show if leadDbId is available)
                    if (widget.leadDbId != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSendingLink ? null : _sendCustomerDetailsLink,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: _isSendingLink
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.link, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Send Link',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // --- Replaced GestureDetector with OutlinedButton ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewSubscriptionPage(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: colorScheme.primaryContainer),
                          foregroundColor: colorScheme.primary,
                        ),
                        child: const Text(
                          'Capture Another Lead',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- Replaced GestureDetector with ElevatedButton ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DashboardPage(
                                // Note: You should pass real data here
                                employeeName: 'User',
                                employeeCount: 9,
                              ),
                            ),
                            (route) => false,
                          );
                        },
                        // Style comes from elevatedButtonTheme
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
    );
  }
}
