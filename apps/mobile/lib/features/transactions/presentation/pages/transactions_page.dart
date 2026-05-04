import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

final transactionsProvider = FutureProvider.family<Map<String, dynamic>, ({String? type, int page, int limit})>((ref, arg) async {
  final client = ref.watch(dioClientProvider);
  final response = await client.get(ApiConstants.transactions, queryParameters: {
    if (arg.type != null) 'type': arg.type,
    'page': arg.page.toString(),
    'limit': arg.limit.toString(),
  });
  return response.data as Map<String, dynamic>;
});

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  String _filter = 'ALL';



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txAsync = ref.watch(transactionsProvider((
      type: _filter == 'ALL' ? null : _filter,
      page: 1,
      limit: 50,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => context.push('/analytics'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: 'All', isSelected: _filter == 'ALL', onTap: () => setState(() => _filter = 'ALL')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Income', isSelected: _filter == 'INCOME', onTap: () => setState(() => _filter = 'INCOME'), color: AppColors.income),
                const SizedBox(width: 8),
                _FilterChip(label: 'Expense', isSelected: _filter == 'EXPENSE', onTap: () => setState(() => _filter = 'EXPENSE'), color: AppColors.expense),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(transactionsProvider),
              child: txAsync.when(
                loading: () => const LoadingIndicator(),
                error: (e, _) => AppErrorWidget(
                  message: 'Failed to load transactions',
                  onRetry: () => ref.invalidate(transactionsProvider),
                ),
                data: (result) {
                  return _TransactionListView(
                    initialItems: List<Map<String, dynamic>>.from(result['data'] ?? []),
                    onRefresh: () async => ref.invalidate(transactionsProvider),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : activeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : activeColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TransactionListView extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  final Future<void> Function() onRefresh;

  const _TransactionListView({
    required this.initialItems,
    required this.onRefresh,
  });

  @override
  ConsumerState<_TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends ConsumerState<_TransactionListView> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  @override
  void didUpdateWidget(_TransactionListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItems != oldWidget.initialItems) {
      _items = List.from(widget.initialItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_items.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions',
        subtitle: 'Add your first income or expense',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final tx = _items[index];
        final type = tx['type'] ?? 'EXPENSE';
        final amount = (tx['amount'] ?? 0).toDouble();
        final currency = tx['currency'] ?? 'USD';
        final category = tx['category'] as Map<String, dynamic>?;
        final isIncome = type == 'INCOME';

        return Dismissible(
          key: Key(tx['id'] ?? index.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Transaction'),
                content: const Text('Are you sure you want to delete this transaction?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete', style: TextStyle(color: AppColors.errorLight)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) async {
            final id = tx['id'];
            setState(() => _items.removeAt(index));
            try {
              final client = ref.read(dioClientProvider);
              await client.delete('${ApiConstants.transactions}/$id');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
            } catch (e) {
              // Revert on error or show error
              widget.onRefresh(); // Refresh the whole list if delete failed
            }
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(category?['icon'] ?? '📦', style: const TextStyle(fontSize: 20))),
              ),
              title: Text(tx['title'] ?? '', style: AppTextStyles.titleMedium),
              subtitle: Text(
                '${category?['name'] ?? ''} • ${tx['date'] != null ? DateFormatter.formatRelative(DateTime.parse(tx['date'])) : ''}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
              ),
              trailing: Text(
                CurrencyFormatter.formatWithSign(amount, currency, type),
                style: AppTextStyles.amountSmall.copyWith(color: isIncome ? AppColors.income : AppColors.expense),
              ),
            ),
          ),
        );
      },
    );
  }
}

