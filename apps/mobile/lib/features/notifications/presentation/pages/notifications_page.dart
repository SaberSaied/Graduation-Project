import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

final notificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final response = await client.get('${ApiConstants.notifications}?limit=50');
  return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
});

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              try {
                final client = ref.read(dioClientProvider);
                await client.patch(ApiConstants.notificationsReadAll);
                ref.invalidate(notificationsProvider);
              } catch (_) {}
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: notificationsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (error, stackTrace) => const Center(child: Text('Failed to load notifications')),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.notifications_none,
                title: 'No new notifications',
              );
            }

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['isRead'] ?? true;
                final type = notification['type'] ?? 'GENERAL';

                IconData icon;
                Color color;

                switch (type) {
                  case 'BUDGET_ALERT':
                  case 'OVERSPEND_WARNING':
                    icon = Icons.warning_amber_rounded;
                    color = AppColors.errorLight;
                    break;
                  case 'GOAL_PROGRESS':
                    icon = Icons.emoji_events_rounded;
                    color = AppColors.warningLight;
                    break;
                  default:
                    icon = Icons.notifications_rounded;
                    color = AppColors.primaryLight;
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  tileColor: isRead ? null : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(
                    notification['title'] ?? '',
                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification['message'] ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        DateFormatter.formatRelative(DateTime.parse(notification['createdAt'])),
                        style: AppTextStyles.labelSmall.copyWith(color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!isRead) {
                      try {
                        final client = ref.read(dioClientProvider);
                        await client.patch('${ApiConstants.notifications}/${notification['id']}/read');
                        ref.invalidate(notificationsProvider);
                      } catch (_) {}
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
