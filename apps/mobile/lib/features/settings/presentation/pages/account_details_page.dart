import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../core/storage/secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

final userProfileProvider = FutureProvider.autoDispose<AppUser>((ref) async {
  final client = ref.watch(dioClientProvider);
  final response = await client.get(ApiConstants.userMe);
  return AppUser.fromJson(response.data['data']);
});

class AccountDetailsPage extends ConsumerStatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  ConsumerState<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends ConsumerState<AccountDetailsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedCurrency = 'USD';
  bool _isSaving = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account Details')),
      body: userAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(
          message: 'Failed to load profile',
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (user) {
          if (_nameController.text.isEmpty) {
            _nameController.text = user.name;
            _emailController.text = user.email;
            _selectedCurrency = user.currency;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
                          backgroundImage: _imageFile != null 
                              ? FileImage(_imageFile!) 
                              : (user.image != null && user.image!.startsWith('http') 
                                  ? NetworkImage(user.image!) 
                                  : (user.image != null && user.image!.startsWith('data:image')
                                      ? MemoryImage(base64Decode(user.image!.split(',').last))
                                      : null) as ImageProvider?),
                          child: _imageFile == null && user.image == null
                              ? Text(
                                  user.name.substring(0, 1).toUpperCase(),
                                  style: AppTextStyles.displayMedium.copyWith(color: AppColors.primaryLight),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 16),
                
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  readOnly: true, // Email usually handled by verification process
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Currency',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('US Dollar (\$)')),
                    DropdownMenuItem(value: 'EUR', child: Text('Euro (€)')),
                    DropdownMenuItem(value: 'GBP', child: Text('British Pound (£)')),
                    DropdownMenuItem(value: 'EGP', child: Text('Egyptian Pound (EGP)')),
                  ],
                  onChanged: (v) => setState(() => _selectedCurrency = v!),
                ),
                
                const SizedBox(height: 40),
                AppButton(
                  text: 'Save Changes',
                  isLoading: _isSaving,
                  width: double.infinity,
                  onPressed: _saveProfile,
                ),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                
                Text('Danger Zone', style: AppTextStyles.titleMedium.copyWith(color: AppColors.errorLight)),
                const SizedBox(height: 8),
                Text(
                  'Once you delete your account, there is no going back. Please be certain.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _deleteAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorLight,
                    side: const BorderSide(color: AppColors.errorLight),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Delete Account'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final client = ref.read(dioClientProvider);
      
      String? base64Image;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        base64Image = 'data:image/png;base64,${base64Encode(bytes)}';
      }

      await client.patch(ApiConstants.userMe, data: {
        'name': _nameController.text,
        'currency': _selectedCurrency,
        'image': base64Image,
      });
      
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (_) {
      // Error handled by dio interceptor
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Account',
      message: 'Are you sure you want to permanently delete your account and all associated data?',
      confirmLabel: 'Delete Permanently',
      confirmColor: AppColors.errorLight,
    );

    if (confirm == true) {
      try {
        final client = ref.read(dioClientProvider);
        await client.delete(ApiConstants.userMe);
        await SecureStorage().clearAll();
        if (mounted) context.go('/auth/login');
      } catch (_) {}
    }
  }
}
