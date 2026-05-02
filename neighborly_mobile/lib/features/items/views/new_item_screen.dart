import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/core/theme/app_colors.dart';
import 'package:neighborly/core/theme/app_typography.dart';
import 'package:neighborly/core/widgets/design_system.dart';
import 'package:neighborly/core/network/dio_client.dart';
import 'package:neighborly/features/items/providers/items_provider.dart';

class NewItemScreen extends ConsumerStatefulWidget {
  const NewItemScreen({super.key});
  @override
  ConsumerState<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends ConsumerState<NewItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dailyRateCtrl = TextEditingController();
  final _weeklyRateCtrl = TextEditingController();
  final _depositCtrl = TextEditingController(text: '0');
  final _conditionCtrl = TextEditingController();
  String _category = 'Electronics';
  bool _isSubmitting = false;

  final _categories = ['Electronics', 'Books', 'Sports', 'Kitchen', 'Tools', 'Clothing', 'Other'];

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _dailyRateCtrl.dispose();
    _weeklyRateCtrl.dispose(); _depositCtrl.dispose(); _conditionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await createItem(ref.read(dioProvider),
        title: _titleCtrl.text.trim(),
        category: _category,
        dailyRate: double.parse(_dailyRateCtrl.text),
        description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
        weeklyRate: _weeklyRateCtrl.text.isNotEmpty ? double.parse(_weeklyRateCtrl.text) : null,
        depositRequired: double.parse(_depositCtrl.text),
        conditionDescription: _conditionCtrl.text.isNotEmpty ? _conditionCtrl.text : null,
      );
      ref.invalidate(itemsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item listed! 🎉')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('List an Item'), leading: IconButton(
        icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop(),
      )),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('What are you sharing?', style: AppTypography.headlineSmall),
          const SizedBox(height: 24),
          TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title_rounded)),
            validator: (v) => (v == null || v.length < 3) ? 'At least 3 characters' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(value: _category,
            decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded)),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!)),
          const SizedBox(height: 16),
          TextFormField(controller: _descCtrl, maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true)),
          const SizedBox(height: 16),
          TextFormField(controller: _conditionCtrl, maxLines: 2,
            decoration: const InputDecoration(labelText: 'Condition description', alignLabelWithHint: true)),
          const SizedBox(height: 24),
          const ShelfDivider(),
          const SizedBox(height: 24),
          Text('Pricing', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextFormField(controller: _dailyRateCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Daily Rate (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _weeklyRateCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weekly Rate (₹)'))),
          ]),
          const SizedBox(height: 16),
          TextFormField(controller: _depositCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Security Deposit (₹)', prefixIcon: Icon(Icons.shield_outlined))),
          const SizedBox(height: 32),
          GradientPillButton(label: 'Publish Listing', icon: Icons.check_rounded,
            onPressed: _isSubmitting ? null : _submit, isLoading: _isSubmitting, width: double.infinity),
          const SizedBox(height: 40),
        ])),
      ),
    );
  }
}
