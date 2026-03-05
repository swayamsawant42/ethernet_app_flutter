import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:itechseed_crm_ethernetxpress/screens/field_survey_page.dart';
import '../services/api_service.dart';
import 'upload_activity_page.dart';
import 'expense_tracker.dart';
import 'travel_tracker_page.dart';
import 'new_subscription_page.dart';
import 'settings_page.dart';
import 'subscriber_page.dart';
import 'ticketing_page.dart'; // ← NEW
import '../widgets/location_permission_dialog.dart';
import '../services/location_service.dart';

class DashboardPage extends StatefulWidget {
  final String employeeName;
  final int employeeCount;

  const DashboardPage({
    super.key,
    required this.employeeName,
    required this.employeeCount,
  });

  @override
  // ignore: library_private_types_in_public_api
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String greeting = '';
  String currentTime = '';
  String currentDate = '';
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  bool _loadingProfile = true;
  String? _profileError;
  List<Map<String, dynamic>> _quickActions = [];
  final ScrollController _scrollController = ScrollController();
  bool _locationDialogShown = false;

  // --- BRAND COLORS ---
  final Color exPrimaryBlue = const Color(0xFF1E407A);
  final Color exPrimaryTeal = const Color(0xFF30A8B5);
  final Color exLightBackground = const Color(0xFFF7F9FA);
  final Color exDarkText = const Color(0xFF2E2E2E);
  final Color exLightText = const Color(0xFF6C6C6C);

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _fetchProfile();
    _initializeLocationUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showLocationDialogIfNeeded();
    });
  }

  void _initializeLocationUpdates() async {
    final hasPermission = await LocationService.hasLocationPermission();
    if (hasPermission) {
      await LocationService.startBackgroundLocationUpdates();
      Future.delayed(const Duration(minutes: 5), () {
        if (mounted) {
          LocationService.startBackgroundLocationUpdates();
          _initializeLocationUpdates();
        }
      });
    }
  }

  Future<void> _showLocationDialogIfNeeded() async {
    if (_locationDialogShown) return;
    final hasPermission = await LocationService.hasLocationPermission();
    if (hasPermission) {
      await LocationService.startBackgroundLocationUpdates();
      return;
    }
    if (!mounted) return;
    setState(() => _locationDialogShown = true);
    final granted = await LocationPermissionDialog.show(context);
    if (granted == true) {
      await LocationService.startBackgroundLocationUpdates();
      _initializeLocationUpdates();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final profile = await _apiService.getProfile();
      if (!mounted) return;
      setState(() {
        _profileData = profile;
        _quickActions = _buildActionsFromModules(profile);
        _loadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Failed to load profile. Please try again.';
        _loadingProfile = false;
      });
    }
  }

  void _updateDateTime() {
    if (!mounted) return;
    DateTime now = DateTime.now();
    int hour = now.hour;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    currentDate = DateFormat('dd/MM/yyyy').format(now);
    currentTime = DateFormat('hh:mm a').format(now);
    if (mounted) {
      setState(() {});
      Future.delayed(const Duration(minutes: 1), _updateDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: exLightBackground,
      appBar: AppBar(
        title: const Text('DASHBOARD', style: TextStyle(color: Colors.white)),
        backgroundColor: exPrimaryBlue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double screenHeight = constraints.maxHeight;
            double screenWidth = constraints.maxWidth;
            bool isPortrait = screenHeight > screenWidth;

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header
                    _buildHeaderSection(screenHeight, isPortrait, _profileData),
                    SizedBox(height: screenHeight * 0.02),

                    // 2. Activity Squares
                    _activitySquares(screenHeight, screenWidth, isPortrait),
                    SizedBox(height: screenHeight * 0.02),

                    // 3. Module Banners — Subscriber + Ticketing ← NEW
                    _buildModuleBanners(context, screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.02),

                    // 4. Quick Actions title
                    _buildQuickActionsHeader(screenHeight),
                    SizedBox(height: screenHeight * 0.01),

                    // 5. Actions Grid
                    _buildQuickActionsSection(
                      context,
                      screenHeight,
                      screenWidth,
                      isPortrait,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  NEW: Side-by-side module banners
  // ═══════════════════════════════════════════════════════════════

  Widget _buildModuleBanners(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Row(
      children: [
        Expanded(
          child: _ModuleBanner(
            icon: Icons.people,
            title: 'Subscribers',
            subtitle: 'View & manage',
            gradientColors: [exPrimaryBlue, const Color(0xFF2A5298)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriberPage()),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: _ModuleBanner(
            icon: Icons.support_agent,
            title: 'Support Tickets',
            subtitle: 'Cases & issues',
            gradientColors: [exPrimaryTeal, const Color(0xFF1A7A85)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TicketingPage()),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EXISTING HELPERS (unchanged)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeaderSection(
    double screenHeight,
    bool isPortrait,
    Map<String, dynamic>? profile,
  ) {
    final employeeName = profile?['name'] ?? widget.employeeName;
    final employeeCode = profile?['employeCode'];
    final roleName = profile?['Role']?['name'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: isPortrait ? screenHeight * 0.028 : screenHeight * 0.04,
            fontWeight: FontWeight.bold,
            color: exDarkText,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(
          employeeName,
          style: TextStyle(
            fontSize: isPortrait ? screenHeight * 0.02 : screenHeight * 0.03,
            color: exDarkText,
          ),
        ),
        if (employeeCode != null) ...[
          SizedBox(height: screenHeight * 0.005),
          Text(
            'ID: $employeeCode',
            style: TextStyle(
              fontSize: isPortrait
                  ? screenHeight * 0.018
                  : screenHeight * 0.026,
              color: exPrimaryTeal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (roleName != null) ...[
          SizedBox(height: screenHeight * 0.003),
          Text(
            roleName,
            style: TextStyle(
              fontSize: isPortrait
                  ? screenHeight * 0.016
                  : screenHeight * 0.024,
              color: exLightText,
            ),
          ),
        ],
        SizedBox(height: screenHeight * 0.005),
        Row(
          children: [
            Text(
              'Date: $currentDate',
              style: TextStyle(
                fontSize: isPortrait
                    ? screenHeight * 0.016
                    : screenHeight * 0.024,
                color: exLightText,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Time: $currentTime',
              style: TextStyle(
                fontSize: isPortrait
                    ? screenHeight * 0.016
                    : screenHeight * 0.024,
                color: exLightText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsHeader(double screenHeight) {
    return Text(
      'Quick Actions',
      style: TextStyle(
        fontSize: screenHeight * 0.022,
        fontWeight: FontWeight.bold,
        color: exDarkText,
      ),
    );
  }

  Widget _activitySquares(
    double screenHeight,
    double screenWidth,
    bool isPortrait,
  ) {
    final activities = [
      {
        'title': "Today's Activity",
        'value': '15',
        'icon': Icons.task_alt,
        'subtitle': 'Tasks completed',
      },
      {
        'title': 'KMs Tracked',
        'value': '24 km',
        'icon': Icons.directions_car,
        'subtitle': 'Distance traveled',
      },
      {
        'title': 'Pending Sync',
        'value': '3',
        'icon': Icons.sync,
        'subtitle': 'Activities pending',
      },
    ];
    return SizedBox(
      height: isPortrait ? screenHeight * 0.15 : screenHeight * 0.25,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: activities
            .map(
              (a) => Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: exPrimaryBlue.withValues(alpha: 0.1),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            a['icon'] as IconData,
                            size: isPortrait
                                ? screenHeight * 0.03
                                : screenHeight * 0.05,
                            color: exPrimaryTeal,
                          ),
                          SizedBox(height: screenHeight * 0.008),
                          Text(
                            a['value'] as String,
                            style: TextStyle(
                              fontSize: isPortrait
                                  ? screenHeight * 0.022
                                  : screenHeight * 0.035,
                              fontWeight: FontWeight.bold,
                              color: exPrimaryBlue,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.004),
                          Text(
                            a['subtitle'] as String,
                            style: TextStyle(
                              fontSize: isPortrait
                                  ? screenHeight * 0.012
                                  : screenHeight * 0.02,
                              color: exLightText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    double screenHeight,
    double screenWidth,
    bool isPortrait,
  ) {
    if (_loadingProfile) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.05),
          child: CircularProgressIndicator(color: exPrimaryTeal),
        ),
      );
    }
    if (_profileError != null) {
      return Column(
        children: [
          Text(_profileError!, style: const TextStyle(color: Colors.red)),
          SizedBox(height: screenHeight * 0.015),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: exPrimaryTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: _fetchProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }
    if (_quickActions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No modules assigned to your account yet.',
            style: TextStyle(color: exLightText),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            'Please contact your administrator.',
            style: TextStyle(color: exLightText),
          ),
        ],
      );
    }
    return _quickActionsGrid(
      context,
      screenHeight,
      screenWidth,
      isPortrait,
      _quickActions,
    );
  }

  Widget _quickActionsGrid(
    BuildContext context,
    double screenHeight,
    double screenWidth,
    bool isPortrait,
    List<Map<String, dynamic>> actions,
  ) {
    int cols = _getCrossAxisCount(screenWidth, isPortrait);
    double ratio = _getAspectRatio(screenWidth, screenHeight, isPortrait);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: screenHeight * 0.015,
        crossAxisSpacing: screenWidth * 0.03,
        childAspectRatio: ratio,
      ),
      itemBuilder: (context, i) => _buildActionCard(
        context,
        actions[i],
        screenHeight,
        screenWidth,
        isPortrait,
      ),
    );
  }

  int _getCrossAxisCount(double w, bool portrait) {
    if (!portrait) return 4;
    if (w > 600) return 3;
    return 2;
  }

  double _getAspectRatio(double w, double h, bool portrait) {
    if (!portrait) return 1.2;
    if (w > 600) return 1.0;
    if (w > 400) return 0.9;
    return 0.8;
  }

  Widget _buildActionCard(
    BuildContext context,
    Map<String, dynamic> action,
    double screenHeight,
    double screenWidth,
    bool isPortrait, {
    Key? key,
  }) {
    return Card(
      key: key,
      color: Colors.white,
      elevation: 2,
      shadowColor: exPrimaryBlue.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: exPrimaryTeal.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        onTap: () {
          if (action['page'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => action['page']),
            );
          } else if (action['infoText'] != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(action['infoText'])));
          }
        },
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.02),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isPortrait ? screenHeight * 0.06 : screenHeight * 0.08,
                height: isPortrait ? screenHeight * 0.06 : screenHeight * 0.08,
                decoration: BoxDecoration(
                  color: exPrimaryBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: Colors.white,
                  size: isPortrait ? screenHeight * 0.035 : screenHeight * 0.05,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  action['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isPortrait
                        ? screenHeight * 0.018
                        : screenHeight * 0.025,
                    color: exDarkText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                action['subtitle'] as String,
                style: TextStyle(
                  color: exLightText,
                  fontSize: isPortrait
                      ? screenHeight * 0.012
                      : screenHeight * 0.018,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildActionsFromModules(
    Map<String, dynamic>? profile,
  ) {
    final actions = <Map<String, dynamic>>[];
    final modules = profile?['Modules'];

    void add({
      required String title,
      required String subtitle,
      required IconData icon,
      Widget? page,
      String? infoText,
    }) {
      actions.add({
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
        'page': page,
        if (infoText != null) 'infoText': infoText,
      });
    }

    if (modules is List) {
      for (final module in modules) {
        final name = module['name']?.toString() ?? '';
        switch (name.toLowerCase()) {
          case 'upload activity':
            add(
              title: 'Upload Activity',
              subtitle: 'Record field activities',
              icon: Icons.upload,
              page: UploadActivityPage(),
            );
            break;
          case 'field survey':
            add(
              title: 'Field Survey',
              subtitle: 'Complete surveys',
              icon: Icons.note_alt,
              page: FieldSurveyPage(),
            );
            break;
          case 'expense tracker':
            add(
              title: 'Expense Tracker',
              subtitle: 'Submit bills & receipts',
              icon: Icons.attach_money,
              page: ExpenseTrackerPage(),
            );
            break;
          case 'travel tracker':
            add(
              title: 'Travel Tracker',
              subtitle: 'Track distance & routes',
              icon: Icons.map,
              page: TravelTrackerPage(),
            );
            break;
          case 'reports':
            add(
              title: 'Reports',
              subtitle: 'View analytics & data',
              icon: Icons.insert_chart,
              infoText: 'Reports coming soon.',
            );
            break;
          case 'new subscription':
            add(
              title: 'New Subscription',
              subtitle: 'Capture new leads',
              icon: Icons.person_add,
              page: NewSubscriptionPage(),
            );
            break;
          case 'subscribers':
            add(
              title: 'Subscribers',
              subtitle: 'Manage subscribers',
              icon: Icons.people,
              page: const SubscriberPage(),
            );
            break;
          // ── NEW ─────────────────────────────────────────
          case 'support tickets':
          case 'ticketing':
          case 'customer care':
            add(
              title: 'Support Tickets',
              subtitle: 'Cases & issues',
              icon: Icons.support_agent,
              page: const TicketingPage(),
            );
            break;
          // ────────────────────────────────────────────────
          default:
            break;
        }
      }
    }

    if (actions.isEmpty) actions.addAll(_defaultActions());

    add(
      title: 'Settings',
      subtitle: 'Account & preferences',
      icon: Icons.settings,
      page: SettingsPage(),
    );

    return actions;
  }

  List<Map<String, dynamic>> _defaultActions() => [
    {
      'title': 'Upload Activity',
      'subtitle': 'Record field activities',
      'icon': Icons.upload,
      'page': UploadActivityPage(),
    },
    {
      'title': 'New Subscription',
      'subtitle': 'Capture new leads',
      'icon': Icons.person_add,
      'page': NewSubscriptionPage(),
    },
    {
      'title': 'Expense Tracker',
      'subtitle': 'Submit bills & receipts',
      'icon': Icons.attach_money,
      'page': ExpenseTrackerPage(),
    },
    {
      'title': 'Travel Tracker',
      'subtitle': 'Track distance & routes',
      'icon': Icons.map,
      'page': TravelTrackerPage(),
    },
    {
      'title': 'Field Survey',
      'subtitle': 'Complete surveys',
      'icon': Icons.note_alt,
      'page': FieldSurveyPage(),
    },
    {
      'title': 'Subscribers',
      'subtitle': 'Manage subscribers',
      'icon': Icons.people,
      'page': const SubscriberPage(),
    },
    // ── NEW ─────────────────────────────────────────────
    {
      'title': 'Support Tickets',
      'subtitle': 'Cases & issues',
      'icon': Icons.support_agent,
      'page': const TicketingPage(),
    },
    // ────────────────────────────────────────────────────
  ];
}

// ═══════════════════════════════════════════════════════════════
//  MODULE BANNER  (reusable component)
// ═══════════════════════════════════════════════════════════════

class _ModuleBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ModuleBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.7),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
