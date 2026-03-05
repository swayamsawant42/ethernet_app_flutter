import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();

  // Profile info
  String name = '';
  String employeCode = '';
  String lastLogin = '';
  String status = '';

  // Password fields
  final TextEditingController _currentPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  final FocusNode _newPasswordFocus = FocusNode();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Validation states
  bool hasLowercase = false;
  bool hasUppercase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;
  bool passwordsMatch = false;

  bool _isSaving = false;
  bool _isLoggingOut = false;

  // App Info
  String version = '';
  String lastUpdated = '';
  String platform = '';

  bool _showRules = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAppInfo();

    _newPassword.addListener(_checkPasswordRules);
    _confirmPassword.addListener(_checkPasswordMatch);

    _newPasswordFocus.addListener(() {
      setState(() {
        _showRules = _newPasswordFocus.hasFocus || _newPassword.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _newPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getProfile();
      if (profile != null && mounted) {
        setState(() {
          name = profile['name']?.toString() ?? 'Unknown User';
          employeCode = profile['employeCode']?.toString() ?? 'Unknown Code';
          lastLogin = profile['lastLogin']?.toString() ?? '';
          status = profile['status']?.toString() ?? 'Active';
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
      if (mounted) {
        setState(() {
          name = 'Error loading profile';
          employeCode = 'N/A';
          lastLogin = '';
          status = 'Unknown';
        });
      }
    }
  }

  Future<void> _loadAppInfo() async {
    var info = await _apiService.getAppInfo();

    // Ensure info is a Map<String, dynamic>
    final Map<String, dynamic> safeInfo = info ?? {};

    setState(() {
      version = safeInfo['version']?.toString() ?? '1.0.0';
      lastUpdated = safeInfo['lastUpdated']?.toString() ?? 'Oct 6, 2025';
      platform = safeInfo['platform']?.toString() ?? 'Mobile Web';
    });
  }

  void _checkPasswordRules() {
    String pw = _newPassword.text;

    setState(() {
      hasLowercase = pw.contains(RegExp(r'[a-z]'));
      hasUppercase = pw.contains(RegExp(r'[A-Z]'));
      hasNumber = pw.contains(RegExp(r'\d'));
      hasSpecialChar = pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      hasMinLength = pw.length >= 8;
      _showRules = pw.isNotEmpty; // Show rules when user starts typing
    });

    _checkPasswordMatch();
  }

  void _checkPasswordMatch() {
    setState(() {
      passwordsMatch =
          _newPassword.text == _confirmPassword.text &&
          _newPassword.text.isNotEmpty &&
          _confirmPassword.text.isNotEmpty;
    });
  }

  Future<void> _changePassword() async {
    if (!_allRulesPassed()) {
      print("Password rules not met");
      return;
    }

    setState(() => _isSaving = true);

    try {
      print("Attempting to change password...");
      final result = await _apiService.changePassword(
        _currentPassword.text,
        _newPassword.text,
      );

      setState(() => _isSaving = false);

      final success = result['success'] == true;
      final message = result['message'] ?? '';

      print("Password change result: $success - $message");

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : "Password updated successfully"),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        _currentPassword.clear();
        _newPassword.clear();
        _confirmPassword.clear();

        // Logout via API and clear token, then navigate back to login
        await _apiService.logout();
        print("Logout completed, navigating to login...");

        // Wait a moment for snackbar to show, then navigate
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to login page - removes all previous routes
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/', // Root route (login page)
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isNotEmpty ? message : "Password update failed. Please check your current password.",
            ),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      print("Error changing password: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred. Please try again."),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _apiService.logout();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logged out successfully"),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );

      await Future.delayed(Duration(milliseconds: 400));

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      print("Logout error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to logout. Please try again."),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  bool _allRulesPassed() {
    return hasLowercase &&
        hasUppercase &&
        hasNumber &&
        hasSpecialChar &&
        hasMinLength &&
        passwordsMatch;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Account Information Card
            _buildRoundedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Account Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Your current account details",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 20),
                  _buildInfoRow("Employee Code", employeCode),
                  SizedBox(height: 12),
                  _buildInfoRow("Last Login", _formatDate(lastLogin)),
                  SizedBox(height: 12),
                  _buildStatusRow("Status", status),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Change Password Card
            _buildRoundedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Change Password",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Update your account password",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 20),
                  _buildPasswordField(
                    "Current Password",
                    _currentPassword,
                    _obscureCurrent,
                    () => setState(() => _obscureCurrent = !_obscureCurrent),
                    "Enter current password",
                  ),
                  SizedBox(height: 16),
                  _buildPasswordField(
                    "New Password",
                    _newPassword,
                    _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew),
                    "Enter new password",
                    focusNode: _newPasswordFocus,
                  ),

                  // Password Strength Bar and Rules - Always visible when typing
                  if (_showRules) ...[
                    SizedBox(height: 16),
                    _buildPasswordStrengthBar(),
                    SizedBox(height: 12),
                    _buildPasswordRulesList(),
                  ],

                  SizedBox(height: 16),
                  _buildPasswordField(
                    "Confirm New Password",
                    _confirmPassword,
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                    "Confirm new password",
                  ),

                  // Password Match Indicator
                  if (passwordsMatch && _confirmPassword.text.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Passwords match",
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (!passwordsMatch && _confirmPassword.text.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Passwords do not match",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 20),
                  _buildInfoBox(
                    Icons.info_outline,
                    "For security reasons, you will be logged out after changing your password and will need to sign in again.",
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _allRulesPassed() && !_isSaving
                          ? _changePassword
                          : null,
                      // Style comes from elevatedButtonTheme in main.dart
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: colorScheme.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Change Password",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // App Information Card
            _buildRoundedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "App Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow("Version", version),
                  SizedBox(height: 8),
                  _buildInfoRow("Last Updated", lastUpdated),
                  SizedBox(height: 8),
                  _buildInfoRow("Platform", platform),
                ],
              ),
            ),
            SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoggingOut ? null : _handleLogout,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoggingOut
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      )
                    : Text(
                        "Log Out",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundedCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Colors.white,
      child: Padding(padding: EdgeInsets.all(20), child: child),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value) {
    Color dotColor = value.toLowerCase() == "active"
        ? Colors.green
        : Colors.red;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle,
    String hint, {
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: toggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthBar() {
    int passed = [
      hasMinLength,
      hasLowercase,
      hasUppercase,
      hasNumber,
      hasSpecialChar,
    ].where((e) => e).length;
    double strength = passed / 5;
    Color color;
    String label;

    if (passed <= 2) {
      color = Colors.red;
      label = "Weak";
    } else if (passed <= 4) {
      color = Colors.orange;
      label = "Moderate";
    } else {
      color = Colors.green;
      label = "Strong";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Password Strength",
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: strength,
            color: color,
            backgroundColor: Colors.grey[300],
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRulesList() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ruleWidget("8+ characters", hasMinLength),
              SizedBox(height: 6),
              _ruleWidget("Lowercase", hasLowercase),
              SizedBox(height: 6),
              _ruleWidget("Special char", hasSpecialChar),
            ],
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ruleWidget("Uppercase", hasUppercase),
              SizedBox(height: 6),
              _ruleWidget("Number", hasNumber),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ruleWidget(String label, bool passed) {
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.cancel,
          color: passed ? Colors.green : Colors.red,
          size: 16,
        ),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: passed ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Today, 9:30 AM';
    try {
      DateTime dt = DateTime.parse(dateStr);
      DateTime now = DateTime.now();

      // Check if it's today
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Today, ${DateFormat('h:mm a').format(dt)}';
      }

      // Check if it's yesterday
      final yesterday = now.subtract(Duration(days: 1));
      if (dt.year == yesterday.year &&
          dt.month == yesterday.month &&
          dt.day == yesterday.day) {
        return 'Yesterday, ${DateFormat('h:mm a').format(dt)}';
      }

      return DateFormat('MMM d, yyyy – h:mm a').format(dt);
    } catch (_) {
      // If parsing fails, try to return the original string or a default
      return dateStr.isNotEmpty ? dateStr : 'Never';
    }
  }
}
