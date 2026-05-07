import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_obligation.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/obligations_provider.dart';
import '../widgets/due_bill_card.dart';
import '../widgets/add_obligation_dialog.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obligationsAsync = ref.watch(obligationsProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Payment Reminders'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: obligationsAsync.when(
        data: (obligations) {
          final bills = obligations.where((o) => o.type == ObligationType.bill || o.type == ObligationType.installment).toList();
          
          if (bills.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildTimelineHeader(),
              const SizedBox(height: 24),
              ...bills.map((bill) => DueBillCard(
                bill: bill,
                onPayPressed: () {
                  ref.read(obligationActionProvider.notifier).markAsPaid(bill.id, bill.amount);
                },
              )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddObligationDialog(),
          );
        },
        backgroundColor: AppColors.primaryLight,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Payments', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Don\'t miss these upcoming due dates.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text('No reminders set', style: AppTextStyles.titleLarge),
        ],
      ),
    );
  }
}
