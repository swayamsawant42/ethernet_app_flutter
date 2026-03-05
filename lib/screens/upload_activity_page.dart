import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class UploadActivityPage extends StatefulWidget {
  const UploadActivityPage({super.key});

  @override
  _UploadActivityPageState createState() => _UploadActivityPageState();
}

class _UploadActivityPageState extends State<UploadActivityPage> {
  String? selectedBusinessUnit;
  String? selectedActivityType;
  String? remarks;
  File? _image;
  String? location;
  String? latitude;
  String? longitude;
  String? dateTime;
  bool isFormComplete = false;

  final picker = ImagePicker();
  final _remarksController = TextEditingController();

  // --- NO LOGIC CHANGES ---
  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      if (!mounted) return;
      setState(() {
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
        location =
            "${place.locality}, ${place.administrativeArea}, ${place.country}";
        dateTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        location = "Location unavailable";
        latitude = "-";
        longitude = "-";
        dateTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
      });
    }
    _checkFormCompletion(); // Check completion after location is fetched
  }

  Future<void> _capturePhoto() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _checkFormCompletion();
    }
  }

  void _checkFormCompletion() {
    setState(() {
      isFormComplete =
          selectedBusinessUnit != null &&
          selectedActivityType != null &&
          _image != null &&
          latitude != null &&
          longitude != null &&
          latitude != "-"; // Added check for valid location
    });
  }
  // --- END OF LOGIC ---

  @override
  Widget build(BuildContext context) {
    // --- Get theme data ---
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    // ---

    return Scaffold(
      // backgroundColor removed, handled by theme
      appBar: AppBar(
        // All styling (background, icon color, title text)
        // is now handled by the appBarTheme in main.dart
        title: Text("Upload Activity"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailsBox(textTheme),
            SizedBox(height: 16),
            _mediaBox(textTheme, colorScheme),
            SizedBox(height: 16),
            _autoCaptureBox(textTheme, colorScheme),
            SizedBox(height: 80), // Padding for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(colorScheme),
    );
  }

  /// Details Section
  /// Replaced custom _roundedBox with Card
  /// Replaced custom _dropdownField with DropdownButtonFormField
  Widget _detailsBox(TextTheme textTheme) {
    return Card(
      // Style (color, elevation, shape) comes from cardTheme
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Details",
              style: textTheme.titleLarge, // Use theme text style
            ),
            Text(
              "Activity information",
              style: textTheme.bodyMedium, // Use theme text style
            ),
            SizedBox(height: 16),
            // Use standard DropdownButtonFormField to get theme styling
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Business Unit *",
                hintText: "Select business unit",
              ),
              dropdownColor: Colors.white, // Explicitly white background
              initialValue: selectedBusinessUnit,
              items: [
                'N/A 1',
                'N/A 2',
                'N/A 3',
                'N/A 4',
                'N/A 5',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                setState(() => selectedBusinessUnit = val);
                _checkFormCompletion();
              },
            ),
            SizedBox(height: 12),
            // Use standard DropdownButtonFormField to get theme styling
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Activity Type *",
                hintText: "Select activity type",
              ),
              dropdownColor: Colors.white, // Explicitly white background
              initialValue: selectedActivityType,
              items: [
                'N/A 1',
                'N/A 2',
                'N/A 3',
                'N/A 4',
                'N/A 5',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                setState(() => selectedActivityType = val);
                _checkFormCompletion();
              },
            ),
            SizedBox(height: 12),
            // This TextField will be styled by inputDecorationTheme
            TextField(
              controller: _remarksController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: "Remarks",
                hintText: "Optional remarks (max 200 characters)",
              ),
              onChanged: (value) {
                remarks = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Media Section
  /// Replaced custom _roundedBox with Card
  /// Replaced grey box with themed "Upload" box
  Widget _mediaBox(TextTheme textTheme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Media",
              style: textTheme.titleLarge, // Use theme text style
            ),
            Text(
              "Capture activity photo",
              style: textTheme.bodyMedium, // Use theme text style
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: _capturePhoto,
              child: _image == null
                  // Themed upload box (similar to ExpenseTrackerPage)
                  ? Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.secondary, // Teal border
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: colorScheme.secondary, // Teal icon
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Capture Photo",
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.secondary, // Teal text
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Image preview with themed delete button
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _image!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _image = null;
                                _checkFormCompletion();
                              });
                            },
                            child: CircleAvatar(
                              // Use theme error colors
                              backgroundColor: colorScheme.error,
                              child: Icon(
                                Icons.close,
                                color: colorScheme.onError,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Auto-Capture Section
  /// Replaced custom _roundedBox with Card
  /// Mapped TextStyles to theme
  Widget _autoCaptureBox(TextTheme textTheme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-Captured
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 24,
                ), // Semantic color
                SizedBox(width: 8),
                Text(
                  "Auto-Captured",
                  style: textTheme.titleMedium, // Use theme text style
                ),
              ],
            ),
            SizedBox(height: 14),
            // Header
            Text(
              "Location and time information",
              style: textTheme.bodyMedium, // Use theme text style
            ),
            SizedBox(height: 14),

            // Actual Info
            if (location != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: colorScheme.onSurface,
                        size: 24,
                      ), // Themed icon
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$location",
                              style: textTheme.bodyLarge, // Themed text
                            ),
                            SizedBox(height: 8),
                            Text(
                              "$latitude",
                              style: textTheme.bodyMedium, // Themed text
                            ),
                            Text(
                              "$longitude",
                              style: textTheme.bodyMedium, // Themed text
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: colorScheme.onSurface,
                        size: 20,
                      ), // Themed icon
                      SizedBox(width: 12),
                      Text(
                        "$dateTime",
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ), // Themed text
                      ),
                    ],
                  ),
                ],
              )
            else
              Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ), // Themed spinner
          ],
        ),
      ),
    );
  }

  /// Bottom Buttons
  /// Replaced custom Container with BottomAppBar
  /// Buttons are now styled by the theme
  Widget _buildBottomBar(ColorScheme colorScheme) {
    return BottomAppBar(
      color: colorScheme.surface, // Use theme surface color
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50, // Match theme button height
              child: OutlinedButton(
                onPressed: isFormComplete ? () {} : null,
                // Style now comes from the OutlinedButtonTheme
                child: Text("Save Offline"),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50, // Match theme button height
              child: ElevatedButton(
                onPressed: isFormComplete ? () {} : null,
                // Style now comes from the elevatedButtonTheme
                child: Text("Save & Submit"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
