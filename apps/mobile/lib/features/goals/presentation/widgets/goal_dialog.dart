import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/models/models.dart';

class GoalDialog extends ConsumerStatefulWidget {
  final Goal? goal;
  const GoalDialog({super.key, this.goal});

  @override
  ConsumerState<GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends ConsumerState<GoalDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetController;
  late final TextEditingController _iconController;
  late DateTime? _deadline;
  late String _selectedStatus;
  late Color _selectedColor;
  bool _isLoading = false;

  final List<Color> _availableColors = [
    const Color(0xFF4F6EF5), // Blue
    const Color(0xFF00C896), // Teal
    const Color(0xFFFF5252), // Red
    const Color(0xFFFFB020), // Orange
    const Color(0xFF7B1FA2), // Purple
    const Color(0xFFC2185B), // Pink
    const Color(0xFFFBC02D), // Yellow
    const Color(0xFF388E3C), // Green
    const Color(0xFF455A64), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal?.title);
    _descriptionController = TextEditingController(text: widget.goal?.description);
    _targetController = TextEditingController(text: widget.goal?.targetAmount.toString() ?? '');
    _iconController = TextEditingController(text: widget.goal?.icon ?? '🎯');
    _deadline = widget.goal?.deadline;
    _selectedStatus = widget.goal?.status ?? 'IN_PROGRESS';
    
    // Parse color from string if available
    if (widget.goal?.color != null) {
      try {
        final colorStr = widget.goal!.color!.replaceAll('#', '');
        _selectedColor = Color(int.parse('FF$colorStr', radix: 16));
      } catch (_) {
        _selectedColor = _availableColors.first;
      }
    } else {
      _selectedColor = _availableColors.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.goal != null;
    
    return AlertDialog(
      title: Text(isEdit ? 'Edit Savings Goal' : 'New Savings Goal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _titleController, 
              label: 'Title', 
              hint: 'e.g. New Car',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Why are you saving?',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _targetController,
              label: 'Target Amount',
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Icon',
                    hint: 'Emoji',
                    controller: _iconController,
                  ),
                ),
                const SizedBox(width: 16),
                if (isEdit)
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'IN_PROGRESS', child: Text('Active')),
                        DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                        DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                      ],
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range),
              title: Text(_deadline == null
                  ? 'Target Date (Optional)'
                  : 'Target Date: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime(2050),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
              trailing: _deadline != null 
                ? IconButton(
                    icon: const Icon(Icons.clear), 
                    onPressed: () => setState(() => _deadline = null),
                  ) 
                : null,
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Theme Color', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                final isSelected = _selectedColor.value == color.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected 
                        ? Border.all(color: Colors.white, width: 3) 
                        : null,
                      boxShadow: isSelected 
                        ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)] 
                        : null,
                    ),
                    child: isSelected 
                      ? const Icon(Icons.check, color: Colors.white, size: 20) 
                      : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        AppButton(
          text: isEdit ? 'Save Changes' : 'Create Goal', 
          isLoading: _isLoading, 
          onPressed: _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _targetController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final client = ref.read(dioClientProvider);
      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'targetAmount': double.parse(_targetController.text),
        'icon': _iconController.text,
        'color': _colorToHex(_selectedColor),
        'status': _selectedStatus,
        'currency': widget.goal?.currency ?? 'USD',
        'deadline': _deadline?.toIso8601String(),
      };

      if (widget.goal != null) {
        await client.patch('${ApiConstants.goals}/${widget.goal!.id}', data: data);
      } else {
        await client.post(ApiConstants.goals, data: data);
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error saving goal: $e');
      setState(() => _isLoading = false);
    }
  }
}
