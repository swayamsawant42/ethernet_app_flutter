import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'screens/login_screen.dart';
import 'utils/navigation_service.dart';
import 'utils/system_ui_helper.dart';

// --- ETHERNETXPRESS BRAND COLORS ---
const Color exPrimaryBlue = Color(0xFF1E407A);
const Color exPrimaryTeal = Color(0xFF30A8B5);
const Color exAccentTeal = Color(0xFF5DC8C6);

// --- SEMANTIC COLORS ---
const Color exLightBackground = Color(0xFFF7F9FA);
const Color exWhite = Color(0xFFFFFFFF);
const Color exDarkText = Color(0xFF2E2E2E);
const Color exLightText = Color(0xFF6C6C6C);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize system UI mode - hide navigation bar globally (Android only)
  // Skip on web platform
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      // This will only work on Android
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top], // Only show status bar, hide navigation bar
      );
    } catch (e) {
      // Ignore errors on platforms that don't support this
      if (kDebugMode) {
        print('SystemChrome not available on this platform: $e');
      }
    }
  }
  
  runApp(const EthernetXpressApp());
}

class EthernetXpressApp extends StatelessWidget {
  const EthernetXpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    NavigationService.registerLoginBuilder((_) => const LoginScreen());
    return GlobalSystemUIManager(
      child: MaterialApp(
        title: 'EthernetXpress',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        navigatorKey: NavigationService.navigatorKey,
        home: LoginScreen(),
      ),
    );
  }
}

// --- ETHERNETXPRESS APP THEME ---

ThemeData buildAppTheme() {
  // Start with light theme (Material 2 by default)
  final ThemeData base = ThemeData.light();

  return base.copyWith(
    // Explicitly set canvas and scaffold colors to white
    canvasColor: exWhite,
    scaffoldBackgroundColor: exWhite,
    
    // Use explicit color scheme to avoid purple colors
    colorScheme: const ColorScheme(
      primary: exPrimaryBlue,
      secondary: exPrimaryTeal,
      tertiary: exAccentTeal,
      error: Colors.red,
      surface: exWhite,
      background: exWhite, // Changed from exLightBackground to exWhite
      onPrimary: exWhite,
      onSecondary: exWhite,
      onTertiary: exWhite,
      onError: Colors.white,
      onSurface: exDarkText,
      onBackground: exDarkText,
      brightness: Brightness.light,
    ),

    // --- Customize Specific Widgets ---

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: exPrimaryBlue,
      foregroundColor: exWhite, // Title and icon color
      elevation: 2,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: exWhite,
      ),
    ),

    // ElevatedButton Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: exPrimaryTeal, // Use the accent teal
        foregroundColor: exWhite, // Text color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // Text Theme (for body, headlines, etc.)
    textTheme: base.textTheme
        .copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(
            color: exDarkText,
          ),
          displayMedium: base.textTheme.displayMedium?.copyWith(
            color: exDarkText,
          ),
          displaySmall: base.textTheme.displaySmall?.copyWith(
            color: exDarkText,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            color: exDarkText,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            color: exDarkText,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(color: exDarkText),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            color: exDarkText,
            fontSize: 16,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            color: exLightText,
            fontSize: 14,
          ),
        )
        .apply(
          fontFamily: 'Roboto', // You can change this to your desired font
        ),

    // Card Theme
    cardTheme: CardThemeData(
      // <-- FIX 2: Added 'Data'
      color: exWhite,
      surfaceTintColor: Colors.transparent, // Remove any tint
      elevation: 1,
      shadowColor: exPrimaryBlue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),

    // Input Decoration Theme (for TextFields)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: exWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: exLightText.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: exLightText.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: exPrimaryBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: exLightText),
    ),

    // Dropdown Menu Theme (for DropdownMenu widgets)
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(exWhite),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent), // Remove any tint
        elevation: WidgetStateProperty.all(4),
      ),
    ),

    // Menu Theme (for dropdowns and popup menus)
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(exWhite),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent), // Remove any tint
        elevation: WidgetStateProperty.all(4),
      ),
    ),

    // Popup Menu Theme
    popupMenuTheme: PopupMenuThemeData(
      color: exWhite,
      surfaceTintColor: Colors.transparent, // Remove any tint
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: exWhite,
      surfaceTintColor: Colors.transparent, // Remove any tint
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: exWhite,
      surfaceTintColor: Colors.transparent, // Remove any tint
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
    ),
  );
}
