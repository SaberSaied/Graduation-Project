import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/obligations_provider.dart';
import '../widgets/subscription_card.dart';
import '../widgets/add_obligation_dialog.dart';

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(obligationsProvider('SUBSCRIPTION'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Subscriptions'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: subscriptionsAsync.when(
        data: (subs) {
          if (subs.isEmpty) {
            return _buildEmptyState();
          }
          
          final totalMonthly = subs.fold<double>(0, (sum, item) => sum + item.amount);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildMonthlyCostHeader(totalMonthly),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${subs.length} Active Subscriptions', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  const Icon(Icons.filter_list, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              ...subs.map((sub) => SubscriptionCard(subscription: sub)),
              const SizedBox(height: 32),
              _buildYearlyProjection(totalMonthly),
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

  Widget _buildMonthlyCostHeader(double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('Total Monthly Cost', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyProjection(double monthly) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: Colors.amber),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yearly Estimation', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  'You will spend \$${(monthly * 12).toStringAsFixed(0)} this year on subscriptions.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subscriptions_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text('No Subscriptions Found', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          const Text('Add your first subscription to track it here.'),
        ],
      ),
    );
  }
}
