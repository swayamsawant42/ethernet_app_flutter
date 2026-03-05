import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_page.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _api = ApiService();
  bool _loading = false;
  bool _obscurePassword = true;

  void _login() async {
    // Check if the widget is still mounted before setting state
    if (!mounted) return;
    setState(() => _loading = true);

    // Step 1: Authenticate and get token
    bool success = await _api.login(
      _identifierController.text, // ← This will be employeCode
      _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login failed. Please check credentials."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Step 2: Token is now stored, fetch profile using the authenticated token
    // Keep loading state active while fetching profile
    final profile = await _api.getProfile();

    if (!mounted) return;
    setState(() => _loading = false);

    // Step 3: Verify profile was fetched successfully before navigation
    if (profile == null || profile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load user profile. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
      // Clear token if profile fetch failed
      await _api.logout();
      return;
    }

    // Step 4: Extract user information from profile
    final String employeeName = profile['name'] ?? _identifierController.text;
    final List<dynamic>? modules = profile['Modules'] as List<dynamic>?;

    print("Profile loaded successfully. Modules: $modules");

    // Step 5: Navigate to DashboardPage only after profile is verified
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          employeeName: employeeName,
          employeeCount: 9, // can replace with actual count from API
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data for easy access
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Background color is now set automatically by the theme
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Logo ---
                Image.asset('assets/EXPL-Logo.png', width: 250),
                const SizedBox(height: 32),

                // --- Login Form Card ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Welcome Back 👋",
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign in to continue",
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // --- Identifier Field (Email or Employee Code) ---
                        TextField(
                          controller: _identifierController,
                          decoration: const InputDecoration(
                            labelText: "Email or Employee Code",
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 16),

                        // --- Password Field ---
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 32),

                        // --- Login Button ---
                        _loading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: colorScheme.secondary,
                                ),
                              )
                            : SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  child: const Text("Login"),
                                ),
                              ),

                        // --- Link to Sign Up ---
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text("Don't have an account? Sign Up"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
