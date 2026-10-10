import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/providers/expense_providers.dart';
import '../../../presentation/widgets/receipt_image.dart';
import '../../../core/utils/receipt_parser.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const ReviewScreen({super.key, required this.imagePath});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  late TextEditingController _merchantCtrl;
  late TextEditingController _dateCtrl;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false; bool _dateEdited = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _merchantCtrl = TextEditingController();
    _dateCtrl = TextEditingController();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Pre-fill from parsed data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromOcr();
      _slideController.forward();
    });
  }

  void _prefillFromOcr() {
    _applyParsed(ref.read(ocrProvider).parsedData);
    if (_dateCtrl.text.isEmpty) {
      _dateCtrl.text = DateFormatter.toDisplay(_selectedDate);
    }
    setState(() {});
  }

  /// Chỉ điền vào ô còn trống / chưa bị người dùng sửa
  void _applyParsed(ParsedReceiptData? data) {
    if (data == null) return;
    if (data.totalAmount != null && _amountCtrl.text.isEmpty) {
      _amountCtrl.text = data.totalAmount!.toStringAsFixed(0);
    }
    if (data.merchantName != null && _merchantCtrl.text.isEmpty) {
      _merchantCtrl.text = data.merchantName!;
    }
    if (data.date != null && !_dateEdited) {
      _selectedDate = data.date!;
      _dateCtrl.text = DateFormatter.toDisplay(_selectedDate);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.backgroundCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateEdited = true;
        _selectedDate = picked;
        _dateCtrl.text = DateFormatter.toDisplay(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final amount = double.tryParse(
        _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
      );

      if (amount == null || amount <= 0) {
        _showError('Invalid amount');
        return;
      }

      final ocrState = ref.read(ocrProvider);

      await repo.saveTransaction(
        totalAmount: amount,
        date: _selectedDate,
        merchantName: _merchantCtrl.text.trim().isNotEmpty
            ? _merchantCtrl.text.trim()
            : 'Unknown Merchant',
        category: _selectedCategory,
        receiptImage: XFile(widget.imagePath),
        rawOcrText: ocrState.parsedData?.rawText,
      );

      // Invalidate cache so lists refresh
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoryTotalsProvider);
      ref.invalidate(weeklySpendingProvider);
      ref.read(ocrProvider.notifier).reset();

      if (mounted) {
        _showSuccess();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Receipt saved successfully!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _dateCtrl.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrProvider);

    ref.listen(ocrProvider, (prev, next) {
      if (next.parsedData != null && next.parsedData != prev?.parsedData) {
        setState(() => _applyParsed(next.parsedData));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ─── Image Header ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.backgroundDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  if (ocrState.isProcessing)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      buildReceiptImage(
                        widget.imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppColors.backgroundCard,
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.backgroundDark.withAlpha(200),
                              AppColors.backgroundDark,
                            ],
                            stops: const [0.4, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Form ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            icon: Icons.receipt_long,
                            title: 'Review & Edit',
                            subtitle: 'OCR extracted data — confirm before saving',
                          ),
                          const Gap(20),

                          // OCR confidence badge
                          if (ocrState.parsedData != null)
                            _OcrConfidenceBadge(data: ocrState.parsedData!.rawText),

                          const Gap(20),

                          // Amount field
                          _ReviewField(
                            label: 'Total Amount (VND)',
                            icon: Icons.attach_money,
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            hint: 'e.g. 150000',
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                          const Gap(16),

                          // Merchant field
                          _ReviewField(
                            label: 'Merchant Name',
                            icon: Icons.store,
                            controller: _merchantCtrl,
                            hint: 'e.g. Highlands Coffee',
                            validator: null,
                          ),
                          const Gap(16),

                          // Date field
                          GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: _ReviewField(
                                label: 'Date',
                                icon: Icons.calendar_today,
                                controller: _dateCtrl,
                                hint: 'DD/MM/YYYY',
                                validator: null,
                              ),
                            ),
                          ),
                          const Gap(20),

                          // Category selector
                          _CategorySelector(
                            selected: _selectedCategory,
                            onChanged: (cat) =>
                                setState(() => _selectedCategory = cat),
                          ),
                          const Gap(32),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _save,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_alt),
                              label: Text(_isSaving ? 'Saving...' : 'Save Receipt'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const Gap(40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const Gap(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            Text(subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                )),
          ],
        ),
      ],
    );
  }
}

class _OcrConfidenceBadge extends StatelessWidget {
  final String data;
  const _OcrConfidenceBadge({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasContent = data.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: hasContent
            ? AppColors.success.withAlpha(20)
            : AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasContent
              ? AppColors.success.withAlpha(80)
              : AppColors.warning.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasContent ? Icons.check_circle : Icons.warning_amber,
            color: hasContent ? AppColors.success : AppColors.warning,
            size: 16,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              hasContent
                  ? 'OCR extracted ${data.split('\n').length} lines of text'
                  : 'OCR returned no text — please fill manually',
              style: TextStyle(
                color: hasContent ? AppColors.success : AppColors.warning,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ReviewField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategorySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.defaultCategories.map((cat) {
            final isSelected = cat == selected;
            final color = AppColors.categoryColor(cat);
            return GestureDetector(
              onTap: () => onChanged(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? color.withAlpha(40) : AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : AppColors.glassBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(Icons.check, color: color, size: 14),
                      const Gap(6),
                    ],
                    Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? color : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
