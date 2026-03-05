import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/api_service.dart';
import 'expense_tracker.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onSelected;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = color ?? theme.colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: baseColor.withValues(alpha: 0.15),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: selected ? baseColor : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onSelected(),
      side: BorderSide(color: baseColor.withValues(alpha: 0.6)),
    );
  }
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<Expense> _allExpenses = [];
  List<Expense> _visibleExpenses = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _employeCode;
  String? _fallbackEmployeeId;
  String? _profileName;
  int? _userId;
  bool _isFetchingProfile = true;
  String _statusFilter = 'ALL';
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('=== EXPENSE LIST PAGE INITIALIZING ===');
    await _fetchUserProfile();
    if (!mounted) return;
    debugPrint(
      'Profile fetched - Employee Code: $_employeCode, User ID: $_userId, Fallback: $_fallbackEmployeeId',
    );
    // Wait longer for server to process any new expenses after submission
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    debugPrint('Loading expenses...');
    await _loadExpenses(refresh: true);
    debugPrint('Expenses loaded - Total: ${_allExpenses.length}, Visible: ${_visibleExpenses.length}');
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isFetchingProfile = true;
      _errorMessage = null;
    });

    try {
      final profile = await _apiService.getProfile();
      if (!mounted) return;
      setState(() {
        _employeCode = profile?['employeCode']?.toString().trim();
        _fallbackEmployeeId = profile?['employeeId']?.toString().trim();
        _profileName = profile?['name']?.toString().trim();
        final idValue = profile?['id'];
        _userId = idValue is int ? idValue : int.tryParse('$idValue');
        _isFetchingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load profile. Please try again.';
        _isFetchingProfile = false;
      });
    }
  }

  Future<void> _loadExpenses({bool refresh = false}) async {
    if (_isFetchingProfile) return;
    final userId = _userId;

    if (userId == null) {
      setState(() {
        _allExpenses = [];
        _visibleExpenses = [];
        _hasMore = false;
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'Missing user information. Please re-login.';
      });
      return;
    }

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _allExpenses = [];
        _visibleExpenses = [];
      });
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      if (_currentPage == 1) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _errorMessage = null;
    });

    try {
      // Fetch expenses with employeCode filter - backend now handles JSON string filtering
      // Use employeCode if available, otherwise fallback to employeeId
      final codeToSend = _employeCode ?? _fallbackEmployeeId;
      debugPrint('Sending employeCode to backend: $codeToSend (from profile: $_employeCode, fallback: $_fallbackEmployeeId)');
      
      Map<String, dynamic>? responseData = await _apiService.getExpenses(
        page: _currentPage,
        limit: _limit,
        employeCode: codeToSend, // Backend will filter by employeCode in JSON string
      );

      if (!mounted) return;

      ExpenseListResponse? response = responseData != null
          ? ExpenseListResponse.fromResponse(responseData)
          : null;

      if (response != null) {
        final resolvedResponse = response;
        
        // Debug logging
        debugPrint('=== EXPENSE LIST DEBUG ===');
        debugPrint('Total expenses from API: ${resolvedResponse.expenses.length}');
        debugPrint('Current employeCode: $_employeCode');
        debugPrint('Current userId: $userId');
        
        // Print first few expenses for debugging
        for (var i = 0; i < resolvedResponse.expenses.length && i < 3; i++) {
          final exp = resolvedResponse.expenses[i];
          debugPrint('--- Expense ${exp.id} ---');
          debugPrint('  employeCode: "${exp.user?.employeCode}"');
          debugPrint('  name: "${exp.user?.name}"');
          debugPrint('  userId: ${exp.userId}');
          debugPrint('  user.id: ${exp.user?.id}');
          debugPrint('  category: ${exp.category}');
          debugPrint('  amount: ${exp.amount}');
        }
        
        // Smart filtering: Match by userId first, then employeCode, then name
        var expenses = resolvedResponse.expenses.where((expense) {
          // 1. Match by userId (most reliable)
          if (userId != null) {
            if (expense.userId == userId || expense.user?.id == userId) {
              debugPrint('Expense ${expense.id}: Matched by userId: $userId');
              return true;
            }
          }

          // 2. Match by employeCode (case-insensitive)
          final profileCode = _employeCode?.toLowerCase().trim() ?? _fallbackEmployeeId?.toLowerCase().trim();
          if (profileCode != null && profileCode.isNotEmpty) {
            final expenseCode = expense.user?.employeCode?.toLowerCase().trim() ?? 
                               expense.user?.employeeId?.toLowerCase().trim();
            if (expenseCode != null && expenseCode.isNotEmpty) {
              // Match if codes are equal (including "unknown")
              if (expenseCode == profileCode) {
                debugPrint('Expense ${expense.id}: Matched by employeCode: $expenseCode');
                return true;
              }
            }
          }

          // 3. Fallback: Match by name (useful when employeCode is "UNKNOWN" or missing)
          if (_profileName != null && _profileName!.isNotEmpty) {
            final expenseName = expense.user?.name?.toLowerCase().trim();
            if (expenseName != null && expenseName == _profileName!.toLowerCase().trim()) {
              debugPrint('Expense ${expense.id}: Matched by name: $expenseName');
              return true;
            }
          }
          
          debugPrint('Expense ${expense.id}: No match found - FILTERED OUT');
          return false;
        }).toList();
        
        debugPrint('Expenses after filtering: ${expenses.length}');
        debugPrint('=== END DEBUG ===');
        

        setState(() {
          if (refresh || _currentPage == 1) {
            _allExpenses = expenses;
          } else {
            _allExpenses.addAll(expenses);
          }

          final pagination = resolvedResponse.pagination;
          if (pagination != null) {
            _hasMore = pagination.hasMore;
            _currentPage =
                _hasMore ? pagination.nextPage : pagination.page ?? _currentPage;
          } else {
            _hasMore = resolvedResponse.expenses.length >= _limit;
            if (_hasMore) {
              _currentPage++;
            }
          }

          _isLoading = false;
          _isLoadingMore = false;
          _applyFilters();
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load expenses. Please try again.';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading expenses: ${e.toString()}';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpenseTrackerPage()),
    );

    // Refresh the list when returning from add expense screen (only on success)
    if (result == true && mounted) {
      // Ensure profile is loaded before refreshing expenses
      if (_employeCode == null && _fallbackEmployeeId == null) {
        await _fetchUserProfile();
      }

      // Wait a moment for server to process the new expense
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      // Refresh the expense list to show the newly submitted expense
      await _loadExpenses(refresh: true);
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      // Convert to local timezone and format
      final localDate = date.toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(localDate);
    } catch (e) {
      // Fallback if formatting fails
      return date.toString();
    }
  }

  void _applyFilters() {
    final term = _searchTerm.trim().toLowerCase();
    final status = _statusFilter;

    _visibleExpenses = _allExpenses.where((expense) {
      final matchesStatus = status == 'ALL' ||
          (expense.status?.toLowerCase() ?? '') == status.toLowerCase();

      final matchesSearch = term.isEmpty ||
          expense.category?.toLowerCase().contains(term) == true ||
          (expense.user?.displayName.toLowerCase().contains(term) ?? false);

      return matchesStatus && matchesSearch;
    }).toList()
      ..sort((a, b) =>
          (b.date ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.date ?? DateTime.fromMillisecondsSinceEpoch(0)));
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchTerm = value;
        _applyFilters();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final hasExpenses = _visibleExpenses.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_isFetchingProfile) return;
              _loadExpenses(refresh: true);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isFetchingProfile
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _isLoading && _allExpenses.isEmpty
              ? Center(
                  child:
                      CircularProgressIndicator(color: colorScheme.primary),
                )
              : _errorMessage != null && _allExpenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300], // Error color is semantic
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.red[700], // Error color is semantic
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _loadExpenses(refresh: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _allExpenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: colorScheme.onBackground.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses found',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onBackground.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first expense',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onBackground.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: const InputDecoration(
                          hintText: 'Search by category or user',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _StatusChip(
                              label: 'All',
                              selected: _statusFilter == 'ALL',
                              onSelected: () {
                                setState(() {
                                  _statusFilter = 'ALL';
                                  _applyFilters();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(
                              label: 'Pending',
                              selected: _statusFilter == 'PENDING',
                              color: Colors.orange,
                              onSelected: () {
                                setState(() {
                                  _statusFilter = 'PENDING';
                                  _applyFilters();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(
                              label: 'Approved',
                              selected: _statusFilter == 'APPROVED',
                              color: Colors.green,
                              onSelected: () {
                                setState(() {
                                  _statusFilter = 'APPROVED';
                                  _applyFilters();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(
                              label: 'Rejected',
                              selected: _statusFilter == 'REJECTED',
                              color: Colors.red,
                              onSelected: () {
                                setState(() {
                                  _statusFilter = 'REJECTED';
                                  _applyFilters();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadExpenses(refresh: true),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (!_isLoadingMore &&
                            _hasMore &&
                            scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent - 200) {
                          _loadExpenses();
                        }
                        return false;
                      },
                      child: hasExpenses
                          ? ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _visibleExpenses.length +
                                  (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _visibleExpenses.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final expense = _visibleExpenses[index];
                                final status = expense.statusLabel;
                                final distance = expense.distanceTravelled;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            expense.category ?? 'N/A',
                                            style: textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              expense.status,
                                            ).withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getStatusColor(
                                                expense.status,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                              color: _getStatusColor(
                                                expense.status,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.currency_rupee,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              expense.amount
                                                  .toStringAsFixed(2),
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (distance != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.straighten,
                                                  size: 14,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.6),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${distance.toStringAsFixed(1)} km',
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: colorScheme
                                                        .onSurface
                                                        .withValues(
                                                      alpha: 0.6,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 14,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                expense.user?.displayName ??
                                                    'Unknown',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.6),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _formatDate(expense.date),
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.receipt_outlined,
                                        size: 64,
                                        color: colorScheme.onBackground
                                            .withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No expenses match your filters',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: colorScheme.onBackground
                                              .withValues(alpha: 0.7),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try adjusting the search or status filters.',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onBackground
                                              .withValues(alpha: 0.6),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}
