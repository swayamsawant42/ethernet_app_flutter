// ignore_for_file: file_names
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'dart:async';

// ═══════════════════════════════════════════════════════════════
//  BRAND COLOURS
// ═══════════════════════════════════════════════════════════════

mixin _Brand {
  Color get blue => const Color(0xFF1E407A);
  Color get teal => const Color(0xFF30A8B5);
  Color get bg => const Color(0xFFF7F9FA);
  Color get dark => const Color(0xFF2E2E2E);
  Color get light => const Color(0xFF6C6C6C);
}

// ═══════════════════════════════════════════════════════════════
//  ENUMS / CONSTANTS
// ═══════════════════════════════════════════════════════════════

enum TicketStatus { open, inProgress, resolved, closed }

enum TicketPriority { high, medium, low }

extension TicketStatusX on TicketStatus {
  String get label => const {
    TicketStatus.open: 'Open',
    TicketStatus.inProgress: 'In Progress',
    TicketStatus.resolved: 'Resolved',
    TicketStatus.closed: 'Closed',
  }[this]!;

  Color get color => const {
    TicketStatus.open: Color(0xFF4CAF50), // green
    TicketStatus.inProgress: Color(0xFF2196F3), // blue
    TicketStatus.resolved: Color(0xFF9E9E9E), // grey
    TicketStatus.closed: Color(0xFF607D8B), // blue-grey
  }[this]!;

  static TicketStatus fromString(String s) {
    switch (s.toLowerCase().replaceAll(' ', '')) {
      case 'inprogress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }
}

extension TicketPriorityX on TicketPriority {
  String get label => const {
    TicketPriority.high: 'High',
    TicketPriority.medium: 'Medium',
    TicketPriority.low: 'Low',
  }[this]!;

  Color get color => const {
    TicketPriority.high: Color(0xFFE53935),
    TicketPriority.medium: Color(0xFFFB8C00),
    TicketPriority.low: Color(0xFF43A047),
  }[this]!;

  static TicketPriority fromString(String s) {
    switch (s.toLowerCase()) {
      case 'high':
        return TicketPriority.high;
      case 'low':
        return TicketPriority.low;
      default:
        return TicketPriority.medium;
    }
  }
}

const List<String> kIssueCategories = [
  'Internet Down',
  'Slow Speed',
  'Billing Issue',
  'Hardware / Equipment',
  'OLT Pon Port Down',
  'Optical Power Issue',
  'Link Port Errors',
  'New Connection Request',
  'Plan Upgrade/Downgrade',
  'Other',
];

const List<String> kTeams = [
  'NOC',
  'Field Tech',
  'Billing',
  'Sales',
  'Management',
];
const List<String> kGroups = ['Group A', 'Group B', 'Group C'];
const List<String> kCaseOrigins = [
  'Phone Call',
  'WhatsApp',
  'Walk-in',
  'App',
  'Email',
];
const List<String> kAllocTypes = ['Auto', 'Manual', 'Zone-based'];
const List<String> kStaff = [
  'Rajesh Kumar',
  'Meena Sharma',
  'Arjun Nair',
  'Priya Patel',
  'Suresh Menon',
];

// ═══════════════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════════════

class TicketComment {
  final String id;
  final String author;
  final String message;
  final DateTime timestamp;
  final bool isInternal;

  const TicketComment({
    required this.id,
    required this.author,
    required this.message,
    required this.timestamp,
    this.isInternal = false,
  });
}

class Ticket {
  final String id;
  final String ticketNumber;
  final String title;
  final String remark;
  final String subscriberName;
  final String subscriberMobile;
  final String subscriberAccountNo;
  final String category;
  final TicketStatus status;
  final TicketPriority priority;
  final String assignedTo;
  final String team;
  final String group;
  final String caseOrigin;
  final String allocationType;
  final String alternateMobile;
  final String area;
  final bool isEscalated;
  final bool allocateInventory;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? resolvedAt;
  final String resolutionNote;
  final List<TicketComment> comments;
  final List<String> attachments;

  const Ticket({
    required this.id,
    required this.ticketNumber,
    required this.title,
    this.remark = '',
    required this.subscriberName,
    this.subscriberMobile = '',
    this.subscriberAccountNo = '',
    required this.category,
    required this.status,
    required this.priority,
    this.assignedTo = '',
    this.team = '',
    this.group = '',
    this.caseOrigin = '',
    this.allocationType = '',
    this.alternateMobile = '',
    this.area = '',
    this.isEscalated = false,
    this.allocateInventory = false,
    required this.createdAt,
    this.dueDate,
    this.resolvedAt,
    this.resolutionNote = '',
    this.comments = const [],
    this.attachments = const [],
  });

  Ticket copyWith({
    TicketStatus? status,
    TicketPriority? priority,
    String? assignedTo,
    String? team,
    bool? isEscalated,
    String? resolutionNote,
    DateTime? resolvedAt,
    List<TicketComment>? comments,
  }) => Ticket(
    id: id,
    ticketNumber: ticketNumber,
    title: title,
    remark: remark,
    subscriberName: subscriberName,
    subscriberMobile: subscriberMobile,
    subscriberAccountNo: subscriberAccountNo,
    category: category,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    assignedTo: assignedTo ?? this.assignedTo,
    team: team ?? this.team,
    group: group,
    caseOrigin: caseOrigin,
    allocationType: allocationType,
    alternateMobile: alternateMobile,
    area: area,
    isEscalated: isEscalated ?? this.isEscalated,
    allocateInventory: allocateInventory,
    createdAt: createdAt,
    dueDate: dueDate,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    resolutionNote: resolutionNote ?? this.resolutionNote,
    comments: comments ?? this.comments,
    attachments: attachments,
  );
}

// ═══════════════════════════════════════════════════════════════
//  MOCK DATA
// ═══════════════════════════════════════════════════════════════

final List<Ticket> _mockTickets = [
  Ticket(
    id: '1',
    ticketNumber: 'TKT-2025-001',
    title: 'Internet completely down since morning',
    remark: 'Customer reported no connectivity since 6 AM.',
    subscriberName: 'NEW KANTARA HOTEL',
    subscriberMobile: '9876543210',
    subscriberAccountNo: 'H67560',
    category: 'Internet Down',
    status: TicketStatus.open,
    priority: TicketPriority.high,
    assignedTo: 'Arjun Nair',
    team: 'NOC',
    group: 'Group A',
    caseOrigin: 'Phone Call',
    area: 'MG Road',
    isEscalated: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    dueDate: DateTime.now().add(const Duration(hours: 4)),
    comments: [
      TicketComment(
        id: 'c1',
        author: 'Arjun Nair',
        message: 'Checked OLT — PON port 3 is down. Dispatching field tech.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isInternal: true,
      ),
      TicketComment(
        id: 'c2',
        author: 'System',
        message: 'Ticket escalated due to high priority SLA breach risk.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  ),
  Ticket(
    id: '2',
    ticketNumber: 'TKT-2025-002',
    title: 'Slow speed — getting only 10 Mbps on 100 Mbps plan',
    remark: 'Speed test results shared by customer.',
    subscriberName: 'Arjun Mehta',
    subscriberMobile: '9988776655',
    subscriberAccountNo: 'H67562',
    category: 'Slow Speed',
    status: TicketStatus.inProgress,
    priority: TicketPriority.medium,
    assignedTo: 'Rajesh Kumar',
    team: 'Field Tech',
    group: 'Group B',
    caseOrigin: 'WhatsApp',
    area: 'Civil Lines',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    dueDate: DateTime.now().add(const Duration(hours: 12)),
    comments: [
      TicketComment(
        id: 'c3',
        author: 'Rajesh Kumar',
        message: 'Optical power issue suspected. Visiting site at 3 PM.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ],
  ),
  Ticket(
    id: '3',
    ticketNumber: 'TKT-2025-003',
    title: 'Billing discrepancy — charged twice for May',
    subscriberName: 'Sunita Patil',
    subscriberMobile: '9123456780',
    subscriberAccountNo: 'H67561',
    category: 'Billing Issue',
    status: TicketStatus.resolved,
    priority: TicketPriority.low,
    assignedTo: 'Meena Sharma',
    team: 'Billing',
    group: 'Group A',
    caseOrigin: 'Walk-in',
    area: 'Shivaji Nagar',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    resolvedAt: DateTime.now().subtract(const Duration(hours: 6)),
    resolutionNote: 'Duplicate charge reversed. Credited to account balance.',
    comments: [
      TicketComment(
        id: 'c4',
        author: 'Meena Sharma',
        message: 'Confirmed duplicate payment. Processing refund.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TicketComment(
        id: 'c5',
        author: 'Meena Sharma',
        message: 'Refund processed. Closing ticket.',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ],
  ),
  Ticket(
    id: '4',
    ticketNumber: 'TKT-2025-004',
    title: 'Router replacement needed — device not powering on',
    subscriberName: 'Ravi Kumar',
    subscriberMobile: '9876543200',
    subscriberAccountNo: 'H67563',
    category: 'Hardware / Equipment',
    status: TicketStatus.open,
    priority: TicketPriority.medium,
    assignedTo: '',
    team: 'Field Tech',
    group: 'Group C',
    caseOrigin: 'App',
    area: 'MG Road',
    allocateInventory: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    dueDate: DateTime.now().add(const Duration(days: 1)),
    comments: [],
  ),
];

// ═══════════════════════════════════════════════════════════════
//  SHARED HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

String _fmt(DateTime dt) => DateFormat('dd MMM yy, hh:mm a').format(dt);
String _fmtDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);

Widget _statusDot(TicketStatus s, {double size = 10}) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
);

Widget _pill(String label, Color color, {double fontSize = 10}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: color, width: 0.8),
  ),
  child: Text(
    label,
    style: TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w700,
    ),
  ),
);

// ═══════════════════════════════════════════════════════════════
//  TICKET LIST PAGE  (Main entry point)
// ═══════════════════════════════════════════════════════════════

class TicketingPage extends StatefulWidget {
  const TicketingPage({super.key});
  @override
  State<TicketingPage> createState() => _TicketingPageState();
}

class _TicketingPageState extends State<TicketingPage>
    with _Brand, SingleTickerProviderStateMixin {
  List<Ticket> _all = [];
  List<Ticket> _filtered = [];
  bool _loading = true;
  bool _myCases = false; // toggle My Cases / All Cases

  // Filters
  String _search = '';
  String _statusFilter = 'All';
  String _priorityFilter = 'All';
  String _teamFilter = 'All';
  // ignore: prefer_final_fields
  String _categoryFilter = 'All';

  // Bulk select
  final Set<String> _selected = {};
  bool _bulkMode = false;

  late TabController _tabCtrl;

  final List<String> _statusOpts = [
    'All',
    'Open',
    'In Progress',
    'Resolved',
    'Closed',
  ];
  final List<String> _priorityOpts = ['All', 'High', 'Medium', 'Low'];
  final List<String> _teamOpts = ['All', ...kTeams];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      setState(() {
        _myCases = _tabCtrl.index == 0;
        _applyFilters();
      });
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    // API: replace with → await _apiService.getTickets()
    setState(() {
      _all = _mockTickets;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    _filtered = _all.where((t) {
      // My cases filter (stub: in real app filter by logged-in user)
      if (_myCases && t.assignedTo != 'Arjun Nair') return false;

      final q = _search.toLowerCase();
      final matchQ =
          q.isEmpty ||
          t.ticketNumber.toLowerCase().contains(q) ||
          t.title.toLowerCase().contains(q) ||
          t.subscriberName.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q);

      final matchS = _statusFilter == 'All' || t.status.label == _statusFilter;
      final matchP =
          _priorityFilter == 'All' || t.priority.label == _priorityFilter;
      final matchT = _teamFilter == 'All' || t.team == _teamFilter;
      final matchC = _categoryFilter == 'All' || t.category == _categoryFilter;

      return matchQ && matchS && matchP && matchT && matchC;
    }).toList();

    // Sort: escalated first, then by created date desc
    _filtered.sort((a, b) {
      if (a.isEscalated && !b.isEscalated) return -1;
      if (!a.isEscalated && b.isEscalated) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  void _openTicket(Ticket t) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketDetailPage(ticket: t)),
    ).then((_) => _load());
  }

  void _openCreate({bool quick = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateTicketPage(quickMode: quick)),
    ).then((_) => _load());
  }

  // Summary counts
  Map<TicketStatus, int> get _counts => {
    for (final s in TicketStatus.values)
      s: _all.where((t) => t.status == s).length,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'SUPPORT TICKETS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: blue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_bulkMode)
            TextButton(
              onPressed: () => setState(() {
                _selected.clear();
                _bulkMode = false;
              }),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) {
                if (v == 'bulk') setState(() => _bulkMode = true);
                if (v == 'refresh') _load();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'bulk', child: Text('Bulk Select')),
                const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: teal,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'MY CASES'),
            Tab(text: 'ALL CASES'),
          ],
        ),
      ),
      body: Column(
        children: [
          _SummaryBar(counts: _counts),
          _FilterBar(
            search: _search,
            statusFilter: _statusFilter,
            priorityFilter: _priorityFilter,
            teamFilter: _teamFilter,
            statusOpts: _statusOpts,
            priorityOpts: _priorityOpts,
            teamOpts: _teamOpts,
            filteredCount: _filtered.length,
            totalCount: _all.length,
            onSearch: (v) => setState(() {
              _search = v;
              _applyFilters();
            }),
            onStatus: (v) => setState(() {
              _statusFilter = v;
              _applyFilters();
            }),
            onPriority: (v) => setState(() {
              _priorityFilter = v;
              _applyFilters();
            }),
            onTeam: (v) => setState(() {
              _teamFilter = v;
              _applyFilters();
            }),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: teal))
                : _filtered.isEmpty
                ? _EmptyTickets(teal: teal, light: light)
                : RefreshIndicator(
                    color: teal,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _TicketCard(
                        ticket: _filtered[i],
                        bulkMode: _bulkMode,
                        selected: _selected.contains(_filtered[i].id),
                        onTap: () => _bulkMode
                            ? setState(() {
                                _selected.contains(_filtered[i].id)
                                    ? _selected.remove(_filtered[i].id)
                                    : _selected.add(_filtered[i].id);
                              })
                            : _openTicket(_filtered[i]),
                        onLongPress: () => setState(() {
                          _bulkMode = true;
                          _selected.add(_filtered[i].id);
                        }),
                      ),
                    ),
                  ),
          ),
          // Bulk action bar
          if (_bulkMode && _selected.isNotEmpty)
            _BulkActionBar(
              count: _selected.count,
              blue: blue,
              teal: teal,
              onClose: () => _showBulkStatusSheet(''),
              onAssign: () => _showBulkAssignSheet(),
            ),
        ],
      ),
      floatingActionButton: _bulkMode
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'quick',
                  mini: true,
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  tooltip: 'Quick Case',
                  onPressed: () => _openCreate(quick: true),
                  child: const Icon(Icons.flash_on),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'new',
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'New Ticket',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _openCreate(),
                ),
              ],
            ),
    );
  }

  void _showBulkStatusSheet(String status) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set status for ${_selected.length} tickets',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...TicketStatus.values.map(
              (s) => ListTile(
                leading: _statusDot(s, size: 14),
                title: Text(s.label),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${_selected.length} tickets set to ${s.label}',
                      ),
                    ),
                  );
                  setState(() {
                    _selected.clear();
                    _bulkMode = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkAssignSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Assign ${_selected.length} tickets to:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...kStaff.map(
              (s) => ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF1E407A),
                  child: Text(
                    s[0],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(s),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${_selected.length} tickets assigned to $s',
                      ),
                    ),
                  );
                  setState(() {
                    _selected.clear();
                    _bulkMode = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Set {
  int get count => length;
}

// ─── Summary bar ───
class _SummaryBar extends StatelessWidget with _Brand {
  final Map<TicketStatus, int> counts;
  const _SummaryBar({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: TicketStatus.values
            .map(
              (s) => Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statusDot(s),
                        const SizedBox(width: 4),
                        Text(
                          '${counts[s] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: s.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(s.label, style: TextStyle(fontSize: 10, color: light)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Filter bar ───
class _FilterBar extends StatelessWidget with _Brand {
  final String search, statusFilter, priorityFilter, teamFilter;
  final List<String> statusOpts, priorityOpts, teamOpts;
  final int filteredCount, totalCount;
  final void Function(String) onSearch, onStatus, onPriority, onTeam;

  const _FilterBar({
    required this.search,
    required this.statusFilter,
    required this.priorityFilter,
    required this.teamFilter,
    required this.statusOpts,
    required this.priorityOpts,
    required this.teamOpts,
    required this.filteredCount,
    required this.totalCount,
    required this.onSearch,
    required this.onStatus,
    required this.onPriority,
    required this.onTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search ticket number, subscriber, category…',
              hintStyle: TextStyle(fontSize: 12, color: light),
              prefixIcon: Icon(Icons.search, color: teal, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: light.withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: light.withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: blue, width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFFF7F9FA),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DropChip(
                  label: statusFilter == 'All' ? 'Status' : statusFilter,
                  icon: Icons.circle,
                  opts: statusOpts,
                  onSelect: onStatus,
                ),
                _DropChip(
                  label: priorityFilter == 'All' ? 'Priority' : priorityFilter,
                  icon: Icons.flag_outlined,
                  opts: priorityOpts,
                  onSelect: onPriority,
                ),
                _DropChip(
                  label: teamFilter == 'All' ? 'Team' : teamFilter,
                  icon: Icons.group_outlined,
                  opts: teamOpts,
                  onSelect: onTeam,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Showing $filteredCount of $totalCount tickets',
            style: TextStyle(fontSize: 11, color: light),
          ),
        ],
      ),
    );
  }
}

class _DropChip extends StatelessWidget with _Brand {
  final String label;
  final IconData icon;
  final List<String> opts;
  final void Function(String) onSelect;
  const _DropChip({
    required this.label,
    required this.icon,
    required this.opts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final active =
        !label.endsWith('Status') &&
        !label.endsWith('Priority') &&
        !label.endsWith('Team');
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Filter by $label',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...opts.map(
              (o) => ListTile(
                title: Text(o),
                onTap: () {
                  Navigator.pop(context);
                  onSelect(o);
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? teal.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? teal : light.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: active ? teal : light),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? teal : light,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_drop_down, size: 14, color: active ? teal : light),
          ],
        ),
      ),
    );
  }
}

// ─── Ticket card ───
class _TicketCard extends StatelessWidget with _Brand {
  final Ticket ticket;
  final bool bulkMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _TicketCard({
    required this.ticket,
    required this.bulkMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final slaBreach =
        t.dueDate != null &&
        DateTime.now().isAfter(t.dueDate!) &&
        t.status != TicketStatus.resolved &&
        t.status != TicketStatus.closed;
    final slaNear =
        !slaBreach &&
        t.dueDate != null &&
        t.dueDate!.difference(DateTime.now()).inHours <= 2 &&
        t.status != TicketStatus.resolved &&
        t.status != TicketStatus.closed;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: teal, width: 2)
            : slaBreach
            ? const BorderSide(color: Color(0xFFE53935), width: 1)
            : BorderSide.none,
      ),
      elevation: 2,
      shadowColor: blue.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: status dot + ticket number + escalation + priority + bulk checkbox
              Row(
                children: [
                  _statusDot(t.status, size: 9),
                  const SizedBox(width: 6),
                  Text(
                    t.ticketNumber,
                    style: TextStyle(
                      fontSize: 11,
                      color: light,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (t.isEscalated)
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Color(0xFFE53935),
                          size: 13,
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'ESCALATED',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                  const Spacer(),
                  _pill(t.priority.label, t.priority.color),
                  const SizedBox(width: 6),
                  if (bulkMode)
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? teal : light,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Title
              Text(
                t.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: dark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              // Subscriber
              Row(
                children: [
                  Icon(Icons.person_outline, size: 13, color: light),
                  const SizedBox(width: 4),
                  Text(
                    t.subscriberName,
                    style: TextStyle(fontSize: 12, color: light),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.category_outlined, size: 13, color: light),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      t.category,
                      style: TextStyle(fontSize: 12, color: light),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Bottom row: status + assigned + SLA + comments
              Row(
                children: [
                  _pill(t.status.label, t.status.color),
                  const SizedBox(width: 6),
                  if (t.assignedTo.isNotEmpty) ...[
                    Icon(Icons.engineering, size: 12, color: light),
                    const SizedBox(width: 3),
                    Text(
                      t.assignedTo,
                      style: TextStyle(fontSize: 11, color: light),
                    ),
                  ] else
                    Text(
                      'Unassigned',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const Spacer(),
                  if (slaBreach)
                    _pill('SLA BREACH', const Color(0xFFE53935))
                  else if (slaNear)
                    _pill(
                      'SLA ~${t.dueDate!.difference(DateTime.now()).inHours}h',
                      Colors.orange,
                    )
                  else if (t.dueDate != null)
                    Text(
                      _fmtDate(t.dueDate!),
                      style: TextStyle(fontSize: 10, color: light),
                    ),
                  if (t.comments.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.chat_bubble_outline, size: 12, color: light),
                    const SizedBox(width: 2),
                    Text(
                      '${t.comments.length}',
                      style: TextStyle(fontSize: 11, color: light),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  final int count;
  final Color blue, teal;
  final VoidCallback onClose;
  final VoidCallback onAssign;
  const _BulkActionBar({
    required this.count,
    required this.blue,
    required this.teal,
    required this.onClose,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: blue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            '$count selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onAssign,
            icon: const Icon(Icons.person_add, color: Colors.white, size: 16),
            label: const Text(
              'Assign',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          TextButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.update, color: Colors.white, size: 16),
            label: const Text(
              'Status',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTickets extends StatelessWidget {
  final Color teal, light;
  const _EmptyTickets({required this.teal, required this.light});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.support_agent, size: 64, color: light),
        const SizedBox(height: 12),
        Text(
          'No tickets found',
          style: TextStyle(
            fontSize: 16,
            color: light,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Adjust filters or create a new ticket',
          style: TextStyle(fontSize: 13, color: light),
        ),
      ],
    ),
  );
}
// ═══════════════════════════════════════════════════════════════
//  TICKET DETAIL PAGE
// ═══════════════════════════════════════════════════════════════

class TicketDetailPage extends StatefulWidget {
  final Ticket ticket;
  const TicketDetailPage({super.key, required this.ticket});
  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage>
    with _Brand, SingleTickerProviderStateMixin {
  late Ticket _t;
  late TabController _tab;
  final _commentCtrl = TextEditingController();
  bool _internalNote = false;
  bool _showResolutionForm = false;
  final _resolutionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _t = widget.ticket;
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _commentCtrl.dispose();
    _resolutionCtrl.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentCtrl.text.trim().isEmpty) return;
    final comment = TicketComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: 'Me', // API: replace with logged-in user name from session
      message: _commentCtrl.text.trim(),
      timestamp: DateTime.now(),
      isInternal: _internalNote,
    );
    // API: await _apiService.addComment(_t.id, comment)
    setState(() {
      _t = _t.copyWith(comments: [..._t.comments, comment]);
      _commentCtrl.clear();
    });
  }

  void _updateStatus(TicketStatus s) {
    // API: await _apiService.updateTicketStatus(_t.id, s)
    setState(() => _t = _t.copyWith(status: s));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Status updated to ${s.label}')));
  }

  void _updateAssignee(String staff) {
    // API: await _apiService.assignTicket(_t.id, staff)
    setState(() => _t = _t.copyWith(assignedTo: staff));
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Assigned to $staff')));
  }

  void _toggleEscalation() {
    // API: await _apiService.toggleEscalation(_t.id)
    setState(() => _t = _t.copyWith(isEscalated: !_t.isEscalated));
  }

  void _closeWithResolution() {
    if (_resolutionCtrl.text.trim().isEmpty) return;
    // API: await _apiService.closeTicket(_t.id, _resolutionCtrl.text)
    setState(() {
      _t = _t.copyWith(
        status: TicketStatus.resolved,
        resolutionNote: _resolutionCtrl.text.trim(),
        resolvedAt: DateTime.now(),
      );
      _showResolutionForm = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ticket resolved!')));
  }

  void _callSubscriber() {
    // API: launch('tel:${_t.subscriberMobile}')
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Calling ${_t.subscriberMobile}…')));
  }

  void _whatsapp() {
    // API: launch('https://wa.me/91${_t.subscriberMobile}')
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening WhatsApp for ${_t.subscriberMobile}…')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slaBreach =
        _t.dueDate != null &&
        DateTime.now().isAfter(_t.dueDate!) &&
        _t.status != TicketStatus.resolved &&
        _t.status != TicketStatus.closed;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _t.ticketNumber,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        backgroundColor: blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Escalation toggle
          IconButton(
            icon: Icon(
              _t.isEscalated
                  ? Icons.warning_amber
                  : Icons.warning_amber_outlined,
              color: _t.isEscalated ? Colors.orange : Colors.white,
            ),
            tooltip: _t.isEscalated ? 'Remove Escalation' : 'Escalate',
            onPressed: _toggleEscalation,
          ),
          // Edit
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateTicketPage(existingTicket: _t),
              ),
            ).then((_) => setState(() {})),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: teal,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'COMMENTS'),
            Tab(text: 'HISTORY'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top action strip
          _ActionStrip(
            ticket: _t,
            slaBreach: slaBreach,
            onStatusChange: _showStatusSheet,
            onAssign: _showAssignSheet,
            onCall: _callSubscriber,
            onWhatsApp: _whatsapp,
            onResolve: () => setState(() => _showResolutionForm = true),
            teal: teal,
            blue: blue,
            light: light,
          ),
          // <<< MOD START: SLA banner conditional (changed) >>>
          if (slaBreach)
            // <<< MOD END: SLA banner conditional (changed) >>>
            Container(
              color: const Color(0xFFE53935).withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_off,
                    color: Color(0xFFE53935),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'SLA BREACHED — Immediate action required',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (_showResolutionForm)
            _ResolutionForm(
              ctrl: _resolutionCtrl,
              onSubmit: _closeWithResolution,
              onCancel: () => setState(() => _showResolutionForm = false),
              teal: teal,
              blue: blue,
            ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _OverviewTab(t: _t),
                _CommentsTab(
                  t: _t,
                  commentCtrl: _commentCtrl,
                  internalNote: _internalNote,
                  onToggleInternal: (v) => setState(() => _internalNote = v),
                  onSend: _addComment,
                  teal: teal,
                  blue: blue,
                  light: light,
                ),
                _HistoryTab(t: _t, light: light),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Update Status',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ...TicketStatus.values.map(
            (s) => ListTile(
              leading: _statusDot(s, size: 14),
              title: Text(s.label),
              trailing: _t.status == s ? Icon(Icons.check, color: teal) : null,
              onTap: () {
                Navigator.pop(context);
                _updateStatus(s);
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showAssignSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Assign Ticket',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ...kStaff.map(
            (s) => ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: blue,
                child: Text(
                  s[0],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              title: Text(s),
              trailing: _t.assignedTo == s
                  ? Icon(Icons.check, color: teal)
                  : null,
              onTap: () => _updateAssignee(s),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─── Top action strip ───
class _ActionStrip extends StatelessWidget {
  final Ticket ticket;
  final bool slaBreach;
  final VoidCallback onStatusChange, onAssign, onCall, onWhatsApp, onResolve;
  final Color teal, blue, light;
  const _ActionStrip({
    required this.ticket,
    required this.slaBreach,
    required this.onStatusChange,
    required this.onAssign,
    required this.onCall,
    required this.onWhatsApp,
    required this.onResolve,
    required this.teal,
    required this.blue,
    required this.light,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Status pill tappable
          GestureDetector(
            onTap: onStatusChange,
            child: Row(
              children: [
                _statusDot(ticket.status, size: 10),
                const SizedBox(width: 5),
                Text(
                  ticket.status.label,
                  style: TextStyle(
                    color: ticket.status.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: light, size: 16),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _pill(ticket.priority.label, ticket.priority.color),
          const Spacer(),
          // Call
          _IconBtn(
            icon: Icons.call,
            color: Colors.green,
            onTap: onCall,
            tooltip: 'Call Subscriber',
          ),
          // WhatsApp
          _IconBtn(
            icon: Icons.chat,
            color: const Color(0xFF25D366),
            onTap: onWhatsApp,
            tooltip: 'WhatsApp',
          ),
          // Assign
          _IconBtn(
            icon: Icons.person_add_alt,
            color: blue,
            onTap: onAssign,
            tooltip: 'Assign',
          ),
          // Resolve
          if (ticket.status != TicketStatus.resolved &&
              ticket.status != TicketStatus.closed)
            _IconBtn(
              icon: Icons.check_circle_outline,
              color: teal,
              onTap: onResolve,
              tooltip: 'Resolve',
            ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ─── Overview tab ───
class _OverviewTab extends StatelessWidget with _Brand {
  final Ticket t;
  const _OverviewTab({required this.t});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Ticket info card
          _Card(
            title: 'Ticket Details',
            children: [
              _buildDetailRow(Icons.tag, 'Ticket No.', t.ticketNumber),
              _buildDetailRow(Icons.title, 'Title', t.title),
              if (t.remark.isNotEmpty)
                _buildDetailRow(Icons.notes, 'Remark', t.remark),
              _buildDetailRow(Icons.category, 'Category', t.category),
              _buildDetailRow(
                Icons.login,
                'Origin',
                t.caseOrigin.isEmpty ? '—' : t.caseOrigin,
              ),
              _buildDetailRow(Icons.access_time, 'Created', _fmt(t.createdAt)),
              if (t.dueDate != null)
                _buildDetailRow(
                  Icons.timer,
                  'Due / ETR',
                  _fmt(t.dueDate!),
                  valueColor: DateTime.now().isAfter(t.dueDate!)
                      ? const Color(0xFFE53935)
                      : null,
                ),
              if (t.resolvedAt != null)
                _buildDetailRow(
                  Icons.check_circle,
                  'Resolved At',
                  _fmt(t.resolvedAt!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Subscriber card
          _Card(
            title: 'Subscriber',
            children: [
              _buildDetailRow(Icons.person, 'Name', t.subscriberName),
              _buildDetailRow(Icons.phone, 'Mobile', t.subscriberMobile),
              _buildDetailRow(
                Icons.confirmation_number,
                'Account',
                t.subscriberAccountNo.isEmpty ? '—' : t.subscriberAccountNo,
              ),
              if (t.alternateMobile.isNotEmpty)
                _buildDetailRow(
                  Icons.phone_forwarded,
                  'Alt. Mobile',
                  t.alternateMobile,
                ),
              _buildDetailRow(
                Icons.location_on,
                'Area',
                t.area.isEmpty ? '—' : t.area,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Assignment card
          _Card(
            title: 'Assignment',
            children: [
              _buildDetailRow(
                Icons.engineering,
                'Assigned To',
                t.assignedTo.isEmpty ? 'Unassigned' : t.assignedTo,
                valueColor: t.assignedTo.isEmpty ? Colors.orange : null,
              ),
              _buildDetailRow(
                Icons.group,
                'Team',
                t.team.isEmpty ? '—' : t.team,
              ),
              _buildDetailRow(
                Icons.grid_view,
                'Group',
                t.group.isEmpty ? '—' : t.group,
              ),
              if (t.allocationType.isNotEmpty)
                _buildDetailRow(
                  Icons.alt_route,
                  'Allocation Type',
                  t.allocationType,
                ),
              _buildDetailRow(
                Icons.inventory_2,
                'Inventory Allocated',
                t.allocateInventory ? 'Yes' : 'No',
                valueColor: t.allocateInventory ? Colors.green : null,
              ),
            ],
          ),
          if (t.resolutionNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              title: 'Resolution',
              children: [
                _buildDetailRow(
                  Icons.check_circle_outline,
                  'Note',
                  t.resolutionNote,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Comments tab ───
class _CommentsTab extends StatelessWidget {
  final Ticket t;
  final TextEditingController commentCtrl;
  final bool internalNote;
  final void Function(bool) onToggleInternal;
  final VoidCallback onSend;
  final Color teal, blue, light;

  const _CommentsTab({
    required this.t,
    required this.commentCtrl,
    required this.internalNote,
    required this.onToggleInternal,
    required this.onSend,
    required this.teal,
    required this.blue,
    required this.light,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: t.comments.isEmpty
              ? Center(
                  child: Text(
                    'No comments yet',
                    style: TextStyle(color: light, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: t.comments.length,
                  itemBuilder: (_, i) {
                    final c = t.comments[i];
                    return _CommentBubble(comment: c, teal: teal, blue: blue);
                  },
                ),
        ),
        // Input bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Switch(
                    value: internalNote,
                    activeThumbColor: blue,
                    onChanged: onToggleInternal,
                  ),
                  Text(
                    'Internal Note',
                    style: TextStyle(fontSize: 12, color: light),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: internalNote
                            ? 'Add internal note (not visible to customer)…'
                            : 'Add comment…',
                        hintStyle: TextStyle(fontSize: 12, color: light),
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: light.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: blue, width: 1.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FA),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSend,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: internalNote ? blue : teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final TicketComment comment;
  final Color teal, blue;
  const _CommentBubble({
    required this.comment,
    required this.teal,
    required this.blue,
  });

  @override
  Widget build(BuildContext context) {
    final isInternal = comment.isInternal;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isInternal
                ? blue.withValues(alpha: 0.15)
                : teal.withValues(alpha: 0.15),
            child: Text(
              comment.author.isNotEmpty ? comment.author[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 12,
                color: isInternal ? blue : teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isInternal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Internal',
                          style: TextStyle(
                            fontSize: 9,
                            color: blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(comment.timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6C6C6C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isInternal
                        ? blue.withValues(alpha: 0.05)
                        : teal.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isInternal
                          ? blue.withValues(alpha: 0.15)
                          : teal.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    comment.message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History tab ───
class _HistoryTab extends StatelessWidget {
  final Ticket t;
  final Color light;
  const _HistoryTab({required this.t, required this.light});

  @override
  Widget build(BuildContext context) {
    // Synthetic history from ticket data
    final List<Map<String, dynamic>> history = [
      {
        'action': 'Ticket Created',
        'detail': 'Origin: ${t.caseOrigin.isEmpty ? 'Unknown' : t.caseOrigin}',
        'time': t.createdAt,
        'icon': Icons.add_circle_outline,
        'color': const Color(0xFF4CAF50),
      },
      if (t.assignedTo.isNotEmpty)
        {
          'action': 'Assigned to ${t.assignedTo}',
          'detail': 'Team: ${t.team}',
          'time': t.createdAt.add(const Duration(minutes: 5)),
          'icon': Icons.person_add,
          'color': const Color(0xFF2196F3),
        },
      if (t.isEscalated)
        {
          'action': 'Ticket Escalated',
          'detail': 'Marked as high urgency',
          'time': t.createdAt.add(const Duration(minutes: 30)),
          'icon': Icons.warning_amber,
          'color': const Color(0xFFE53935),
        },
      if (t.status == TicketStatus.resolved || t.status == TicketStatus.closed)
        {
          'action': 'Ticket Resolved',
          'detail': t.resolutionNote.isEmpty
              ? 'Marked as resolved'
              : t.resolutionNote,
          'time': t.resolvedAt ?? DateTime.now(),
          'icon': Icons.check_circle,
          'color': const Color(0xFF9E9E9E),
        },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final h = history[i];
        final isLast = i == history.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (h['color'] as Color).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    h['icon'] as IconData,
                    color: h['color'] as Color,
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: light.withValues(alpha: 0.2),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h['action'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if ((h['detail'] as String).isNotEmpty)
                      Text(
                        h['detail'] as String,
                        style: TextStyle(fontSize: 12, color: light),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      _fmt(h['time'] as DateTime),
                      style: TextStyle(fontSize: 11, color: light),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Resolution form widget ───
class _ResolutionForm extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSubmit, onCancel;
  final Color teal, blue;
  const _ResolutionForm({
    required this.ctrl,
    required this.onSubmit,
    required this.onCancel,
    required this.teal,
    required this.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resolution Note',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: blue,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe what was done to resolve the issue…',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: blue, width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFFF7F9FA),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mark Resolved'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared card / row helpers ───
class _Card extends StatelessWidget with _Brand {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: blue,
              ),
            ),
            const Divider(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

Widget _buildDetailRow(
  IconData icon,
  String label,
  String value, {
  Color? valueColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF30A8B5)),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6C6C6C)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? const Color(0xFF2E2E2E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
// ═══════════════════════════════════════════════════════════════
//  CREATE / EDIT TICKET PAGE
// ═══════════════════════════════════════════════════════════════

class CreateTicketPage extends StatefulWidget {
  final bool quickMode;
  final Ticket? existingTicket;
  const CreateTicketPage({
    super.key,
    this.quickMode = false,
    this.existingTicket,
  });
  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> with _Brand {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _titleSameAsRemark = false;

  // Fields
  late TextEditingController _subscriberName;
  late TextEditingController _subscriberMobile;
  late TextEditingController _altMobile;
  late TextEditingController _title;
  late TextEditingController _remark;
  late TextEditingController _resolutionNote;

  String _category = kIssueCategories.first;
  String _priority = 'Medium';
  String _status = 'Open';
  String _team = kTeams.first;
  String _group = kGroups.first;
  String _assignedTo = '';
  String _caseOrigin = kCaseOrigins.first;
  String _allocationType = kAllocTypes.first;
  bool _isEscalated = false;
  bool _allocateInventory = false;
  DateTime? _dueDate;

  bool get _isEdit => widget.existingTicket != null;
  bool get _isQuick => widget.quickMode && !_isEdit;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTicket;
    _subscriberName = TextEditingController(text: t?.subscriberName ?? '');
    _subscriberMobile = TextEditingController(text: t?.subscriberMobile ?? '');
    _altMobile = TextEditingController(text: t?.alternateMobile ?? '');
    _title = TextEditingController(text: t?.title ?? '');
    _remark = TextEditingController(text: t?.remark ?? '');
    _resolutionNote = TextEditingController(text: t?.resolutionNote ?? '');

    if (t != null) {
      _category = t.category;
      _priority = t.priority.label;
      _status = t.status.label;
      _team = t.team.isNotEmpty ? t.team : kTeams.first;
      _group = t.group.isNotEmpty ? t.group : kGroups.first;
      _assignedTo = t.assignedTo;
      _caseOrigin = t.caseOrigin.isNotEmpty ? t.caseOrigin : kCaseOrigins.first;
      _allocationType = t.allocationType.isNotEmpty
          ? t.allocationType
          : kAllocTypes.first;
      _isEscalated = t.isEscalated;
      _allocateInventory = t.allocateInventory;
      _dueDate = t.dueDate;
    }
  }

  @override
  void dispose() {
    _subscriberName.dispose();
    _subscriberMobile.dispose();
    _altMobile.dispose();
    _title.dispose();
    _remark.dispose();
    _resolutionNote.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final _ = {
      'subscriberName': _subscriberName.text.trim(),
      'subscriberMobile': _subscriberMobile.text.trim(),
      'alternateMobile': _altMobile.text.trim(),
      'title': _title.text.trim(),
      'remark': _remark.text.trim(),
      'category': _category,
      'priority': _priority,
      'status': _status,
      'team': _team,
      'group': _group,
      'assignedTo': _assignedTo,
      'caseOrigin': _caseOrigin,
      'allocationType': _allocationType,
      'isEscalated': _isEscalated,
      'allocateInventory': _allocateInventory,
      'dueDate': _dueDate != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(_dueDate!)
          : null,
    };

    // API: replace below with createTicket / updateTicket call
    // if (_isEdit) {
    //   await _apiService.updateTicket(widget.existingTicket!.id, payload);
    // } else {
    //   await _apiService.createTicket(payload);
    // }
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _submitting = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEdit ? 'Ticket updated!' : 'Ticket created successfully!',
        ),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDateTimePicker(context);
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'Edit Ticket'
              : _isQuick
              ? '⚡ Quick Case'
              : 'New Ticket',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isQuick)
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateTicketPage(quickMode: false),
                ),
              ),
              child: const Text(
                'Advanced',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_isQuick) ...[
                // ── QUICK MODE ──────────────────────────────────────
                _buildSection('Customer', [
                  _buildTextField(
                    _subscriberName,
                    'Customer / Subscriber Name *',
                    Icons.person,
                    required: true,
                  ),
                  _buildTextField(
                    _subscriberMobile,
                    'Mobile Number',
                    Icons.phone,
                    type: TextInputType.phone,
                  ),
                ]),
                _buildSection('Issue', [
                  _buildDropdown(
                    'Case Reason / Category',
                    kIssueCategories,
                    _category,
                    Icons.category,
                    (v) => setState(() => _category = v!),
                  ),
                  // Title same as remark checkbox
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Title same as Remark',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _titleSameAsRemark,
                    activeColor: teal,
                    onChanged: (v) {
                      setState(() {
                        _titleSameAsRemark = v!;
                        if (_titleSameAsRemark) {
                          _title.text = _remark.text;
                        }
                      });
                    },
                  ),
                  if (!_titleSameAsRemark)
                    _buildTextField(
                      _title,
                      'Title *',
                      Icons.title,
                      required: true,
                    ),
                  _buildTextField(
                    _remark,
                    'Remarks *',
                    Icons.notes,
                    required: true,
                    maxLines: 3,
                    onChanged: (v) {
                      if (_titleSameAsRemark) {
                        setState(() => _title.text = v);
                      }
                    },
                  ),
                ]),
              ] else ...[
                // ── ADVANCED MODE ───────────────────────────────────
                _buildSection('Subscriber Info', [
                  _buildTextField(
                    _subscriberName,
                    'Customer / Subscriber Name *',
                    Icons.person,
                    required: true,
                  ),
                  _buildTextField(
                    _subscriberMobile,
                    'Mobile Number *',
                    Icons.phone,
                    type: TextInputType.phone,
                    required: true,
                  ),
                  _buildTextField(
                    _altMobile,
                    'Alternate Mobile',
                    Icons.phone_forwarded,
                    type: TextInputType.phone,
                  ),
                ]),
                _buildSection('Case Details', [
                  _buildDropdown(
                    'Case Reason / Category *',
                    kIssueCategories,
                    _category,
                    Icons.category,
                    (v) => setState(() => _category = v!),
                  ),
                  _buildDropdown(
                    'Case Origin',
                    kCaseOrigins,
                    _caseOrigin,
                    Icons.login,
                    (v) => setState(() => _caseOrigin = v!),
                  ),
                  // Title same as remark
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Title same as Remark',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _titleSameAsRemark,
                    activeColor: teal,
                    onChanged: (v) {
                      setState(() {
                        _titleSameAsRemark = v!;
                        if (_titleSameAsRemark) _title.text = _remark.text;
                      });
                    },
                  ),
                  if (!_titleSameAsRemark)
                    _buildTextField(
                      _title,
                      'Title *',
                      Icons.title,
                      required: true,
                    ),
                  _buildTextField(
                    _remark,
                    'Remarks *',
                    Icons.notes,
                    required: true,
                    maxLines: 3,
                    onChanged: (v) {
                      if (_titleSameAsRemark) setState(() => _title.text = v);
                    },
                  ),
                ]),
                _buildSection('Priority & Status', [
                  _buildDropdown(
                    'Priority',
                    ['High', 'Medium', 'Low'],
                    _priority,
                    Icons.flag,
                    (v) => setState(() => _priority = v!),
                  ),
                  _buildDropdown(
                    'Status',
                    ['Open', 'In Progress', 'Resolved', 'Closed'],
                    _status,
                    Icons.toggle_on,
                    (v) => setState(() => _status = v!),
                  ),
                  // ETR / Due date
                  _DateTimePick(
                    label: 'ETR / Due Date',
                    value: _dueDate,
                    onTap: _pickDueDate,
                    teal: teal,
                    light: light,
                    blue: blue,
                  ),
                ]),
                _buildSection('Allocation', [
                  _buildDropdown(
                    'Team',
                    kTeams,
                    _team,
                    Icons.group,
                    (v) => setState(() => _team = v!),
                  ),
                  _buildDropdown(
                    'Group',
                    kGroups,
                    _group,
                    Icons.grid_view,
                    (v) => setState(() => _group = v!),
                  ),
                  _buildDropdown(
                    'Assign To',
                    ['', ...kStaff],
                    _assignedTo,
                    Icons.engineering,
                    (v) => setState(() => _assignedTo = v ?? ''),
                  ),
                  _buildDropdown(
                    'Allocation Type',
                    kAllocTypes,
                    _allocationType,
                    Icons.alt_route,
                    (v) => setState(() => _allocationType = v!),
                  ),
                ]),
                _buildSection('Flags', [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Escalate this ticket',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      'Mark as urgent priority',
                      style: TextStyle(fontSize: 11, color: light),
                    ),
                    value: _isEscalated,
                    activeThumbColor: const Color(0xFFE53935),
                    onChanged: (v) => setState(() => _isEscalated = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Allocate Inventory',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      'Track hardware/parts used',
                      style: TextStyle(fontSize: 11, color: light),
                    ),
                    value: _allocateInventory,
                    activeThumbColor: teal,
                    onChanged: (v) => setState(() => _allocateInventory = v),
                  ),
                ]),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_isEdit ? Icons.save : Icons.add_circle),
                  label: Text(
                    _isEdit
                        ? 'Save Changes'
                        : _isQuick
                        ? 'Create Quick Case'
                        : 'Create Ticket',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Form helpers ───
  Widget _buildSection(String title, List<Widget> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: blue,
              ),
            ),
            const Divider(height: 14),
            ...fields.expand((w) => [w, const SizedBox(height: 12)]).toList()
              ..removeLast(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    bool required = false,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: required
          ? (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null
          : null,
      decoration: _deco(label, icon),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> opts,
    String val,
    IconData icon,
    void Function(String?)? onChange,
  ) {
    final dropdownVal = opts.contains(val) ? val : opts.first;
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: dropdownVal,
      onChanged: onChange,
      decoration: _deco(label, icon),
      items: opts
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(
                o.isEmpty ? '— Unassigned —' : o,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          )
          .toList(),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontSize: 13, color: light),
    prefixIcon: Icon(icon, size: 18, color: teal),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: light.withValues(alpha: 0.25)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: light.withValues(alpha: 0.25)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: blue, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}

class _DateTimePick extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final Color teal, light, blue;
  const _DateTimePick({
    required this.label,
    required this.value,
    required this.onTap,
    required this.teal,
    required this.light,
    required this.blue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: value != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(value!)
                : '',
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: 13, color: light),
            prefixIcon: Icon(Icons.timer_outlined, size: 18, color: teal),
            suffixIcon: Icon(Icons.arrow_drop_down, color: light),
            hintText: 'Select date & time',
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: light.withValues(alpha: 0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: light.withValues(alpha: 0.25)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Date+Time picker helper ───
Future<DateTime?> showDateTimePicker(BuildContext context) async {
  final date = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1E407A),
          secondary: Color(0xFF30A8B5),
        ),
      ),
      child: child!,
    ),
  );
  if (date == null) return null;
  if (!context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
