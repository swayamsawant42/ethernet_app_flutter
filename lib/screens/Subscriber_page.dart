import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════════════

class Subscriber {
  final String id;
  // 1. Personal Details
  final String name;
  final String username;
  final String mobile;
  final String email;
  final String address;
  final String city;
  final String district;
  final String state;
  final String pinCode;
  final String gender;
  final String dateOfBirth;
  final String status; // Active / Inactive
  final String? profileImageUrl;

  // 2. Connection & Network
  final String connectivityType; // Fiber / Wireless / P2P
  final String macAddress;
  final String ipAddress;
  final String onuSerial;
  final String onuBrand;
  final String routerType;
  final String vlanId;
  final String latitude;
  final String longitude;
  final String installationDate;
  final String signalStrength;
  final String area;
  final String zone;
  final String route;

  // 3. Plan & Usage
  final String accountNumber;
  final String planName;
  final String bandwidth;
  final String balance;
  final String expiryDate;
  final String creationDate;
  final String dataUsed;
  final String startDate;

  // 4. eKYC / Docs
  final String documentType;
  final String documentNumber;
  final String kycStatus; // Verified / Pending
  final String salesRep;
  final String remarks;

  // Payment History
  final List<Map<String, dynamic>> paymentHistory;

  // Documents
  final List<Map<String, dynamic>> documents;

  Subscriber({
    required this.id,
    required this.name,
    this.username = '',
    required this.mobile,
    this.email = '',
    this.address = '',
    this.city = '',
    this.district = '',
    this.state = '',
    this.pinCode = '',
    this.gender = '',
    this.dateOfBirth = '',
    required this.status,
    this.profileImageUrl,
    this.connectivityType = '',
    this.macAddress = '',
    this.ipAddress = '',
    this.onuSerial = '',
    this.onuBrand = '',
    this.routerType = '',
    this.vlanId = '',
    this.latitude = '',
    this.longitude = '',
    this.installationDate = '',
    this.signalStrength = '',
    this.area = '',
    this.zone = '',
    this.route = '',
    required this.accountNumber,
    required this.planName,
    this.bandwidth = '',
    this.balance = '0',
    required this.expiryDate,
    this.creationDate = '',
    this.dataUsed = '',
    this.startDate = '',
    this.documentType = '',
    this.documentNumber = '',
    this.kycStatus = 'Pending',
    this.salesRep = '',
    this.remarks = '',
    this.paymentHistory = const [],
    this.documents = const [],
  });

  factory Subscriber.fromMap(Map<String, dynamic> m) => Subscriber(
    id: m['id'] ?? '',
    name: m['name'] ?? '',
    username: m['username'] ?? '',
    mobile: m['mobile'] ?? m['phone'] ?? '',
    email: m['email'] ?? '',
    address: m['address'] ?? '',
    city: m['city'] ?? '',
    district: m['district'] ?? '',
    state: m['state'] ?? '',
    pinCode: m['pinCode'] ?? '',
    gender: m['gender'] ?? '',
    dateOfBirth: m['dateOfBirth'] ?? '',
    status: m['status'] ?? 'Active',
    profileImageUrl: m['profileImageUrl'],
    connectivityType: m['connectivityType'] ?? '',
    macAddress: m['macAddress'] ?? '',
    ipAddress: m['ipAddress'] ?? '',
    onuSerial: m['onuSerial'] ?? '',
    onuBrand: m['onuBrand'] ?? '',
    routerType: m['routerType'] ?? '',
    vlanId: m['vlanId'] ?? '',
    latitude: m['latitude'] ?? '',
    longitude: m['longitude'] ?? '',
    installationDate: m['installationDate'] ?? '',
    signalStrength: m['signalStrength'] ?? '',
    area: m['area'] ?? '',
    zone: m['zone'] ?? '',
    route: m['route'] ?? '',
    accountNumber: m['accountNumber'] ?? '',
    planName: m['planName'] ?? m['plan'] ?? '',
    bandwidth: m['bandwidth'] ?? '',
    balance: m['balance']?.toString() ?? '0',
    expiryDate: m['expiryDate'] ?? '',
    creationDate: m['creationDate'] ?? '',
    dataUsed: m['dataUsed'] ?? '',
    startDate: m['startDate'] ?? '',
    documentType: m['documentType'] ?? '',
    documentNumber: m['documentNumber'] ?? '',
    kycStatus: m['kycStatus'] ?? 'Pending',
    salesRep: m['salesRep'] ?? '',
    remarks: m['remarks'] ?? '',
    paymentHistory: List<Map<String, dynamic>>.from(m['paymentHistory'] ?? []),
    documents: List<Map<String, dynamic>>.from(m['documents'] ?? []),
  );
}

// ═══════════════════════════════════════════════════════════════
//  MOCK DATA
// ═══════════════════════════════════════════════════════════════

final List<Subscriber> _mockSubscribers = [
  Subscriber(
    id: '1',
    name: 'NEW KANTARA HOTEL',
    username: 'kantara_hotel',
    mobile: '9876543210',
    email: 'kantara@example.com',
    address: '12, MG Road',
    city: 'Bengaluru',
    district: 'Bengaluru Urban',
    state: 'Karnataka',
    pinCode: '560001',
    gender: 'Other',
    dateOfBirth: '',
    status: 'Active',
    connectivityType: 'Fiber',
    macAddress: 'AA:BB:CC:DD:EE:01',
    ipAddress: '192.168.1.101',
    onuSerial: 'HWTC1234ABCD',
    onuBrand: 'Huawei',
    routerType: 'Dual Band 2.4GHz and 5GHz',
    vlanId: '100',
    latitude: '12.9716',
    longitude: '77.5946',
    installationDate: '2023-06-15',
    signalStrength: 'RX: -18 dBm / TX: +2 dBm',
    area: 'MG Road',
    zone: 'Zone A',
    route: 'Route 1',
    accountNumber: 'H67560',
    planName: '720 - 100Mbps Unlimited',
    bandwidth: '100 Mbps Up/Down',
    balance: '0',
    expiryDate: '2025-06-30',
    creationDate: '2023-06-15',
    dataUsed: '450 GB',
    startDate: '2023-06-15',
    documentType: 'Aadhar',
    documentNumber: '1234-5678-9012',
    kycStatus: 'Verified',
    salesRep: 'Rajesh Kumar',
    remarks: 'VIP client. Prioritize support.',
    paymentHistory: [
      {
        'date': '2025-05-01',
        'amount': '720',
        'method': 'UPI',
        'status': 'Paid',
        'ref': 'UPI2025050112345',
      },
      {
        'date': '2025-04-01',
        'amount': '720',
        'method': 'Cash',
        'status': 'Paid',
        'ref': 'CASH20250401',
      },
      {
        'date': '2025-03-01',
        'amount': '720',
        'method': 'UPI',
        'status': 'Paid',
        'ref': 'UPI2025030198765',
      },
    ],
    documents: [
      {
        'name': 'Aadhar Card',
        'type': 'ID Proof',
        'uploadedOn': '2023-06-15',
        'verified': true,
      },
      {
        'name': 'Shop License',
        'type': 'Business Proof',
        'uploadedOn': '2023-06-15',
        'verified': true,
      },
    ],
  ),
  Subscriber(
    id: '2',
    name: 'Sunita Patil',
    username: 'sunita_patil',
    mobile: '9123456780',
    email: 'sunita@example.com',
    address: '45, Shivaji Nagar',
    city: 'Pune',
    district: 'Pune',
    state: 'Maharashtra',
    pinCode: '411005',
    gender: 'Female',
    status: 'Inactive',
    connectivityType: 'Wireless',
    macAddress: 'AA:BB:CC:DD:EE:02',
    ipAddress: '192.168.1.102',
    area: 'Shivaji Nagar',
    zone: 'Zone B',
    route: 'Route 3',
    accountNumber: 'H67561',
    planName: 'Silver - 50Mbps',
    bandwidth: '50 Mbps Up/Down',
    balance: '500',
    expiryDate: '2024-05-31',
    creationDate: '2023-05-01',
    dataUsed: '120 GB',
    kycStatus: 'Pending',
    salesRep: 'Meena Sharma',
    paymentHistory: [
      {
        'date': '2024-05-01',
        'amount': '499',
        'method': 'Cash',
        'status': 'Paid',
        'ref': 'CASH20240501',
      },
      {
        'date': '2024-04-01',
        'amount': '499',
        'method': 'UPI',
        'status': 'Overdue',
        'ref': '-',
      },
    ],
    documents: [],
  ),
  Subscriber(
    id: '3',
    name: 'Arjun Mehta',
    username: 'arjun_m',
    mobile: '9988776655',
    email: 'arjun@example.com',
    address: '7, Civil Lines',
    city: 'Nagpur',
    district: 'Nagpur',
    state: 'Maharashtra',
    pinCode: '440001',
    gender: 'Male',
    status: 'Active',
    connectivityType: 'Fiber',
    macAddress: 'AA:BB:CC:DD:EE:03',
    ipAddress: '192.168.1.103',
    area: 'Civil Lines',
    zone: 'Zone A',
    route: 'Route 2',
    accountNumber: 'H67562',
    planName: 'Gold - 200Mbps',
    bandwidth: '200 Mbps Up/Down',
    balance: '0',
    expiryDate: '2025-09-09',
    creationDate: '2024-03-10',
    dataUsed: '900 GB',
    kycStatus: 'Verified',
    salesRep: 'Rajesh Kumar',
    remarks: 'Referred by Kantara Hotel',
    paymentHistory: [
      {
        'date': '2025-05-01',
        'amount': '1299',
        'method': 'Online',
        'status': 'Paid',
        'ref': 'ONL20250501001',
      },
      {
        'date': '2025-04-01',
        'amount': '1299',
        'method': 'Online',
        'status': 'Paid',
        'ref': 'ONL20250401001',
      },
    ],
    documents: [
      {
        'name': 'PAN Card',
        'type': 'ID Proof',
        'uploadedOn': '2024-03-10',
        'verified': true,
      },
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════
//  BRAND COLOURS (shared mixin pattern)
// ═══════════════════════════════════════════════════════════════

mixin _BrandColors {
  Color get exPrimaryBlue => const Color(0xFF1E407A);
  Color get exPrimaryTeal => const Color(0xFF30A8B5);
  Color get exLightBg => const Color(0xFFF7F9FA);
  Color get exDarkText => const Color(0xFF2E2E2E);
  Color get exLightText => const Color(0xFF6C6C6C);
}

String _fmtDate(String d) {
  try {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(d));
  } catch (_) {
    return d.isEmpty ? '—' : d;
  }
}

// ═══════════════════════════════════════════════════════════════
//  SUBSCRIBER LIST PAGE
// ═══════════════════════════════════════════════════════════════

class SubscriberPage extends StatefulWidget {
  const SubscriberPage({super.key});
  @override
  State<SubscriberPage> createState() => _SubscriberPageState();
}

class _SubscriberPageState extends State<SubscriberPage> with _BrandColors {
  List<Subscriber> _all = [];
  List<Subscriber> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _statusFilter = 'All';
  String _kycFilter = 'All';

  final List<String> _statusOpts = ['All', 'Active', 'Inactive'];
  final List<String> _kycOpts = ['All', 'Verified', 'Pending'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: replace with → final list = await _apiService.getSubscribers();
    setState(() {
      _all = _mockSubscribers;
      _filter();
      _loading = false;
    });
  }

  void _filter() {
    _filtered = _all.where((s) {
      final q = _search.toLowerCase();
      final matchQ =
          s.name.toLowerCase().contains(q) ||
          s.mobile.contains(q) ||
          s.accountNumber.toLowerCase().contains(q) ||
          s.planName.toLowerCase().contains(q) ||
          s.area.toLowerCase().contains(q);
      final matchS = _statusFilter == 'All' || s.status == _statusFilter;
      final matchK = _kycFilter == 'All' || s.kycStatus == _kycFilter;
      return matchQ && matchS && matchK;
    }).toList();
  }

  void _go(Subscriber s) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SubscriberDetailPage(subscriber: s)),
    ).then((_) => _load());
  }

  void _addNew() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditSubscriberPage()),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: exLightBg,
      appBar: AppBar(
        title: const Text(
          'SUBSCRIBERS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: exPrimaryBlue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: exPrimaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text(
          'Add Subscriber',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _addNew,
      ),
      body: Column(
        children: [
          _TopBar(
            onSearch: (q) => setState(() {
              _search = q;
              _filter();
            }),
            statusFilter: _statusFilter,
            kycFilter: _kycFilter,
            onStatusChanged: (v) => setState(() {
              _statusFilter = v;
              _filter();
            }),
            onKycChanged: (v) => setState(() {
              _kycFilter = v;
              _filter();
            }),
            statusOpts: _statusOpts,
            kycOpts: _kycOpts,
            totalCount: _all.length,
            filteredCount: _filtered.length,
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: exPrimaryTeal))
                : _filtered.isEmpty
                ? _EmptyState(teal: exPrimaryTeal, light: exLightText)
                : RefreshIndicator(
                    color: exPrimaryTeal,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _SubscriberCard(
                        s: _filtered[i],
                        onTap: () => _go(_filtered[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Top search + filter bar ───
class _TopBar extends StatelessWidget with _BrandColors {
  final void Function(String) onSearch;
  final String statusFilter;
  final String kycFilter;
  final void Function(String) onStatusChanged;
  final void Function(String) onKycChanged;
  final List<String> statusOpts;
  final List<String> kycOpts;
  final int totalCount;
  final int filteredCount;

  const _TopBar({
    required this.onSearch,
    required this.statusFilter,
    required this.kycFilter,
    required this.onStatusChanged,
    required this.onKycChanged,
    required this.statusOpts,
    required this.kycOpts,
    required this.totalCount,
    required this.filteredCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search name, mobile, account, plan, area…',
              hintStyle: TextStyle(fontSize: 13, color: exLightText),
              prefixIcon: Icon(Icons.search, color: exPrimaryTeal, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: exLightText.withOpacity(0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: exLightText.withOpacity(0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: exPrimaryBlue, width: 1.8),
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
                Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 12,
                    color: exLightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                ...statusOpts.map(
                  (o) => _Chip(
                    label: o,
                    selected: statusFilter == o,
                    teal: exPrimaryTeal,
                    light: exLightText,
                    onTap: () => onStatusChanged(o),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'KYC:',
                  style: TextStyle(
                    fontSize: 12,
                    color: exLightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                ...kycOpts.map(
                  (o) => _Chip(
                    label: o,
                    selected: kycFilter == o,
                    teal: exPrimaryTeal,
                    light: exLightText,
                    onTap: () => onKycChanged(o),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Showing $filteredCount of $totalCount subscribers',
            style: TextStyle(fontSize: 11, color: exLightText),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color teal;
  final Color light;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.teal,
    required this.light,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? teal.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? teal : light.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? teal : light,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── Subscriber card in list ───
class _SubscriberCard extends StatelessWidget with _BrandColors {
  final Subscriber s;
  final VoidCallback onTap;
  const _SubscriberCard({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = s.status == 'Active';
    final expiryDt = DateTime.tryParse(s.expiryDate);
    final daysLeft = expiryDt?.difference(DateTime.now()).inDays;
    final expiringSoon = daysLeft != null && daysLeft >= 0 && daysLeft <= 10;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: exPrimaryBlue.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isActive
                        ? exPrimaryBlue
                        : exLightText.withOpacity(0.3),
                    child: Text(
                      s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
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
                            Expanded(
                              child: Text(
                                s.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: exDarkText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _statusBadge(s.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 12, color: exLightText),
                            const SizedBox(width: 3),
                            Text(
                              s.mobile,
                              style: TextStyle(
                                fontSize: 12,
                                color: exLightText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.confirmation_number,
                              size: 12,
                              color: exLightText,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              s.accountNumber,
                              style: TextStyle(
                                fontSize: 12,
                                color: exLightText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: exLightText, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              // Plan & expiry row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: exLightBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi, size: 14, color: exPrimaryTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.planName,
                        style: TextStyle(
                          fontSize: 12,
                          color: exPrimaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (expiringSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange, width: 0.8),
                        ),
                        child: Text(
                          'Expires in $daysLeft days',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Exp: ${_fmtDate(s.expiryDate)}',
                        style: TextStyle(fontSize: 11, color: exLightText),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Area / KYC / connection row
              Row(
                children: [
                  Icon(Icons.location_on, size: 12, color: exLightText),
                  const SizedBox(width: 4),
                  Text(
                    '${s.area} • ${s.zone}',
                    style: TextStyle(fontSize: 11, color: exLightText),
                  ),
                  const Spacer(),
                  _kycBadge(s.kycStatus),
                  const SizedBox(width: 6),
                  _connBadge(s.connectivityType),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String st) {
    final ok = st == 'Active';
    return _badge(st, ok ? Colors.green : Colors.grey);
  }

  Widget _kycBadge(String st) {
    final ok = st == 'Verified';
    return _badge(st, ok ? Colors.blue : Colors.orange);
  }

  Widget _connBadge(String ct) {
    return _badge(ct, exPrimaryTeal);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 0.7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color teal, light;
  const _EmptyState({required this.teal, required this.light});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 64, color: light),
        const SizedBox(height: 12),
        Text(
          'No subscribers found',
          style: TextStyle(
            fontSize: 16,
            color: light,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Try adjusting filters',
          style: TextStyle(fontSize: 13, color: light),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  SUBSCRIBER DETAIL PAGE  (Tabbed)
// ═══════════════════════════════════════════════════════════════

class SubscriberDetailPage extends StatefulWidget {
  final Subscriber subscriber;
  const SubscriberDetailPage({super.key, required this.subscriber});
  @override
  State<SubscriberDetailPage> createState() => _SubscriberDetailPageState();
}

class _SubscriberDetailPageState extends State<SubscriberDetailPage>
    with _BrandColors, SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subscriber;
    return Scaffold(
      backgroundColor: exLightBg,
      appBar: AppBar(
        title: Text(
          s.name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: exPrimaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditSubscriberPage(subscriber: s),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          indicatorColor: exPrimaryTeal,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'PERSONAL'),
            Tab(text: 'CONNECTION'),
            Tab(text: 'PLAN & USAGE'),
            Tab(text: 'PAYMENTS'),
            Tab(text: 'DOCS & KYC'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _PersonalTab(s: s),
          _ConnectionTab(s: s),
          _PlanTab(s: s),
          _PaymentsTab(s: s),
          _DocsKycTab(s: s),
        ],
      ),
    );
  }
}

// ─── Tab 1: Personal ───
class _PersonalTab extends StatelessWidget with _BrandColors {
  final Subscriber s;
  const _PersonalTab({required this.s});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile header
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: exPrimaryBlue,
                    child: Text(
                      s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: exDarkText,
                          ),
                        ),
                        if (s.username.isNotEmpty)
                          Text(
                            '@${s.username}',
                            style: TextStyle(
                              fontSize: 13,
                              color: exPrimaryTeal,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _StatusPill(s.status),
                            const SizedBox(width: 6),
                            _StatusPill(
                              s.kycStatus,
                              color: s.kycStatus == 'Verified'
                                  ? Colors.blue
                                  : Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Contact Information',
            rows: [
              _Row(Icons.phone, 'Mobile', s.mobile),
              _Row(Icons.email, 'Email', s.email.isEmpty ? '—' : s.email),
              _Row(
                Icons.location_on,
                'Address',
                s.address.isEmpty ? '—' : s.address,
              ),
              _Row(
                Icons.location_city,
                'City / District',
                '${s.city}, ${s.district}'.replaceAll(RegExp(r'^, |, $'), ''),
              ),
              _Row(Icons.map, 'State', s.state.isEmpty ? '—' : s.state),
              _Row(
                Icons.local_post_office,
                'PIN Code',
                s.pinCode.isEmpty ? '—' : s.pinCode,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Personal Info',
            rows: [
              _Row(Icons.wc, 'Gender', s.gender.isEmpty ? '—' : s.gender),
              _Row(
                Icons.cake,
                'Date of Birth',
                s.dateOfBirth.isEmpty ? '—' : _fmtDate(s.dateOfBirth),
              ),
            ],
          ),
          if (s.remarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Remarks',
              rows: [_Row(Icons.notes, 'Remarks', s.remarks)],
            ),
          ],
          if (s.salesRep.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Sales',
              rows: [
                _Row(Icons.person_pin, 'Sales Representative', s.salesRep),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tab 2: Connection ───
class _ConnectionTab extends StatelessWidget with _BrandColors {
  final Subscriber s;
  const _ConnectionTab({required this.s});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _InfoCard(
            title: 'Network Identity',
            rows: [
              _Row(
                Icons.wifi,
                'Connectivity Type',
                s.connectivityType.isEmpty ? '—' : s.connectivityType,
              ),
              _Row(
                Icons.memory,
                'MAC Address',
                s.macAddress.isEmpty ? '—' : s.macAddress,
              ),
              _Row(
                Icons.router,
                'IP Address',
                s.ipAddress.isEmpty ? '—' : s.ipAddress,
              ),
              _Row(
                Icons.settings_ethernet,
                'VLAN ID',
                s.vlanId.isEmpty ? '—' : s.vlanId,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Hardware',
            rows: [
              _Row(
                Icons.device_hub,
                'ONU/ONT Serial',
                s.onuSerial.isEmpty ? '—' : s.onuSerial,
              ),
              _Row(
                Icons.business,
                'ONU Brand',
                s.onuBrand.isEmpty ? '—' : s.onuBrand,
              ),
              _Row(
                Icons.router,
                'Router Type',
                s.routerType.isEmpty ? '—' : s.routerType,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Location & Signal',
            rows: [
              _Row(
                Icons.gps_fixed,
                'Latitude',
                s.latitude.isEmpty ? '—' : s.latitude,
              ),
              _Row(
                Icons.gps_fixed,
                'Longitude',
                s.longitude.isEmpty ? '—' : s.longitude,
              ),
              _Row(
                Icons.signal_cellular_alt,
                'Signal Strength',
                s.signalStrength.isEmpty ? '—' : s.signalStrength,
              ),
              _Row(
                Icons.calendar_today,
                'Installation Date',
                s.installationDate.isEmpty ? '—' : _fmtDate(s.installationDate),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Area Assignment',
            rows: [
              _Row(Icons.location_city, 'Area', s.area.isEmpty ? '—' : s.area),
              _Row(Icons.grid_view, 'Zone', s.zone.isEmpty ? '—' : s.zone),
              _Row(Icons.alt_route, 'Route', s.route.isEmpty ? '—' : s.route),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Plan & Usage ───
class _PlanTab extends StatelessWidget with _BrandColors {
  final Subscriber s;
  const _PlanTab({required this.s});

  @override
  Widget build(BuildContext context) {
    final expiryDt = DateTime.tryParse(s.expiryDate);
    final daysLeft = expiryDt?.difference(DateTime.now()).inDays;
    final expiringSoon = daysLeft != null && daysLeft >= 0 && daysLeft <= 10;
    final expired = daysLeft != null && daysLeft < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Plan highlight card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: exPrimaryBlue,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.planName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.bandwidth,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _PlanStat('Account', s.accountNumber, Colors.white),
                      _PlanStat(
                        'Balance',
                        '₹${s.balance}',
                        s.balance == '0'
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                      _PlanStat(
                        'Data Used',
                        s.dataUsed.isEmpty ? '—' : s.dataUsed,
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Expiry alert
          if (expiringSoon || expired)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: expired
                    ? Colors.red.withOpacity(0.08)
                    : Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: expired ? Colors.red : Colors.orange,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: expired ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      expired
                          ? 'Plan has expired. Please renew immediately.'
                          : 'Plan expiring in $daysLeft days!',
                      style: TextStyle(
                        color: expired ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _InfoCard(
            title: 'Dates',
            rows: [
              _Row(
                Icons.calendar_today,
                'Start Date',
                s.startDate.isEmpty ? '—' : _fmtDate(s.startDate),
              ),
              _Row(
                Icons.event,
                'Expiry Date',
                s.expiryDate.isEmpty ? '—' : _fmtDate(s.expiryDate),
              ),
              _Row(
                Icons.add_circle_outline,
                'Account Created',
                s.creationDate.isEmpty ? '—' : _fmtDate(s.creationDate),
              ),
              _Row(
                Icons.calendar_month,
                'Installation',
                s.installationDate.isEmpty ? '—' : _fmtDate(s.installationDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _PlanStat(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 4: Payments ───
class _PaymentsTab extends StatelessWidget with _BrandColors {
  final Subscriber s;
  const _PaymentsTab({required this.s});

  @override
  Widget build(BuildContext context) {
    final history = s.paymentHistory;

    return history.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 50, color: exLightText),
                const SizedBox(height: 8),
                Text(
                  'No payment records found',
                  style: TextStyle(color: exLightText, fontSize: 14),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                // Summary
                final total = history.fold<double>(
                  0,
                  (sum, p) =>
                      sum + double.tryParse(p['amount']?.toString() ?? '0')!,
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: exPrimaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Paid',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${history.length} transactions',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final p = history[i - 1];
              final isPaid = p['status'] == 'Paid';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: isPaid
                        ? Colors.green.withOpacity(0.12)
                        : Colors.red.withOpacity(0.12),
                    child: Icon(
                      isPaid ? Icons.check : Icons.close,
                      size: 16,
                      color: isPaid ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        '₹${p['amount']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: exDarkText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p['method'] ?? '',
                        style: TextStyle(fontSize: 12, color: exLightText),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fmtDate(p['date'] ?? ''),
                        style: TextStyle(fontSize: 12, color: exLightText),
                      ),
                      if ((p['ref'] ?? '-') != '-')
                        Text(
                          'Ref: ${p['ref']}',
                          style: TextStyle(fontSize: 11, color: exLightText),
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPaid ? Colors.green : Colors.red,
                        width: 0.7,
                      ),
                    ),
                    child: Text(
                      p['status'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: isPaid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }
}

// ─── Tab 5: Docs & KYC ───
class _DocsKycTab extends StatelessWidget with _BrandColors {
  final Subscriber s;
  const _DocsKycTab({required this.s});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // KYC status card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: s.kycStatus == 'Verified'
                        ? Colors.blue.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    child: Icon(
                      s.kycStatus == 'Verified'
                          ? Icons.verified_user
                          : Icons.hourglass_top,
                      color: s.kycStatus == 'Verified'
                          ? Colors.blue
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KYC Status',
                        style: TextStyle(fontSize: 12, color: exLightText),
                      ),
                      Text(
                        s.kycStatus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: s.kycStatus == 'Verified'
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Document Details',
            rows: [
              _Row(
                Icons.badge,
                'Document Type',
                s.documentType.isEmpty ? '—' : s.documentType,
              ),
              _Row(
                Icons.numbers,
                'Document Number',
                s.documentNumber.isEmpty ? '—' : s.documentNumber,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Uploaded docs list
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Uploaded Documents',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: exPrimaryBlue,
                        ),
                      ),
                      const Spacer(),
                      // TODO: hook to file picker + upload API
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Upload feature coming soon!'),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.upload_file,
                          size: 16,
                          color: exPrimaryTeal,
                        ),
                        label: Text(
                          'Upload',
                          style: TextStyle(fontSize: 12, color: exPrimaryTeal),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  if (s.documents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.folder_open, color: exLightText),
                          const SizedBox(width: 8),
                          Text(
                            'No documents uploaded',
                            style: TextStyle(color: exLightText, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    ...s.documents.map(
                      (d) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: exPrimaryBlue.withOpacity(0.1),
                          child: Icon(
                            Icons.description,
                            size: 16,
                            color: exPrimaryBlue,
                          ),
                        ),
                        title: Text(
                          d['name'] ?? '',
                          style: TextStyle(fontSize: 13, color: exDarkText),
                        ),
                        subtitle: Text(
                          '${d['type']} • ${_fmtDate(d['uploadedOn'] ?? '')}',
                          style: TextStyle(fontSize: 11, color: exLightText),
                        ),
                        trailing: d['verified'] == true
                            ? const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 18,
                              )
                            : Icon(
                                Icons.hourglass_top,
                                color: Colors.orange,
                                size: 18,
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Info Card ───
class _InfoCard extends StatelessWidget with _BrandColors {
  final String title;
  final List<Widget> rows;
  const _InfoCard({required this.title, required this.rows});

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
                color: exPrimaryBlue,
              ),
            ),
            const Divider(height: 14),
            ...rows,
          ],
        ),
      ),
    );
  }
}

Widget _Row(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF30A8B5)),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6C6C6C)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2E2E2E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color? color;
  const _StatusPill(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (label == 'Active' ? Colors.green : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ADD / EDIT SUBSCRIBER PAGE
// ═══════════════════════════════════════════════════════════════

class AddEditSubscriberPage extends StatefulWidget {
  final Subscriber? subscriber;
  const AddEditSubscriberPage({super.key, this.subscriber});
  @override
  State<AddEditSubscriberPage> createState() => _AddEditSubscriberPageState();
}

class _AddEditSubscriberPageState extends State<AddEditSubscriberPage>
    with _BrandColors, SingleTickerProviderStateMixin {
  late TabController _tab;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  bool get _isEdit => widget.subscriber != null;

  // ─── Controllers ───
  // Personal
  late TextEditingController _name,
      _username,
      _mobile,
      _email,
      _address,
      _city,
      _district,
      _state,
      _pin,
      _dob;
  String _gender = 'Male';
  String _status = 'Active';

  // Connection
  late TextEditingController _connType,
      _mac,
      _ip,
      _onuSerial,
      _onuBrand,
      _router,
      _vlan,
      _lat,
      _lng,
      _signal;
  String _area = '', _zone = '', _route = '';
  DateTime? _installDate;

  // Plan
  late TextEditingController _accountNo, _plan, _bandwidth, _balance, _dataUsed;
  String _planStatus = 'Active';
  DateTime? _startDate, _expiryDate;

  // KYC
  late TextEditingController _docType, _docNumber, _salesRep, _remarks;
  String _kycStatus = 'Pending';

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _statuses = ['Active', 'Inactive', 'Suspended'];
  final List<String> _kycStatuses = ['Verified', 'Pending'];
  final List<String> _connTypes = ['Fiber', 'Wireless', 'P2P', 'Cable'];
  final List<String> _docTypes = [
    'Aadhar',
    'PAN',
    'Voter ID',
    'Passport',
    'Driving License',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    final s = widget.subscriber;

    _name = TextEditingController(text: s?.name ?? '');
    _username = TextEditingController(text: s?.username ?? '');
    _mobile = TextEditingController(text: s?.mobile ?? '');
    _email = TextEditingController(text: s?.email ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _city = TextEditingController(text: s?.city ?? '');
    _district = TextEditingController(text: s?.district ?? '');
    _state = TextEditingController(text: s?.state ?? '');
    _pin = TextEditingController(text: s?.pinCode ?? '');
    _dob = TextEditingController(text: s?.dateOfBirth ?? '');

    _gender = s?.gender.isEmpty ?? true ? 'Male' : s!.gender;
    _status = s?.status ?? 'Active';

    _connType = TextEditingController(text: s?.connectivityType ?? '');
    _mac = TextEditingController(text: s?.macAddress ?? '');
    _ip = TextEditingController(text: s?.ipAddress ?? '');
    _onuSerial = TextEditingController(text: s?.onuSerial ?? '');
    _onuBrand = TextEditingController(text: s?.onuBrand ?? '');
    _router = TextEditingController(text: s?.routerType ?? '');
    _vlan = TextEditingController(text: s?.vlanId ?? '');
    _lat = TextEditingController(text: s?.latitude ?? '');
    _lng = TextEditingController(text: s?.longitude ?? '');
    _signal = TextEditingController(text: s?.signalStrength ?? '');
    _area = s?.area ?? '';
    _zone = s?.zone ?? '';
    _route = s?.route ?? '';
    _installDate = s?.installationDate.isNotEmpty == true
        ? DateTime.tryParse(s!.installationDate)
        : null;

    _accountNo = TextEditingController(text: s?.accountNumber ?? '');
    _plan = TextEditingController(text: s?.planName ?? '');
    _bandwidth = TextEditingController(text: s?.bandwidth ?? '');
    _balance = TextEditingController(text: s?.balance ?? '0');
    _dataUsed = TextEditingController(text: s?.dataUsed ?? '');
    _startDate = s?.startDate.isNotEmpty == true
        ? DateTime.tryParse(s!.startDate)
        : null;
    _expiryDate = s?.expiryDate.isNotEmpty == true
        ? DateTime.tryParse(s!.expiryDate)
        : null;

    _docType = TextEditingController(text: s?.documentType ?? '');
    _docNumber = TextEditingController(text: s?.documentNumber ?? '');
    _salesRep = TextEditingController(text: s?.salesRep ?? '');
    _remarks = TextEditingController(text: s?.remarks ?? '');
    _kycStatus = s?.kycStatus ?? 'Pending';
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [
      _name,
      _username,
      _mobile,
      _email,
      _address,
      _city,
      _district,
      _state,
      _pin,
      _dob,
      _connType,
      _mac,
      _ip,
      _onuSerial,
      _onuBrand,
      _router,
      _vlan,
      _lat,
      _lng,
      _signal,
      _accountNo,
      _plan,
      _bandwidth,
      _balance,
      _dataUsed,
      _docType,
      _docNumber,
      _salesRep,
      _remarks,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(
    bool Function(DateTime) setter, {
    DateTime? initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: exPrimaryBlue,
            secondary: exPrimaryTeal,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => setter(picked));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _tab.animateTo(0); // jump to first tab with errors
      return;
    }
    setState(() => _submitting = true);

    final payload = {
      'name': _name.text.trim(),
      'username': _username.text.trim(),
      'mobile': _mobile.text.trim(),
      'email': _email.text.trim(),
      'address': _address.text.trim(),
      'city': _city.text.trim(),
      'district': _district.text.trim(),
      'state': _state.text.trim(),
      'pinCode': _pin.text.trim(),
      'gender': _gender,
      'dateOfBirth': _dob.text.trim(),
      'status': _status,
      'connectivityType': _connType.text.trim(),
      'macAddress': _mac.text.trim(),
      'ipAddress': _ip.text.trim(),
      'onuSerial': _onuSerial.text.trim(),
      'onuBrand': _onuBrand.text.trim(),
      'routerType': _router.text.trim(),
      'vlanId': _vlan.text.trim(),
      'latitude': _lat.text.trim(),
      'longitude': _lng.text.trim(),
      'signalStrength': _signal.text.trim(),
      'installationDate': _installDate != null
          ? DateFormat('yyyy-MM-dd').format(_installDate!)
          : '',
      'area': _area,
      'zone': _zone,
      'route': _route,
      'accountNumber': _accountNo.text.trim(),
      'planName': _plan.text.trim(),
      'bandwidth': _bandwidth.text.trim(),
      'balance': _balance.text.trim(),
      'dataUsed': _dataUsed.text.trim(),
      'startDate': _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : '',
      'expiryDate': _expiryDate != null
          ? DateFormat('yyyy-MM-dd').format(_expiryDate!)
          : '',
      'documentType': _docType.text.trim(),
      'documentNumber': _docNumber.text.trim(),
      'kycStatus': _kycStatus,
      'salesRep': _salesRep.text.trim(),
      'remarks': _remarks.text.trim(),
    };

    // TODO: replace below with API call
    // if (_isEdit) {
    //   await _apiService.updateSubscriber(widget.subscriber!.id, payload);
    // } else {
    //   await _apiService.createSubscriber(payload);
    // }
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _submitting = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEdit ? 'Subscriber updated!' : 'Subscriber created!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: exLightBg,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Subscriber' : 'Add Subscriber',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: exPrimaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          indicatorColor: exPrimaryTeal,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'PERSONAL'),
            Tab(text: 'CONNECTION'),
            Tab(text: 'PLAN'),
            Tab(text: 'KYC & DOCS'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tab,
          children: [
            _buildPersonalForm(),
            _buildConnectionForm(),
            _buildPlanForm(),
            _buildKycForm(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
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
                  : Icon(_isEdit ? Icons.save : Icons.person_add),
              label: Text(
                _isEdit ? 'Save Changes' : 'Add Subscriber',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: exPrimaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Form Tab 1: Personal ───
  Widget _buildPersonalForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _FormSection('Basic Info', [
            _tf(_name, 'Full Name *', Icons.person, required: true),
            _tf(_username, 'Username', Icons.alternate_email),
            _tf(
              _mobile,
              'Mobile Number *',
              Icons.phone,
              type: TextInputType.phone,
              required: true,
            ),
            _tf(_email, 'Email', Icons.email, type: TextInputType.emailAddress),
          ]),
          _FormSection('Address', [
            _tf(_address, 'Address', Icons.location_on, maxLines: 2),
            _tf(_city, 'City', Icons.location_city),
            _tf(_district, 'District', Icons.map),
            _tf(_state, 'State', Icons.flag),
            _tf(
              _pin,
              'PIN Code',
              Icons.local_post_office,
              type: TextInputType.number,
            ),
          ]),
          _FormSection('Additional', [
            _dd(
              'Gender',
              _genders,
              _gender,
              Icons.wc,
              (v) => setState(() => _gender = v!),
            ),
            _tf(_dob, 'Date of Birth (YYYY-MM-DD)', Icons.cake),
            _dd(
              'Status',
              _statuses,
              _status,
              Icons.toggle_on,
              (v) => setState(() => _status = v!),
            ),
          ]),
        ],
      ),
    );
  }

  // ─── Form Tab 2: Connection ───
  Widget _buildConnectionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _FormSection('Network', [
            _dd(
              'Connectivity Type',
              _connTypes,
              _connType.text.isEmpty ? 'Fiber' : _connType.text,
              Icons.wifi,
              (v) => setState(() => _connType.text = v!),
            ),
            _tf(_mac, 'MAC Address', Icons.memory),
            _tf(_ip, 'IP Address', Icons.router),
            _tf(_vlan, 'VLAN ID', Icons.settings_ethernet),
          ]),
          _FormSection('Hardware', [
            _tf(_onuSerial, 'ONU/ONT Serial No.', Icons.device_hub),
            _tf(_onuBrand, 'ONU Brand', Icons.business),
            _tf(_router, 'Router Type / Model', Icons.router),
          ]),
          _FormSection('Location', [
            _tf(_lat, 'Latitude', Icons.gps_fixed, type: TextInputType.number),
            _tf(_lng, 'Longitude', Icons.gps_fixed, type: TextInputType.number),
            _tf(_signal, 'Signal Strength', Icons.signal_cellular_alt),
            _datePicker(
              'Installation Date',
              _installDate,
              () => _pickDate((d) {
                _installDate = d;
                return true;
              }, initial: _installDate),
            ),
          ]),
          _FormSection('Area Assignment', [
            _tf(
              TextEditingController(text: _area),
              'Area',
              Icons.location_city,
              onChanged: (v) => _area = v,
            ),
            _tf(
              TextEditingController(text: _zone),
              'Zone',
              Icons.grid_view,
              onChanged: (v) => _zone = v,
            ),
            _tf(
              TextEditingController(text: _route),
              'Route',
              Icons.alt_route,
              onChanged: (v) => _route = v,
            ),
          ]),
        ],
      ),
    );
  }

  // ─── Form Tab 3: Plan ───
  Widget _buildPlanForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _FormSection('Subscription', [
            _tf(
              _accountNo,
              'Account Number *',
              Icons.confirmation_number,
              required: true,
            ),
            _tf(_plan, 'Plan Name *', Icons.wifi, required: true),
            _tf(_bandwidth, 'Bandwidth', Icons.speed),
            _tf(
              _balance,
              'Outstanding Balance (₹)',
              Icons.account_balance_wallet,
              type: TextInputType.number,
            ),
            _tf(_dataUsed, 'Total Data Used', Icons.data_usage),
          ]),
          _FormSection('Dates', [
            _datePicker(
              'Start Date',
              _startDate,
              () => _pickDate((d) {
                _startDate = d;
                return true;
              }, initial: _startDate),
            ),
            const SizedBox(height: 14),
            _datePicker(
              'Expiry Date',
              _expiryDate,
              () => _pickDate((d) {
                _expiryDate = d;
                return true;
              }, initial: _expiryDate),
            ),
          ]),
        ],
      ),
    );
  }

  // ─── Form Tab 4: KYC ───
  Widget _buildKycForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _FormSection('KYC Verification', [
            _dd(
              'Document Type',
              _docTypes,
              _docType.text.isEmpty ? 'Aadhar' : _docType.text,
              Icons.badge,
              (v) => setState(() => _docType.text = v!),
            ),
            _tf(_docNumber, 'Document Number', Icons.numbers),
            _dd(
              'KYC Status',
              _kycStatuses,
              _kycStatus,
              Icons.verified_user,
              (v) => setState(() => _kycStatus = v!),
            ),
          ]),
          _FormSection('Sales & Remarks', [
            _tf(_salesRep, 'Sales Representative', Icons.person_pin),
            _tf(_remarks, 'Remarks / Notes', Icons.notes, maxLines: 3),
          ]),
          // Document upload placeholder
          Card(
            margin: const EdgeInsets.only(top: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Documents',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: exPrimaryBlue,
                    ),
                  ),
                  const Divider(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: integrate file_picker → upload API
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('File picker — connect to upload API'),
                        ),
                      );
                    },
                    icon: Icon(Icons.upload_file, color: exPrimaryTeal),
                    label: Text(
                      'Choose & Upload Document',
                      style: TextStyle(color: exPrimaryTeal),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: exPrimaryTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Supported: JPG, PNG, PDF',
                    style: TextStyle(fontSize: 11, color: exLightText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Form helpers ───
  Widget _FormSection(String title, List<Widget> fields) {
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
                color: exPrimaryBlue,
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

  Widget _tf(
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
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: _deco(label, icon),
    );
  }

  Widget _dd(
    String label,
    List<String> opts,
    String val,
    IconData icon,
    void Function(String?)? onChange,
  ) {
    return DropdownButtonFormField<String>(
      value: opts.contains(val) ? val : opts.first,
      onChanged: onChange,
      decoration: _deco(label, icon),
      items: opts
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontSize: 13, color: exLightText),
    prefixIcon: Icon(icon, size: 18, color: exPrimaryTeal),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: exLightText.withOpacity(0.25)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: exLightText.withOpacity(0.25)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: exPrimaryBlue, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red),
    ),
    filled: true,
    fillColor: Colors.white,
  );

  Widget _datePicker(String label, DateTime? dt, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: dt != null ? DateFormat('dd MMM yyyy').format(dt) : '',
          ),
          decoration: _deco(label, Icons.calendar_today).copyWith(
            suffixIcon: Icon(Icons.arrow_drop_down, color: exLightText),
            hintText: 'Select date',
          ),
        ),
      ),
    );
  }
}
