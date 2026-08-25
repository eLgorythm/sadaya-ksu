import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/app_input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/entities/cash_entities.dart';
import '../cubit/cash_form_cubit.dart';
import '../cubit/keuangan_cubit.dart';

class CashFormSheet extends StatefulWidget {
  const CashFormSheet({super.key, required this.initialBook});

  /// 'cash' atau 'bank' — mengikuti tab yang sedang dibuka.
  final String initialBook;

  static Future<bool> show(
    BuildContext context, {
    required String initialBook,
  }) async {
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => CashFormSheet(initialBook: initialBook),
        ) ??
        false;
  }

  @override
  State<CashFormSheet> createState() => _CashFormSheetState();
}

class _CashFormSheetState extends State<CashFormSheet> {
  late final CashFormCubit _cubit = GetIt.I<CashFormCubit>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// Penanda pemaksaan rebuild dropdown saat pilihan berubah
  /// secara programatik (dropdown memakai initialValue).
  int _categoryEpoch = 0;

  late String _book = widget.initialBook;
  String _direction = 'in';
  CashCategoryOption? _category;
  List<CashCategoryOption> _categories = const [];
  DateTime _date = DateTime.now();

  /// Item khusus di ujung daftar untuk membuka dialog
  /// pembuatan kategori baru.
  static const _newCategoryOption = CashCategoryOption(
    code: '',
    name: '+ Kategori baru...',
    isIncome: false,
  );

  bool get _isIncoming => _direction == 'in';
  String get _title => _book == 'cash' ? 'Transaksi Buku Kas' : 'Transaksi Buku Bank';

  @override
  void initState() {
    super.initState();
    final state = GetIt.I<KeuanganCubit>().state;
    if (state is KeuanganLoaded) {
      _categories = state.categories;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _cubit.close();
    super.dispose();
  }

  /// Kategori sesuai arah + opsi transfer antar-buku (akun lawan).
  List<CashCategoryOption> _optionsFor() {
    final filtered =
        _categories.where((c) => c.isIncome == _isIncoming).toList();
    final otherBookCode = _book == 'cash' ? '1112' : '1111';
    final transferLabel = switch ((_book, _isIncoming)) {
      ('cash', true) => 'Transfer dari Bank',
      ('cash', false) => 'Transfer ke Bank',
      (_, true) => 'Transfer dari Kas',
      (_, false) => 'Transfer ke Kas',
    };
    if (!filtered.any((c) => c.code == otherBookCode)) {
      filtered.add(CashCategoryOption(
        code: otherBookCode,
        name: transferLabel,
        isIncome: _isIncoming,
      ));
    }
    filtered.add(_newCategoryOption);
    return filtered;
  }

  Future<void> _createNewCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kategori Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Nama kategori',
            helperText:
                'Akan masuk daftar ${_isIncoming ? 'pendapatan' : 'biaya'} '
                'dengan kode akun otomatis',
          ),
          onSubmitted: (value) =>
              Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty || !mounted) return;

    final result = await GetIt.I<KeuanganCubit>().addCategory(
      name: name,
      isIncome: _isIncoming,
    );
    if (!mounted) return;

    switch (result) {
      case Ok(:final value):
        final created = CashCategoryOption(
          code: value,
          name: name,
          isIncome: _isIncoming,
        );
        setState(() {
          _categories = [..._categories, created];
          _category = created;
          _categoryEpoch++;
        });
        SadayaMessage.success(context, 'Kategori "$name" ditambahkan');
      case Err(:final failure):
        SadayaMessage.error(context, failure.message);
    }
  }

  void _resetCategoryIfInvalid(List<CashCategoryOption> options) {
    if (_category != null && !options.any((c) => c.code == _category!.code)) {
      _category = null;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Tanggal Transaksi',
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final category = _category;
    if (category == null) {
      SadayaMessage.error(context, 'Kategori wajib dipilih');
      return;
    }
    FocusScope.of(context).unfocus();
    _cubit.save(
      book: _book,
      direction: _direction,
      counterAccount: category.code,
      amount: double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0,
      date: _date,
      description: _noteController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<CashFormCubit, CashFormState>(
        listener: (context, state) {
          switch (state) {
            case CashFormSuccess():
              SadayaMessage.success(
                context,
                'Transaksi tercatat & diposting ke buku besar',
              );

              /// Tutup sheet sendiri dengan hasil true —
              /// halaman pemanggil yang me-reload daftar.
              Navigator.of(context).pop(true);
            case CashFormFailure(:final message):
              SadayaMessage.error(context, message);
            default:
              break;
          }
        },
        builder: (context, state) {
          final saving = state is CashFormSaving;
          final options = _optionsFor();
          _resetCategoryIfInvalid(options);

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(title: _title),
                  const SizedBox(height: 4),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'cash', label: Text('Buku Kas')),
                      ButtonSegment(value: 'bank', label: Text('Buku Bank')),
                    ],
                    selected: {_book},
                    onSelectionChanged: saving
                        ? null
                        : (selection) =>
                            setState(() => _book = selection.first),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Masuk'),
                        selected: _isIncoming,
                        onSelected: saving
                            ? null
                            : (_) => setState(() => _direction = 'in'),
                      ),
                      ChoiceChip(
                        label: const Text('Keluar'),
                        selected: !_isIncoming,
                        onSelected: saving
                            ? null
                            : (_) => setState(() => _direction = 'out'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CashCategoryOption>(
                    key: ValueKey('$_book$_direction$_categoryEpoch'),
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Kategori *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      for (final option in options)
                        DropdownMenuItem(
                          value: option,
                          child: Text(
                            option.name,
                            overflow: TextOverflow.ellipsis,
                            style: option.code.isEmpty
                                ? TextStyle(
                                    color:
                                        AppColors.primaryGreen.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600)
                                : null,
                          ),
                        ),
                    ],
                    onChanged: saving
                        ? null
                        : (value) async {
                            if (value == null) return;
                            if (value.code.isEmpty) {
                              await _createNewCategory();
                              if (mounted) setState(() {});
                              return;
                            }
                            setState(() => _category = value);
                          },
                    validator: (value) =>
                        value == null || value.code.isEmpty
                            ? 'Kategori wajib dipilih'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Nominal (Rp) *',
                      prefixIcon: Icon(Icons.payments_outlined),
                      hintText: 'mis. 150.000',
                    ),
                    validator: Validators.positiveAmount(label: 'Nominal'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: saving ? null : _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Transaksi *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(AppFormatters.date(_date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan *',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    validator: Validators.required('Keterangan'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving ? null : _submit,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
