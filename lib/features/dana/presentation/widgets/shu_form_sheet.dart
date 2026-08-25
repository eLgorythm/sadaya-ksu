import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/app_input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/entities/dana_entities.dart';
import '../cubit/shu_form_cubit.dart';

/// Sheet perhitungan SHU tahunan. Dipakai untuk membuat draft baru
/// maupun mengedit draft yang sudah ada lewat [existing].
class ShuFormSheet extends StatefulWidget {
  const ShuFormSheet({super.key, this.existing});

  final ShuDistribution? existing;

  static Future<bool> show(BuildContext context,
      {ShuDistribution? existing}) async {
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => ShuFormSheet(existing: existing),
        ) ??
        false;
  }

  @override
  State<ShuFormSheet> createState() => _ShuFormSheetState();
}

class _ShuFormSheetState extends State<ShuFormSheet> {
  late final ShuFormCubit _cubit = GetIt.I<ShuFormCubit>();
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final _taxController = TextEditingController();
  final _reservePctController = TextEditingController();
  final _socialPctController = TextEditingController(text: '5');
  final _educationPctController = TextEditingController(text: '5');
  final _memberPctController = TextEditingController();
  final _managementPctController = TextEditingController();
  final _notesController = TextEditingController();

  int _year = DateTime.now().year;

  /// Bila aktif, setelah tersimpan status langsung jadi "disetujui"
  /// sehingga tinggal menekan Distribusikan di tab SHU.
  bool _approveDirectly = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final shu = widget.existing;
    if (shu != null) {
      _year = shu.fiscalYear;
      _approveDirectly = false;
      _totalController.text = _moneyText(shu.totalShu);
      if (shu.taxAmount > 0) {
        _taxController.text = _moneyText(shu.taxAmount);
      }
      _reservePctController.text = _pctText(shu.reservePct);
      _socialPctController.text = _pctText(shu.socialPct);
      _educationPctController.text = _pctText(shu.educationPct);
      _memberPctController.text = _pctText(shu.memberDividendPct);
      _managementPctController.text = _pctText(shu.managementPct);
      _notesController.text = shu.notes ?? '';
    }
  }

  static String _moneyText(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }

  static String _pctText(double? fraction) {
    if (fraction == null || fraction == 0) return '';
    return (fraction * 100)
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'[.,]?0+$'), '');
  }

  @override
  void dispose() {
    for (final c in [
      _totalController,
      _taxController,
      _reservePctController,
      _socialPctController,
      _educationPctController,
      _memberPctController,
      _managementPctController,
      _notesController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalShu =>
      double.tryParse(_totalController.text.replaceAll('.', '')) ?? 0;
  double get _tax =>
      double.tryParse(_taxController.text.replaceAll('.', '')) ?? 0;

  /// Fraksi persentase dari input teks (kosong = 0, % → pecahan).
  double _pctOf(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
    return v / 100;
  }

  double get _netShu => (_totalShu - _tax).clamp(0, double.infinity);

  Widget _pctField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: '%',
      ),
      validator: (value) {
        final v = value?.trim().replaceAll(',', '.') ?? '';
        if (v.isEmpty) return null;
        final parsed = double.tryParse(v);
        if (parsed == null || parsed < 0 || parsed > 100) {
          return 'Isi 0-100';
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _cubit.save(
      existingId: widget.existing?.id,
      fiscalYear: _year,
      totalShu: _totalShu,
      taxAmount: _tax,
      reservePct: _pctOf(_reservePctController),
      socialPct: _pctOf(_socialPctController),
      educationPct: _pctOf(_educationPctController),
      memberDividendPct: _pctOf(_memberPctController),
      managementPct: _pctOf(_managementPctController),
      notes: _notesController.text,
      approveAfterSave: _approveDirectly,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ShuFormCubit, ShuFormState>(
        listener: (context, state) {
          switch (state) {
            case ShuFormSuccess():
              SadayaMessage.success(context, 'Perhitungan SHU tersimpan');
              Navigator.of(context).pop(true);
            case ShuFormFailure(:final message):
              SadayaMessage.error(context, message);
            default:
              break;
          }
        },
        builder: (context, state) {
          final saving = state is ShuFormSaving;
          final netShu = _netShu;
          final allocations = <String, double>{
            'Cadangan': netShu * _pctOf(_reservePctController),
            'Dana Sosial': netShu * _pctOf(_socialPctController),
            'Dana Pendidikan': netShu * _pctOf(_educationPctController),
            'Dividen Anggota': netShu * _pctOf(_memberPctController),
            'Pengurus & Pengawas': netShu * _pctOf(_managementPctController),
          };

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(
                      title: _isEdit
                          ? 'Edit SHU ${widget.existing!.fiscalYear}'
                          : 'Hitung SHU Tahunan'),
                  DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(
                      labelText: 'Tahun Fiskal *',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    items: [
                      for (var y = DateTime.now().year; y >= 2020; y--)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged:
                        saving ? null : (value) => setState(() => _year = value!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _totalController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Total SHU (Rp) *',
                      prefixIcon: Icon(Icons.savings_outlined),
                      hintText: 'Laba bersih sebelum pajak',
                    ),
                    validator: Validators.positiveAmount(label: 'Total SHU'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _taxController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Pajak (Rp)',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Text('Alokasi (%)',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  LayoutBuilder(builder: (context, constraints) {
                    final w = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: w,
                          child: _pctField('Cadangan', _reservePctController),
                        ),
                        SizedBox(
                          width: w,
                          child: _pctField('Sosial', _socialPctController),
                        ),
                        SizedBox(
                          width: w,
                          child:
                              _pctField('Pendidikan', _educationPctController),
                        ),
                        SizedBox(
                          width: w,
                          child:
                              _pctField('Dividen Anggota', _memberPctController),
                        ),
                        SizedBox(
                          width: w,
                          child: _pctField(
                              'Pengurus & Pengawas', _managementPctController),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pratinjau Alokasi',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 6),
                          Text('Net SHU: ${AppFormatters.rupiah(netShu)}'),
                          const Divider(),
                          for (final a in allocations.entries)
                            if (a.value > 0)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Text(a.key,
                                          overflow: TextOverflow.ellipsis)),
                                  Text(AppFormatters.rupiah(a.value)),
                                ],
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_isEdit)
                    CheckboxListTile(
                      value: _approveDirectly,
                      onChanged: saving
                          ? null
                          : (value) =>
                              setState(() => _approveDirectly = value ?? false),
                      title: const Text('Langsung setujui'),
                      subtitle: Text(_approveDirectly
                          ? 'Setelah simpan, tinggal tekan Distribusikan'
                          : 'Tersimpan sebagai draft (perlu disetujui dulu)'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  TextFormField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving ? null : _submit,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.calculate_outlined),
                    label: Text(saving
                        ? 'Menyimpan...'
                        : _isEdit
                            ? 'Simpan Perubahan'
                            : _approveDirectly
                                ? 'Simpan & Setujui'
                                : 'Simpan Draft'),
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
