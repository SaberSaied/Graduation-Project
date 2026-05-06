import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/ai_command_models.dart';
import '../providers/ai_commands_provider.dart';

class AIActionPreview extends ConsumerWidget {
  final AICommandResponse response;

  const AIActionPreview({super.key, required this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 8),
                Text('AI Proposed Actions', style: AppTextStyles.titleMedium),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: response.actions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final action = response.actions[index];
              return _ActionTile(action: action, index: index);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(aiCommandProvider.notifier).cancelActions(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref.read(aiCommandProvider.notifier).confirmActions(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirm'),
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

class _ActionTile extends ConsumerWidget {
  final AICommandAction action;
  final int index;

  const _ActionTile({required this.action, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData icon;
    String title;
    String subtitle;

    switch (action.type) {
      case 'CREATE_TRANSACTION':
        icon = action.data['type'] == 'INCOME' ? Icons.add_circle_outline : Icons.remove_circle_outline;
        title = "Add ${action.data['type'] == 'INCOME' ? 'Income' : 'Expense'}";
        subtitle = "${action.data['amount']} ${action.data['currency']} - ${action.data['category']}";
        break;
      case 'CREATE_CATEGORY':
        icon = Icons.category_outlined;
        title = "Create Category";
        subtitle = "${action.data['name']} (${action.data['type']})";
        break;
      case 'CREATE_BUDGET':
        icon = Icons.pie_chart_outline;
        title = "Set Budget";
        subtitle = "${action.data['amount']} for ${action.data['category']}";
        break;
      case 'CREATE_GOAL':
        icon = Icons.flag_outlined;
        title = "Create Goal";
        subtitle = "${action.data['title']} (Target: ${action.data['targetAmount']})";
        break;
      case 'CONTRIBUTE_TO_GOAL':
        icon = Icons.savings_outlined;
        title = "Save toward Goal";
        subtitle = "Add ${action.data['amount']} to ${action.data['goalTitle']}";
        break;
      case 'CREATE_REMINDER':
        icon = Icons.alarm_outlined;
        title = "Set Reminder";
        subtitle = action.data['title'];
        break;
      case 'CREATE_NOTE':
        icon = Icons.note_outlined;
        title = "Save Note";
        final content = action.data['content'].toString();
        subtitle = "${content.substring(0, content.length > 30 ? 30 : content.length)}...";
        break;
      default:
        icon = Icons.help_outline;
        title = action.type;
        subtitle = action.data.toString();
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
        child: Icon(icon, color: AppColors.primaryLight, size: 20),
      ),
      title: Text(title, style: AppTextStyles.labelLarge),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 18),
        onPressed: () => ref.read(aiCommandProvider.notifier).removeAction(index),
      ),
    );
  }
}
