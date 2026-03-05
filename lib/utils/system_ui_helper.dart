import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:async';

/// Helper class to manage Android system navigation bar visibility
class SystemUIHelper {
  static bool _isNavigationBarVisible = false;

  /// Hide the system navigation bar (Android only)
  static void hideNavigationBar() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    
    _isNavigationBarVisible = false;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top], // Only show status bar, hide navigation bar
    );
  }

  /// Show the system navigation bar (Android only)
  static void showNavigationBar() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    
    _isNavigationBarVisible = true;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom], // Show both status and navigation bars
    );
  }

  /// Check if navigation bar is currently visible
  static bool get isNavigationBarVisible => _isNavigationBarVisible;
}

/// Global widget that manages system navigation bar for the entire app
/// Automatically hides navigation bar and allows tap gesture to reveal it
class GlobalSystemUIManager extends StatefulWidget {
  final Widget child;

  const GlobalSystemUIManager({
    super.key,
    required this.child,
  });

  @override
  State<GlobalSystemUIManager> createState() => _GlobalSystemUIManagerState();
}

class _GlobalSystemUIManagerState extends State<GlobalSystemUIManager> {
  Timer? _autoHideTimer;
  DateTime? _lastTapTime;
  double? _cachedScreenHeight;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            SystemUIHelper.hideNavigationBar();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _cancelAutoHideTimer();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SystemUIHelper.showNavigationBar();
    }
    super.dispose();
  }

  void _cancelAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  void _startAutoHideTimer() {
    _cancelAutoHideTimer();
    // Reduced to 2 seconds for faster hiding
    _autoHideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && SystemUIHelper.isNavigationBarVisible) {
        SystemUIHelper.hideNavigationBar();
      }
    });
  }

  double _getScreenHeight() {
    if (_cachedScreenHeight != null) return _cachedScreenHeight!;
    
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        _cachedScreenHeight = box.size.height;
        return _cachedScreenHeight!;
      }
    } catch (e) {
      // Fallback to MediaQuery if RenderBox fails
    }
    
    // Fallback to MediaQuery
    final mediaQuery = MediaQuery.of(context);
    _cachedScreenHeight = mediaQuery.size.height;
    return _cachedScreenHeight!;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!mounted || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    
    // If navigation bar is visible, reset the auto-hide timer
    if (SystemUIHelper.isNavigationBarVisible) {
      _startAutoHideTimer();
      return;
    }

    // Get screen height
    final screenHeight = _getScreenHeight();
    final tapY = event.position.dy;
    
    // Check if tap is in the bottom 15% of the screen
    final bottomThreshold = screenHeight * 0.85;
    
    if (tapY > bottomThreshold) {
      // Reduced debounce to 200ms for more responsive taps
      final now = DateTime.now();
      if (_lastTapTime == null || now.difference(_lastTapTime!).inMilliseconds > 200) {
        _lastTapTime = now;
        SystemUIHelper.showNavigationBar();
        _startAutoHideTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return widget.child;
    }
    
    // Cache screen height when build is called
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getScreenHeight();
    });
    
    return Listener(
      onPointerDown: _handlePointerDown,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
