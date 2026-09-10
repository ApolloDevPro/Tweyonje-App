import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../providers/service_controllers.dart';
import '../../widgets/widgets.dart';

class SupportCreateScreen extends ConsumerStatefulWidget {
  const SupportCreateScreen({super.key});

  @override
  ConsumerState<SupportCreateScreen> createState() =>
      _SupportCreateScreenState();
}

class _SupportCreateScreenState extends ConsumerState<SupportCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'COLLECTION_ISSUE';
  String _priority = 'MEDIUM';

  static const _categories = [
    ('COLLECTION_ISSUE', 'Collection issue'),
    ('PAYMENT_ISSUE', 'Payment issue'),
    ('APP_BUG', 'App bug'),
    ('RECYCLING_INQUIRY', 'Recycling inquiry'),
    ('OTHER', 'Other'),
  ];

  static const _priorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('support.newTicket'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration:
                    InputDecoration(labelText: context.tr('support.subject')),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Subject is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration:
                    InputDecoration(labelText: context.tr('support.category')),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c.$1,
                          child: Text(c.$2),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'COLLECTION_ISSUE'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration:
                    InputDecoration(labelText: context.tr('support.priority')),
                items: _priorities
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v ?? 'MEDIUM'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: context.tr('support.message'),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Describe your issue'
                    : null,
              ),
              if (state.message != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  state.message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: state.isError ? AppColors.danger : AppColors.success,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: context.tr('common.send'),
                icon: const Icon(Icons.send_rounded, size: 18),
                isLoading: state.isCreating,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(supportProvider.notifier).create(
          subject: _subjectController.text.trim(),
          category: _category,
          priority: _priority,
          message: _messageController.text.trim(),
        );
    if (ok && mounted) {
      context.go('/support');
    }
  }
}