import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/field_survey.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'dashboard_page.dart';
import 'survey_responses_page.dart';

class FieldSurveyPage extends StatefulWidget {
  final FieldSurvey? existingSurvey;
  final bool navigateToCompletionOnSubmit;

  const FieldSurveyPage({
    super.key,
    this.existingSurvey,
    this.navigateToCompletionOnSubmit = true,
  });

  @override
  _FieldSurveyPageState createState() => _FieldSurveyPageState();
}

class _FieldSurveyPageState extends State<FieldSurveyPage> {
  // Survey fields
  String? q1Answer;
  List<String> q2Answers = [];
  String? q3Answer;
  TextEditingController q4Controller = TextEditingController();

  // Auto-capture fields
  String? location;
  String? latitude;
  String? longitude;
  String? dateTime;
  String? _editingSurveyId;
  bool get _isEditing => widget.existingSurvey != null;
  bool get _shouldAutoCaptureLocation => !_isEditing;

  bool allFilled = false;
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSurvey != null) {
      _prefillFromSurvey(widget.existingSurvey!);
    }
    if (_shouldAutoCaptureLocation) {
      _getLocation();
    }
    _loadProfile();
  }

  @override
  void dispose() {
    q4Controller.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      // Try to get location from LocationService first (uses cached or fresh)
      Map<String, double>? loc = await LocationService.getLocation();
      
      if (loc != null) {
        setState(() {
          latitude = loc['latitude']!.toStringAsFixed(4);
          longitude = loc['longitude']!.toStringAsFixed(4);
          location = "Auto Location";
          dateTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
          _checkAllFilled();
        });
        return;
      }

      // Fallback to direct Geolocator if LocationService doesn't have location
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        latitude = pos.latitude.toStringAsFixed(4);
        longitude = pos.longitude.toStringAsFixed(4);
        location = "Auto Location";
        dateTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
        _checkAllFilled();
      });
    } catch (e) {
      print("Location error: $e");
    }
  }

  void _prefillFromSurvey(FieldSurvey survey) {
    q1Answer = survey.serviceRating;
    q2Answers = List<String>.from(survey.likedFeaturesList);
    q3Answer = survey.heardFrom;
    q4Controller.text = survey.feedback ?? '';
    latitude = survey.latitude?.toStringAsFixed(4) ?? survey.latitude?.toString();
    longitude =
        survey.longitude?.toStringAsFixed(4) ?? survey.longitude?.toString();
    location = 'Recorded location';
    final created = survey.createdAt?.toLocal();
    if (created != null) {
      dateTime = DateFormat('dd/MM/yyyy hh:mm a').format(created);
    }
    _editingSurveyId = survey.id?.toString();
    _checkAllFilled();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getProfile();
      if (!mounted) return;
      setState(() {
        _profileData = profile;
      });
    } catch (e) {
      print("Profile load error: $e");
    }
  }

  void _checkAllFilled() {
    setState(() {
      allFilled =
          q1Answer != null &&
          q2Answers.isNotEmpty &&
          q3Answer != null &&
          q4Controller.text.trim().isNotEmpty &&
          location != null &&
          latitude != null &&
          longitude != null &&
          dateTime != null;
    });
  }

  void _toggleQ2Answer(String val) {
    setState(() {
      if (q2Answers.contains(val)) {
        q2Answers.remove(val);
      } else {
        q2Answers.add(val);
      }
      _checkAllFilled();
    });
  }

  Future<void> _submitSurvey() async {
    if (!allFilled || _isSubmitting) return;

    print("Starting survey submission...");
    print("Q1 Answer: $q1Answer");
    print("Q2 Answers: $q2Answers");
    print("Q3 Answer: $q3Answer");
    print("Q4 Feedback: ${q4Controller.text}");
    print("Latitude: $latitude, Longitude: $longitude");

    setState(() {
      _isSubmitting = true;
    });

    try {
      final profile = _profileData ?? await _apiService.getProfile();
      final contactNumber =
          profile?['phoneNumber']?.toString() ??
          profile?['phone']?.toString() ??
          profile?['contactNumber']?.toString() ??
          "N/A";
      final customerName = profile?['name'] ?? "N/A";
      final customerEmail = profile?['email'] ?? "no-email@unknown.com";

      final success = await _apiService.submitFieldSurvey(
        serviceRating: q1Answer ?? "",
        contactNumber: contactNumber,
        heardFrom: q3Answer ?? "",
        likedFeatures: q2Answers.join(
          ", ",
        ), // Convert array to comma-separated string
        feedback: q4Controller.text.trim(),
        customerName: customerName,
        customerEmail: customerEmail,
        latitude: double.tryParse(latitude ?? '') ?? 0.0,
        longitude: double.tryParse(longitude ?? '') ?? 0.0,
        surveyId: _editingSurveyId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.white,
            content: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    // Theme: Checkmark box
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.check, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Survey submitted successfully",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );

        if (widget.navigateToCompletionOnSubmit) {
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SurveyCompletedPage(),
              ),
            );
          });
        } else {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit survey. Please try again."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      print("Survey submit error: $e");
      print("Error type: ${e.runtimeType}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: ${e.toString()}"),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _saveOffline() async {
    if (!allFilled) return;

    try {
      final profile = _profileData ?? await _apiService.getProfile();
      final contactNumber =
          profile?['phoneNumber']?.toString() ??
          profile?['phone']?.toString() ??
          profile?['contactNumber']?.toString() ??
          "N/A";
      final customerName = profile?['name'] ?? "N/A";
      final customerEmail = profile?['email'] ?? "no-email@unknown.com";

      // Create survey data object
      final surveyData = {
        "serviceRating": q1Answer ?? "",
        "contactNumber": contactNumber,
        "heardFrom": q3Answer ?? "",
        "likedFeatures": q2Answers.join(", "),
        "feedback": q4Controller.text.trim(),
        "customerName": customerName,
        "customerEmail": customerEmail,
        "latitude": double.tryParse(latitude ?? '') ?? 0.0,
        "longitude": double.tryParse(longitude ?? '') ?? 0.0,
        "savedAt": DateTime.now().toIso8601String(),
        "dateTime": dateTime,
      };

      // Get existing offline surveys
      final prefs = await SharedPreferences.getInstance();
      final offlineSurveysKey = "offline_surveys";
      final existingSurveysJson = prefs.getString(offlineSurveysKey);

      List<Map<String, dynamic>> offlineSurveys = [];
      if (existingSurveysJson != null && existingSurveysJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(existingSurveysJson);
        offlineSurveys = decoded
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      // Add new survey to the list
      offlineSurveys.add(surveyData);

      // Save back to SharedPreferences
      final updatedSurveysJson = json.encode(offlineSurveys);
      await prefs.setString(offlineSurveysKey, updatedSurveysJson);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Theme: Primary Blue for info snackbars
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: Row(
            children: [
              Icon(Icons.save, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Survey saved offline (${offlineSurveys.length} total)",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Save offline error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save offline: ${e.toString()}"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        // Theme: AppBar is automatically styled by theme, but setting explicit for safety
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text("Field Survey", style: theme.appBarTheme.titleTextStyle),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View past responses',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SurveyResponsesPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _surveyHeader(theme),
            SizedBox(height: 16),
            _question1(theme),
            SizedBox(height: 12),
            _question2(theme),
            SizedBox(height: 12),
            _question3(theme),
            SizedBox(height: 12),
            _question4(theme),
            SizedBox(height: 12),
            _autoCaptureBox(theme),
            SizedBox(height: 50),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: theme.colorScheme.surface,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: allFilled ? _saveOffline : null,
                style: OutlinedButton.styleFrom(
                  // Theme: Blue border for outlined button
                  side: BorderSide(color: theme.colorScheme.primary),
                  foregroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Save Offline",
                  style: TextStyle(
                    color: allFilled ? theme.colorScheme.primary : Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: allFilled && !_isSubmitting ? _submitSurvey : null,
                style: ElevatedButton.styleFrom(
                  // Theme: Teal for primary action
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text("Save & Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _surveyHeader(ThemeData theme) {
    return _roundedBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Customer Satisfaction Survey",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Please help us to improve our services",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _question1(ThemeData theme) {
    List<String> options = ["Excellent", "Good", "Average", "Poor"];
    return _roundedBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How would you rate our services? *",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          ...options.map(
            (opt) => GestureDetector(
              onTap: () {
                setState(() {
                  q1Answer = opt;
                  _checkAllFilled();
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        // Theme: Use Teal if selected, otherwise grey
                        color: q1Answer == opt
                            ? theme.colorScheme.secondary
                            : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: q1Answer == opt
                        // Theme: Teal Check
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          )
                        : null,
                  ),
                  SizedBox(width: 8),
                  Text(opt, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _question2(ThemeData theme) {
    List<String> options = [
      "Easy to use",
      "Fast Service",
      "Good support",
      "Competitive pricing",
    ];
    return _roundedBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Which feature do you like most?",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "(Select all that apply)",
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          SizedBox(height: 8),
          ...options.map(
            (opt) => GestureDetector(
              onTap: () => _toggleQ2Answer(opt),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        // Theme: Use Teal if selected, otherwise grey
                        color: q2Answers.contains(opt)
                            ? theme.colorScheme.secondary
                            : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: q2Answers.contains(opt)
                        // Theme: Teal Check
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          )
                        : null,
                  ),
                  SizedBox(width: 8),
                  Text(opt, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _question3(ThemeData theme) {
    List<String> options = [
      "Social Media",
      "Friend",
      "Advertisement",
      "Website",
      "Other",
    ];
    return _roundedBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How did you hear about us? *",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: DropdownButton<String>(
              dropdownColor: Colors.white, // Explicitly white background
              hint: Text("Select an option"),
              value: q3Answer,
              isExpanded: true,
              underline: SizedBox(),
              items: options
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  q3Answer = val;
                  _checkAllFilled();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _question4(ThemeData theme) {
    return _roundedBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Any additional feedback or suggestions?",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: q4Controller,
            maxLines: 4,
            // Theme: Input decoration is handled by theme, but adding specific hint here
            decoration: InputDecoration(
              hintText: "Enter your detailed answer",
              // Prefix icon to match style
              prefixIcon: Icon(
                Icons.comment_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            onChanged: (_) => _checkAllFilled(),
          ),
        ],
      ),
    );
  }

  Widget _autoCaptureBox(ThemeData theme) {
    return _roundedBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Theme: Teal icon
              Icon(Icons.check_circle, color: theme.colorScheme.secondary),
              SizedBox(width: 8),
              Text(
                "Auto-Captured",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Text(
            "Location and time information",
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          SizedBox(height: 10),
          if (location != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: theme.colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      "$location\nLat: $latitude\nLong: $longitude",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, color: theme.colorScheme.primary),
                    SizedBox(width: 8),
                    Text("$dateTime", style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            )
          else
            Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.secondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _roundedBox(Widget child, {Color? color}) {
    return Card(
      // Theme: Using Card instead of Container for shadow and rounded corners
      color: color ?? Colors.white,
      child: Padding(padding: EdgeInsets.all(16), child: child),
    );
  }
}

// ---------------------------------------------------
// Survey Completed Page
// ---------------------------------------------------
class SurveyCompletedPage extends StatefulWidget {
  @override
  _SurveyCompletedPageState createState() => _SurveyCompletedPageState();
}

class _SurveyCompletedPageState extends State<SurveyCompletedPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int _todayCount = 0;
  int _monthCount = 0;
  String _estimatedPayout = "₹ 0";
  Map<String, dynamic>? _profileData;
  static const double _defaultPayoutPerSurvey = 0.30; // Rs. 0.30 per survey (matches server)

  List<FieldSurvey> _userSurveys = [];
  bool _isLoadingStats = false; // Guard to prevent multiple simultaneous calls

  @override
  void initState() {
    super.initState();
    // Always reload stats when page is opened (to get latest counts)
    _loadSurveyStats();
  }

  Future<void> _loadSurveyStats() async {
    // Prevent multiple simultaneous calls
    if (_isLoadingStats) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _isLoadingStats = true;
    });

    try {
      final profile = await _apiService.getProfile();
      if (profile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = _asInt(profile['id']);
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final employeCode = profile['employeCode']?.toString() ??
          profile['employeeCode']?.toString() ??
          profile['employeeId']?.toString();
      final phoneNumber = profile['phoneNumber']?.toString();

      setState(() {
        _profileData = profile;
      });

      final summaryFuture = _apiService.getSurveySummary();
      final userSurveys = await _fetchAllSurveysForUser(
        userId,
        employeCode: employeCode,
        phoneNumber: phoneNumber,
      );
      // Fetch ALL surveys (not filtered by user) to get total counts
      // IMPORTANT: Don't pass userId or employeCode to get ALL surveys
      // The API service only adds params if they're not null, so we can omit them
      final allSurveysData = await _apiService.getFieldSurveys(
        page: 1,
        limit: 1000, // Get all surveys
        // Omit userId and employeCode to get ALL surveys
      );
      
      await summaryFuture; // Wait for summary (we don't use it for counts, but keep for consistency)

      // Server uses IST (Indian Standard Time, UTC+5:30) for date boundaries
      // "Today" in IST is from 00:00:00 IST to 23:59:59 IST
      // After 12:00 AM IST, it becomes the next day
      //
      // Server creates: new Date(year, month, day) in IST
      // Example: new Date(2025, 11, 2) = Dec 2, 2025 00:00:00 IST
      // Sequelize converts this to UTC for database comparison:
      // Dec 2, 2025 00:00:00 IST = Dec 1, 2025 18:30:00 UTC
      //
      // To match server behavior, we need to:
      // 1. Get current time and convert to IST
      // 2. Determine "today" in IST (year, month, day)
      // 3. Convert IST date boundaries to UTC boundaries
      
      const istOffset = Duration(hours: 5, minutes: 30); // IST is UTC+5:30
      final nowUTC = DateTime.now().toUtc();
      final nowIST = nowUTC.add(istOffset); // Convert UTC to IST
      
      // Determine "today" in IST (year, month, day components)
      final istYear = nowIST.year;
      final istMonth = nowIST.month;
      final istDay = nowIST.day;
      
      // Create IST date boundaries as UTC DateTime, then subtract offset
      // Dec 2, 2025 00:00:00 IST = Dec 1, 2025 18:30:00 UTC
      final serverTodayStartUTC = DateTime.utc(istYear, istMonth, istDay).subtract(istOffset);
      final serverTodayEndUTC = serverTodayStartUTC.add(Duration(days: 1));
      
      // Determine "this month" in IST
      // Month starts at 00:00:00 IST on the 1st of the month
      final serverMonthStartUTC = DateTime.utc(istYear, istMonth, 1).subtract(istOffset);
      final serverNextMonthStartUTC = DateTime.utc(istYear, istMonth + 1, 1).subtract(istOffset);
      
      final monthStart = serverMonthStartUTC;
      final nextMonthStart = serverNextMonthStartUTC;

      // Parse all surveys to count today/month totals
      List<FieldSurvey> allSurveys = [];
      if (allSurveysData != null) {
        final response = FieldSurveyListResponse.fromResponse(allSurveysData);
        allSurveys = response.surveys;
      }

      // Count from USER'S surveys only (to match API response from addSurvey)
      // The API's addSurvey endpoint returns user-specific stats (surveysToday, surveysThisMonth)
      // So we should count only the current user's surveys to match
      final userSurveysForCount = allSurveys.where((survey) => survey.userId == userId).toList();
      
      // Use server's UTC date boundaries to match server's database queries
      int todayCount = _countSurveysBetweenUTC(userSurveysForCount, serverTodayStartUTC, serverTodayEndUTC);
      int monthCount = _countSurveysBetweenUTC(userSurveysForCount, serverMonthStartUTC, serverNextMonthStartUTC);
      
      // Debug: Print detailed date info for verification
      print("DEBUG: Current local time: ${DateTime.now().toString()}");
      print("DEBUG: Current UTC time: ${nowUTC.toString()}");
      print("DEBUG: Current IST time: ${nowIST.toString()} (year=${nowIST.year}, month=${nowIST.month}, day=${nowIST.day})");
      print("DEBUG: Today in IST: ${istYear}-${istMonth.toString().padLeft(2, '0')}-${istDay.toString().padLeft(2, '0')}");
      print("DEBUG: Server today start (UTC): ${serverTodayStartUTC.toString()}");
      print("DEBUG: Server today end (UTC): ${serverTodayEndUTC.toString()}");
      print("DEBUG: Server month start (UTC): ${serverMonthStartUTC.toString()}");
      print("DEBUG: Server month end (UTC): ${serverNextMonthStartUTC.toString()}");
      print("DEBUG: Counts - Today: $todayCount, Month: $monthCount from ${userSurveysForCount.length} user surveys (${allSurveys.length} total surveys)");
      
      // Debug: Print first few survey dates to verify timezone conversion
      if (allSurveys.isNotEmpty) {
        print("DEBUG: Sample survey dates (first 5):");
        for (int i = 0; i < allSurveys.length && i < 5; i++) {
          final survey = allSurveys[i];
          if (survey.createdAt != null) {
            final utc = survey.createdAt!.toUtc();
            final isInToday = utc.isAfter(serverTodayStartUTC) && utc.isBefore(serverTodayEndUTC);
            final isInMonth = utc.isAfter(serverMonthStartUTC) && utc.isBefore(serverNextMonthStartUTC);
            print("  Survey ${survey.id}: UTC=${utc.toString()}, InToday=$isInToday, InMonth=$isInMonth");
          }
        }
      }

      // Summary API returns data directly (not nested in 'stats')
      // It includes: totalResponses, ratings, heardFrom, likedFeaturesCount, topPayoutUsers
      // Payout per survey is 0.30 (hardcoded in server, not in API response)
      final payoutPerSurvey = _defaultPayoutPerSurvey;
      
      // Use user's month count for payout calculation (user-specific payout)
      final userMonthCount = _countSurveysBetweenUTC(userSurveys, monthStart, nextMonthStart);
      final payoutValue = userMonthCount * payoutPerSurvey;

      setState(() {
        _todayCount = todayCount;
        _monthCount = monthCount;
        _estimatedPayout = _formatCurrency(payoutValue);
        _userSurveys = userSurveys;
        _isLoading = false;
        _isLoadingStats = false;
      });
    } catch (e) {
      print("Error loading survey stats: $e");
      setState(() {
        _isLoading = false;
        _isLoadingStats = false;
      });
    }
  }

  Future<List<FieldSurvey>> _fetchAllSurveysForUser(
    int userId, {
    String? employeCode,
    String? phoneNumber,
  }) async {
    // The API returns ALL surveys in a single response, so we only need ONE request
    // No pagination needed - just fetch once and filter client-side
    try {
      final responseData = await _apiService.getFieldSurveys(
        page: 1,
        limit: 1000, // Request a large limit to get all surveys
        userId: userId,
        employeCode: employeCode,
      );

      if (responseData == null) {
        return [];
      }

      final response = FieldSurveyListResponse.fromResponse(responseData);
      final allSurveys = response.surveys;
      
      if (allSurveys.isEmpty) {
        return [];
      }

      final normalizedPhone = phoneNumber?.trim();

      // Filter surveys for this user
      final filteredSurveys = allSurveys.where((survey) {
        final surveyUserId = survey.userId;
        if (surveyUserId != null && surveyUserId == userId) return true;

        if (normalizedPhone != null &&
            normalizedPhone.isNotEmpty &&
            survey.contactNumber?.trim() == normalizedPhone) {
          return true;
        }

        return false;
      }).toList();

      return filteredSurveys;
    } catch (e) {
      print("Error fetching surveys: $e");
      return [];
    }
  }


  /// Count surveys between dates using UTC comparison (more reliable for API dates)
  int _countSurveysBetweenUTC(
    List<FieldSurvey> surveys,
    DateTime startUTC,
    DateTime endUTC,
  ) {
    return surveys.where((survey) {
      final createdAt = survey.createdAt;
      if (createdAt == null) return false;
      
      // API dates come as UTC strings like "2025-12-02T14:14:09.000Z"
      // DateTime.parse() creates a UTC DateTime when 'Z' is present
      // Ensure we're working with UTC
      final createdAtUTC = createdAt.isUtc 
          ? createdAt 
          : DateTime.utc(
              createdAt.year, 
              createdAt.month, 
              createdAt.day,
              createdAt.hour, 
              createdAt.minute, 
              createdAt.second,
              createdAt.millisecond,
              createdAt.microsecond,
            );
      
      // Compare: createdAt >= start AND createdAt < end
      // Use isAtSameMomentAs or isAfter for start, and isBefore for end
      final isAfterStart = createdAtUTC.isAtSameMomentAs(startUTC) || createdAtUTC.isAfter(startUTC);
      final isBeforeEnd = createdAtUTC.isBefore(endUTC);
      
      return isAfterStart && isBeforeEnd;
    }).length;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _formatCurrency(num value) {
    final formatter = NumberFormat.currency(symbol: '₹ ', decimalDigits: 2);
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        // Theme: Blue AppBar
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          "Survey Completed",
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 20),
            _roundedBox(
              Column(
                children: [
                  // Theme: Teal Icon
                  Icon(
                    Icons.check_circle,
                    size: 60,
                    color: theme.colorScheme.secondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Survey Completed",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Thank you for your feedback",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              // Theme: Light Teal background
              color: theme.colorScheme.secondary.withOpacity(0.1),
            ),
            SizedBox(height: 16),
            _roundedBox(
              Column(
                children: [
                  Row(
                    children: [
                      // Theme: Primary Blue icon
                      Icon(
                        Icons.insert_chart,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Survey Stats",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _isLoading
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.secondary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _statColumn(_todayCount.toString(), "Today", theme),
                            _statColumn(
                              _monthCount.toString(),
                              "This Month",
                              theme,
                            ),
                            _statColumn(_estimatedPayout, "Est. Payout", theme),
                          ],
                        ),
                  SizedBox(height: 12),
                  GestureDetector(
                    onTap: _userSurveys.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SurveyResponsesPage(),
                              ),
                            );
                          },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Center(
                        child: Text(
                          "View Past Responses ($_monthCount)",
                          style: TextStyle(
                            color: _userSurveys.isEmpty
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => FieldSurveyPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  // Theme: Teal primary button
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text("Take Another Survey"),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final employeeName = _profileData?['name'] ?? "User";
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardPage(
                        employeeName: employeeName,
                        employeeCount: _monthCount,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  // Theme: Blue outlined button
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Back to Home",
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String number, String label, ThemeData theme) {
    return Column(
      children: [
        Text(
          number,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.colorScheme.primary, // Theme: Blue numbers
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _roundedBox(Widget child, {Color? color}) {
    return Card(
      // Theme: Use Card for consistent shadow/rounding
      color: color ?? Colors.white,
      child: Padding(padding: EdgeInsets.all(16), child: child),
    );
  }
}
