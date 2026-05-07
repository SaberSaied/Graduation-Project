enum HistoryDateRange {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
  custom
}

class HistoryFilter {
  final HistoryDateRange dateRange;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? type; // ALL, INCOME, EXPENSE
  final List<String> categoryIds;
  final double? minAmount;
  final double? maxAmount;
  final String? search;
  final String sortBy;

  HistoryFilter({
    this.dateRange = HistoryDateRange.thisMonth,
    this.startDate,
    this.endDate,
    this.type = 'ALL',
    this.categoryIds = const [],
    this.minAmount,
    this.maxAmount,
    this.search,
    this.sortBy = 'date_desc',
  });

  HistoryFilter copyWith({
    HistoryDateRange? dateRange,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    List<String>? categoryIds,
    double? minAmount,
    double? maxAmount,
    String? search,
    String? sortBy,
  }) {
    return HistoryFilter(
      dateRange: dateRange ?? this.dateRange,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      categoryIds: categoryIds ?? this.categoryIds,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'sortBy': sortBy,
    };

    if (type != 'ALL') params['type'] = type;
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (minAmount != null) params['minAmount'] = minAmount;
    if (maxAmount != null) params['maxAmount'] = maxAmount;
    if (categoryIds.isNotEmpty) params['categoryId'] = categoryIds.join(',');

    final range = _getDates();
    if (range.start != null) params['from'] = range.start!.toIso8601String();
    if (range.end != null) params['to'] = range.end!.toIso8601String();

    return params;
  }

  ({DateTime? start, DateTime? end}) _getDates() {
    if (dateRange == HistoryDateRange.custom) {
      return (start: startDate, end: endDate);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (dateRange) {
      case HistoryDateRange.today:
        return (start: today, end: today.add(const Duration(days: 1)));
      case HistoryDateRange.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return (start: yesterday, end: today);
      case HistoryDateRange.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return (start: startOfWeek, end: today.add(const Duration(days: 1)));
      case HistoryDateRange.thisMonth:
        final startOfMonth = DateTime(today.year, today.month, 1);
        return (start: startOfMonth, end: today.add(const Duration(days: 1)));
      case HistoryDateRange.lastMonth:
        final startOfLastMonth = DateTime(today.year, today.month - 1, 1);
        final endOfLastMonth = DateTime(today.year, today.month, 0);
        return (start: startOfLastMonth, end: endOfLastMonth);
      case HistoryDateRange.last3Months:
        final start = DateTime(today.year, today.month - 3, 1);
        return (start: start, end: today.add(const Duration(days: 1)));
      case HistoryDateRange.thisYear:
        final startOfYear = DateTime(today.year, 1, 1);
        return (start: startOfYear, end: today.add(const Duration(days: 1)));
      default:
        return (start: null, end: null);
    }
  }
}
