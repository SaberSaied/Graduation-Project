import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Account
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account Details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/account'),
          ),

          // Theme
          ListTile(
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.primaryLight),
            title: const Text('Appearance'),
            subtitle: Text(themeMode == ThemeMode.system ? 'System default' : (isDark ? 'Dark Theme' : 'Light Theme')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),

          // History
          ListTile(
            leading: const Icon(Icons.history_rounded, color: AppColors.primaryLight),
            title: const Text('Transaction History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/transactions'),
          ),

          // Analytics
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: AppColors.primaryLight),
            title: const Text('Analytics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/analytics'),
          ),

          // Categories
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Manage Categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/categories'),
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.errorLight),
            title: const Text('Log Out', style: TextStyle(color: AppColors.errorLight)),
            onTap: () async {
              final confirm = await ConfirmationDialog.show(
                context,
                title: 'Log Out',
                message: 'Are you sure you want to log out?',
                confirmLabel: 'Log Out',
                confirmColor: AppColors.errorLight,
              );

              if (confirm == true) {
                await SecureStorage().clearAll();
                if (context.mounted) context.go('/auth/login');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentTheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Select Theme', style: AppTextStyles.titleLarge),
              ),
              _ThemeOption(
                title: 'System Default',
                icon: Icons.brightness_auto,
                isSelected: currentTheme == ThemeMode.system,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              _ThemeOption(
                title: 'Light',
                icon: Icons.light_mode,
                isSelected: currentTheme == ThemeMode.light,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              _ThemeOption(
                title: 'Dark',
                icon: Icons.dark_mode,
                isSelected: currentTheme == ThemeMode.dark,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : null)),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
