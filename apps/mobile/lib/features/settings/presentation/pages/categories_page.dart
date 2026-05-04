import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

final categoriesListProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final response = await client.get(ApiConstants.categories);
  final List data = response.data['data'] ?? [];
  return data.map((json) => Category.fromJson(json)).toList();
});

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showCategoryDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(categoriesListProvider),
        child: categoriesAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading categories...'),
          error: (e, _) => AppErrorWidget(
            message: 'Failed to load categories',
            onRetry: () => ref.invalidate(categoriesListProvider),
          ),
          data: (categories) {
            if (categories.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.category_outlined,
                title: 'No categories',
                subtitle: 'Create your first category to start tracking',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryTile(category: category);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, [Category? category]) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryDialog(category: category),
    ).then((value) {
      if (value == true) ref.invalidate(categoriesListProvider);
    });
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Parse color hex string safely
    Color catColor = AppColors.primaryLight;
    try {
      final hex = category.color.replaceAll('#', '');
      catColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(category.icon, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(category.name, style: AppTextStyles.titleMedium),
        subtitle: Text(category.type, style: AppTextStyles.bodySmall),
        trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => _CategoryDialog(category: category),
                    ).then((value) {
                      if (value == true) ref.invalidate(categoriesListProvider);
                    });
                  },
                ),
                if (!category.isDefault)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.errorLight, size: 20),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
              ],
            ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This will not delete transactions in this category.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                final client = ref.read(dioClientProvider);
                await client.delete(ApiConstants.category(category.id));
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(categoriesListProvider);
              } catch (_) {}
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorLight)),
          ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  final Category? category;
  const _CategoryDialog({this.category});

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _nameController = TextEditingController();
  String _selectedIcon = '📦';
  String _selectedColor = '#5B6AD0'; // Primary Light
  String _selectedType = 'EXPENSE';
  bool _isLoading = false;

  final List<String> _suggestedColors = [
    '#FF6B6B', '#4ECDC4', '#FFE66D', '#A855F7', '#F97316', 
    '#EF4444', '#3B82F6', '#8B5CF6', '#06B6D4', '#EC4899',
    '#F43F5E', '#6366F1', '#14B8A6', '#00C896', '#10B981',
    '#5B6AD0', '#0F172A', '#6B7280'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
      _selectedType = widget.category!.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'New Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'e.g. Groceries',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'EXPENSE', child: Text('Expense')),
                DropdownMenuItem(value: 'INCOME', child: Text('Income')),
              ],
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: AppTextField(
                    label: 'Icon',
                    hint: 'Emoji',
                    onChanged: (v) => setState(() => _selectedIcon = v),
                    controller: TextEditingController(text: _selectedIcon),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Color', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestedColors.map((colorHex) {
                          final color = Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
                          final isSelected = _selectedColor == colorHex;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = colorHex),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ] : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        AppButton(
          text: 'Save',
          isLoading: _isLoading,
          onPressed: _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(dioClientProvider);
      final data = {
        'name': _nameController.text,
        'icon': _selectedIcon,
        'color': _selectedColor,
        'type': _selectedType,
      };

      if (widget.category == null) {
        await client.post(ApiConstants.categories, data: data);
      } else {
        await client.patch(ApiConstants.category(widget.category!.id), data: data);
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }
}
