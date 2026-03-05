import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../services/api_service.dart';
import 'expense_list_page.dart';

class ExpenseTrackerPage extends StatefulWidget {
  const ExpenseTrackerPage({super.key});

  @override
  _ExpenseTrackerPageState createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  String? selectedCategory;
  TextEditingController amountController = TextEditingController();
  TextEditingController distanceController = TextEditingController();
  List<XFile> uploadedImages = [];
  double totalSizeMB = 0.0;
  final double maxSizeMB = 10.0;
  static const int _maxBase64Chars = 64000;
  static const int _desiredQuality = 50; // Reduced from 60 to 50 for better compression
  static const int _maxImageDimension = 800; // Reduced from 1280 to 800 for smaller file size
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;

  bool get isFormValid =>
      selectedCategory != null &&
      selectedCategory != 'N/A' &&
      amountController.text.isNotEmpty &&
      uploadedImages.isNotEmpty;

  Future<XFile?> _compressAndValidateImage(XFile source) async {
    try {
      final originalFile = File(source.path);
      if (!await originalFile.exists()) {
        return null;
      }

      // Progressive compression: try multiple quality levels until we get a small enough file
      List<int>? compressedBytes;
      int quality = _desiredQuality;
      int dimension = _maxImageDimension;

      // Try compression with decreasing quality and dimensions
      for (int attempt = 0; attempt < 4; attempt++) {
        compressedBytes = await FlutterImageCompress.compressWithFile(
          source.path,
          quality: quality,
          minWidth: dimension,
          minHeight: dimension,
          format: CompressFormat.jpeg,
          keepExif: false, // Remove EXIF data to reduce size
        );

        if (compressedBytes == null) {
          return null;
        }

        // If file is small enough (under 400KB), use it
        if (compressedBytes.length < 400000) {
          break;
        }

        // If still too large, try more aggressive compression
        if (attempt == 0) {
          quality = 40;
          dimension = 600;
        } else if (attempt == 1) {
          quality = 30;
          dimension = 500;
        } else if (attempt == 2) {
          quality = 25;
          dimension = 400;
        }
      }

      if (compressedBytes == null || compressedBytes.isEmpty) {
        return null;
      }

      // Check if it fits the database limit
      if (!_fitsDbLimit(compressedBytes.length)) {
        return null;
      }

      final targetPath =
          '${source.path}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = await File(targetPath).writeAsBytes(
        compressedBytes,
        flush: true,
      );
      return XFile(file.path);
    } catch (e) {
      debugPrint('Image compression failed: $e');
      return null;
    }
  }

  bool _fitsDbLimit(int byteLength) {
    final base64Length = ((byteLength + 2) ~/ 3) * 4;
    return base64Length <= _maxBase64Chars;
  }

  Future<void> pickImage() async {
    if (uploadedImages.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only upload a maximum of 2 images.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final XFile? rawImage = await _picker.pickImage(source: ImageSource.gallery);
    if (rawImage == null) return;

    final XFile? optimized = await _compressAndValidateImage(rawImage);

    if (optimized == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image is too large even after compression. Please choose a smaller image.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fileSizeMB = await File(optimized.path).length() / (1024 * 1024);

    if (totalSizeMB + fileSizeMB > maxSizeMB) {
      try {
        await File(optimized.path).delete();
      } catch (_) {
        // Ignore delete errors
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total image size cannot exceed 10MB.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      uploadedImages.add(optimized);
      totalSizeMB += fileSizeMB;
    });
  }

  String getCurrentTime() {
    return DateFormat('hh:mm a').format(DateTime.now());
  }

  Future<void> _submitExpense() async {
    if (!isFormValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get user profile for employee code and name
      final profile = await _apiService.getProfile();
      final String employeCode = profile?['employeCode'] ?? 'UNKNOWN';
      final String name = profile?['name'] ?? 'Unknown User';

      // Prepare image paths
      final List<String> imagePaths = uploadedImages
          .map((img) => img.path)
          .toList();

      print("=== EXPENSE SUBMISSION START ===");
      print("Employee Code: $employeCode");
      print("Name: $name");
      print("Category: ${selectedCategory!}");
      print("Amount: ${amountController.text}");
      print(
        "Distance: ${distanceController.text.isNotEmpty ? distanceController.text : '0'}",
      );
      print("Images: ${imagePaths.length} files");
      print("Image paths: $imagePaths");

      // Submit expense
      await _apiService.submitExpense(
        employeCode: employeCode,
        name: name,
        category: selectedCategory!,
        amount: amountController.text,
        distanceTravelled: distanceController.text.isNotEmpty
            ? distanceController.text
            : '0',
        imagePaths: imagePaths,
      );

      print("=== EXPENSE SUBMISSION RESULT ===");
      print("Success: true");

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        selectedCategory = null;
        amountController.clear();
        distanceController.clear();
        uploadedImages.clear();
        totalSizeMB = 0.0;
      });

      // Wait a moment for server to process the new expense
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Navigate to Expense List Page to show all expenses including the newly submitted one
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ExpenseListPage()),
      );
    } on ExpenseSubmissionException catch (e) {
      print('ExpenseSubmissionException: ${e.message}');
      if (e.statusCode != null) {
        print('Status code: ${e.statusCode}');
      }
      if (e.details != null) {
        print('Error details: ${e.details}');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print('Error submitting expense: $e');
      print('Error type: ${e.runtimeType}');
      if (!mounted) return;

      String errorMessage = 'Failed to submit expense. ';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Network')) {
        errorMessage += 'Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Request timed out. Please try again.';
      } else {
        errorMessage += 'Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
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

  @override
  void dispose() {
    amountController.dispose();
    distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // AppBar now uses the theme automatically
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View Submitted Expenses',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseListPage()),
              );
            },
          ),
        ],
      ),
      // Background color is set by the theme
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // --- Expense Details Box ---
              Card(
                // All styling comes from cardTheme in main.dart
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expense Details', style: textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Submit your bill for reimbursement',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),

                      // Category Label
                      Text('Category *', style: textTheme.titleSmall),
                      const SizedBox(height: 8),
                      // Category Drop-down
                      DropdownButtonFormField<String>(
                        // Decoration now comes from inputDecorationTheme
                        decoration: const InputDecoration(
                          hintText: 'Select expense category',
                        ),
                        // Dropdown-specific styling - explicitly white
                        dropdownColor: Colors.white,
                        initialValue: selectedCategory,
                        items:
                            ['N/A', 'Food', 'Travel', 'Accommodation', 'Other']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e, style: textTheme.bodyLarge),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedCategory = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Amount Label
                      Text('Amount (₹) *', style: textTheme.titleSmall),
                      const SizedBox(height: 8),
                      // Amount TextField
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        // Decoration now comes from inputDecorationTheme
                        decoration: const InputDecoration(
                          hintText: 'Enter bill amount',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),

                      // Distance Label
                      Text(
                        'Distance Travelled (km)',
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      // Distance TextField
                      TextFormField(
                        controller: distanceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter distance in km (optional)',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // --- Blue Summary Box ---
              if (isFormValid)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    // Use brand primary color
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category, color: colorScheme.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            selectedCategory ?? '',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Today's travel: ${distanceController.text.isNotEmpty ? distanceController.text : '0.0'} km",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Current time: ${getCurrentTime()}",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // --- Bill Images Box ---
              Card(
                // Styling from cardTheme
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bill Images', style: textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(
                              'Upload up to 2 images (max 10MB total)',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Branded Upload Button ---
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            // Use theme background and secondary color
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.secondary,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file_rounded,
                                size: 40,
                                color: colorScheme.secondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Upload Bill Image",
                                style: textTheme.titleSmall?.copyWith(
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // --- Uploaded Images List ---
                      if (uploadedImages.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Uploaded Images',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: uploadedImages.map((img) {
                            final file = File(img.path);
                            double sizeMB =
                                file.existsSync() ? file.lengthSync() / (1024 * 1024) : 0;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        img.name,
                                        style: textTheme.bodyLarge,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        '${sizeMB.toStringAsFixed(2)} MB',
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      totalSizeMB -= sizeMB;
                                      uploadedImages.remove(img);
                                    });
                                    if (file.existsSync()) {
                                      try {
                                        file.delete();
                                      } catch (_) {
                                        // Ignore delete errors
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${totalSizeMB.toStringAsFixed(2)}MB / $maxSizeMB MB',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Bottom Buttons ---
              Row(
                children: [
                  Expanded(
                    // Secondary action: OutlinedButton
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        // Style comes from theme
                        onPressed: isFormValid
                            ? () {
                                // Save offline logic
                              }
                            : null,
                        child: const Text('Save Offline'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    // Primary action: ElevatedButton
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        // Style comes from elevatedButtonTheme
                        onPressed: isFormValid && !_isSubmitting
                            ? _submitExpense
                            : null,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Submit'),
                      ),
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
