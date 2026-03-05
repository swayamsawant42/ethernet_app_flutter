import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/field_survey.dart';
import '../services/api_service.dart';
import 'field_survey_page.dart';

class SurveyResponsesPage extends StatefulWidget {
  const SurveyResponsesPage({super.key});

  @override
  State<SurveyResponsesPage> createState() => _SurveyResponsesPageState();
}

class _SurveyResponsesPageState extends State<SurveyResponsesPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<FieldSurvey> _allSurveys = [];
  List<FieldSurvey> _visibleSurveys = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;
  String _ratingFilter = 'ALL';
  String _searchTerm = '';
  String? _errorMessage;
  int? _currentUserId;
  String? _employeeCode;
  String? _userPhone;
  bool _isFetchingProfile = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    await _loadProfile();
    if (!mounted) return;
    await _fetchSurveys(refresh: true);
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isFetchingProfile = true;
      _profileError = null;
    });

    try {
      final profile = await _apiService.getProfile();
      if (!mounted) return;

      final idValue = profile?['id'];
      final parsedId = idValue is int ? idValue : int.tryParse('$idValue');

      setState(() {
        _currentUserId = parsedId;
        _employeeCode = profile?['employeCode']?.toString() ??
            profile?['employeeCode']?.toString() ??
            profile?['employeeId']?.toString();
        _userPhone = profile?['phoneNumber']?.toString();
        _isFetchingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Failed to load profile. Please try again.';
        _isFetchingProfile = false;
      });
    }
  }

  bool _isFetchingSurveys = false; // Guard to prevent multiple simultaneous calls

  Future<void> _fetchSurveys({bool refresh = false}) async {
    if (_isFetchingProfile) {
      return;
    }
    
    // Prevent multiple simultaneous calls (unless it's a refresh)
    if (!refresh && _isFetchingSurveys) {
      return;
    }

    if (_currentUserId == null &&
        (_userPhone == null || _userPhone!.trim().isEmpty)) {
      setState(() {
        _errorMessage = 'Missing user information. Please re-login.';
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = false;
      });
      return;
    }

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
        _allSurveys = [];
        _visibleSurveys = [];
        _errorMessage = null;
      });
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      if (_currentPage == 1 && !refresh) {
        _isLoading = true;
      } else if (_currentPage > 1) {
        _isLoadingMore = true;
      }
      _errorMessage = null;
      _isFetchingSurveys = true;
    });

    try {
      final responseData = await _apiService.getFieldSurveys(
        page: _currentPage,
        limit: _limit,
        userId: _currentUserId,
        employeCode: _employeeCode,
      );

      if (!mounted) return;

      if (responseData == null) {
        setState(() {
          _errorMessage = 'Failed to load surveys';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final response = FieldSurveyListResponse.fromResponse(responseData);
      final filtered = response.surveys.where(_belongsToCurrentUser).toList();

      setState(() {
        if (refresh || _currentPage == 1) {
          _allSurveys = filtered;
        } else {
          // Only add surveys we haven't seen before (by ID) to prevent duplicates
          final existingIds = _allSurveys.map((s) => s.id).toSet();
          final newSurveys = filtered.where((s) => s.id != null && !existingIds.contains(s.id)).toList();
          _allSurveys.addAll(newSurveys);
          
          // If no new surveys were added, we've reached the end (API returns all data on each page)
          if (newSurveys.isEmpty) {
            _hasMore = false;
            _isLoading = false;
            _isLoadingMore = false;
            _applyFilters();
            return;
          }
        }

        final pagination = response.pagination;
        if (pagination != null) {
          _hasMore = pagination.hasMore;
          _currentPage =
              _hasMore ? pagination.nextPage : pagination.page ?? _currentPage;
        } else {
          // If no pagination info, check if we got fewer surveys than limit
          // or if we're getting duplicates (API returns all surveys on every page)
          if (response.surveys.length < _limit) {
            _hasMore = false;
          } else if (!refresh && _currentPage > 1) {
            // On subsequent pages, if we got the same number of surveys as limit
            // but they're all duplicates, stop paginating
            // This handles the case where API returns all surveys on every page
            _hasMore = false;
          } else {
            _hasMore = true;
            _currentPage++;
          }
        }

        _isLoading = false;
        _isLoadingMore = false;
        _isFetchingSurveys = false;
        _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading surveys: ${e.toString()}';
        _isLoading = false;
        _isLoadingMore = false;
        _isFetchingSurveys = false;
      });
    }
  }

  void _applyFilters() {
    final term = _searchTerm.trim().toLowerCase();
    final ratingFilter = _ratingFilter;

    _visibleSurveys = _allSurveys.where((survey) {
      final matchesRating = ratingFilter == 'ALL' ||
          (survey.serviceRating?.toLowerCase() ?? '') ==
              ratingFilter.toLowerCase();

      final searchTarget = [
        survey.serviceRating,
        survey.likedFeatures,
        survey.heardFrom,
        survey.feedback,
        survey.contactNumber,
      ].whereType<String>().join(' ').toLowerCase();

      final matchesSearch = term.isEmpty || searchTarget.contains(term);

      return matchesRating && matchesSearch;
    }).toList()
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
  }

  bool _belongsToCurrentUser(FieldSurvey survey) {
    if (_currentUserId != null && survey.userId != null) {
      return survey.userId == _currentUserId;
    }

    if (_userPhone != null &&
        _userPhone!.isNotEmpty &&
        survey.contactNumber?.trim() == _userPhone) {
      return true;
    }

    return _currentUserId == null && (_userPhone == null || _userPhone!.isEmpty);
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

  Future<void> _onEditSurvey(FieldSurvey survey) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FieldSurveyPage(
          existingSurvey: survey,
          navigateToCompletionOnSubmit: false,
        ),
      ),
    );

    if (result == true && mounted) {
      await _fetchSurveys(refresh: true);
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Responses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchSurveys(refresh: true),
            tooltip: 'Refresh',
          )
        ],
      ),
      body: (_isFetchingProfile || _isLoading) && _allSurveys.isEmpty
          ? Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            )
          : (_profileError ?? _errorMessage) != null && _allSurveys.isEmpty
              ? _ErrorState(
                  message: _profileError ?? _errorMessage!,
                  onRetry: () {
                    if (_profileError != null) {
                      _initialize();
                    } else {
                      _fetchSurveys(refresh: true);
                    }
                  },
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: 'Search by rating, contact, or feedback',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'All',
                                  selected: _ratingFilter == 'ALL',
                                  onSelected: () {
                                    setState(() {
                                      _ratingFilter = 'ALL';
                                      _applyFilters();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Excellent',
                                  selected: _ratingFilter == 'Excellent',
                                  color: Colors.green,
                                  onSelected: () {
                                    setState(() {
                                      _ratingFilter = 'Excellent';
                                      _applyFilters();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Good',
                                  selected: _ratingFilter == 'Good',
                                  color: Colors.blue,
                                  onSelected: () {
                                    setState(() {
                                      _ratingFilter = 'Good';
                                      _applyFilters();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Average',
                                  selected: _ratingFilter == 'Average',
                                  color: Colors.orange,
                                  onSelected: () {
                                    setState(() {
                                      _ratingFilter = 'Average';
                                      _applyFilters();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Poor',
                                  selected: _ratingFilter == 'Poor',
                                  color: Colors.red,
                                  onSelected: () {
                                    setState(() {
                                      _ratingFilter = 'Poor';
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
                        onRefresh: () => _fetchSurveys(refresh: true),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (!_isLoadingMore &&
                                _hasMore &&
                                scrollInfo.metrics.pixels >=
                                    scrollInfo.metrics.maxScrollExtent - 200) {
                              _fetchSurveys();
                            }
                            return false;
                          },
                          child: _visibleSurveys.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 80),
                                    Center(
                                      child: Text(
                                        'No surveys match your filters.',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: _visibleSurveys.length +
                                      (_isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _visibleSurveys.length) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    final survey = _visibleSurveys[index];
                                    return _SurveyCard(
                                      survey: survey,
                                      onEdit: () => _onEditSurvey(survey),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  final FieldSurvey survey;
  final VoidCallback onEdit;

  const _SurveyCard({required this.survey, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    survey.serviceRating ?? 'N/A',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    survey.contactNumber ?? 'N/A',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.public, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  survey.heardFrom ?? 'N/A',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (survey.likedFeatures != null &&
                survey.likedFeatures!.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.thumb_up, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      survey.likedFeatures!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            if (survey.feedback != null && survey.feedback!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        survey.feedback!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(survey.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                if (survey.latitude != null && survey.longitude != null)
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14,
                          color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        '${survey.latitude!.toStringAsFixed(4)}, '
                        '${survey.longitude!.toStringAsFixed(4)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
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
      selectedColor: baseColor.withOpacity(0.15),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: selected ? baseColor : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onSelected(),
      side: BorderSide(color: baseColor.withOpacity(0.5)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

