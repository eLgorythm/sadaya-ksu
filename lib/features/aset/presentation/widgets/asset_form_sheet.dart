import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/app_input_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/entities/aset_entities.dart';
import '../cubit/asset_form_cubit.dart';

/// Sheet pendaftaran/penyuntingan aset tetap.
class AssetFormSheet extends StatefulWidget {
  const AssetFormSheet({super.key, this.asset});

  static Future<bool> show(BuildContext context, {AssetItem? asset}) async {
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => AssetFormSheet(asset: asset),
        ) ??
        false;
  }

  /// Terisi pada mode ubah aset.
  final AssetItem? asset;

  @override
  State<AssetFormSheet> createState() => _AssetFormSheetState();
}

class _AssetFormSheetState extends State<AssetFormSheet> {
  late final AssetFormCubit _cubit = GetIt.I<AssetFormCubit>();
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.asset?.name);
  late final _descController = TextEditingController(
    text: widget.asset?.description,
  );
  late final _costController = TextEditingController(
    text: widget.asset == null
        ? ''
        : AppFormatters.number(widget.asset!.cost.round()),
  );
  late final _salvageController = TextEditingController(
    text: widget.asset == null || widget.asset!.salvageValue == 0
        ? ''
        : AppFormatters.number(widget.asset!.salvageValue.round()),
  );
  late final _lifeController = TextEditingController(
    text: widget.asset == null ? '' : '${widget.asset!.usefulLifeYears}',
  );

  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) _date = widget.asset!.acquisitionDate;
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _descController,
      _costController,
      _salvageController,
      _lifeController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Tanggal Perolehan',
    );
    if (picked != null) setState(() => _date = picked);
  }

  double _parseAmount(String text) =>
      double.tryParse(text.replaceAll('.', '')) ?? 0;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _cubit.save(
      assetId: widget.asset?.id,
      name: _nameController.text,
      description: _descController.text,
      acquisitionDate: _date,
      cost: _parseAmount(_costController.text),
      salvageValue: _parseAmount(_salvageController.text),
      usefulLifeYears: int.tryParse(_lifeController.text) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<AssetFormCubit, AssetFormState>(
        listener: (context, state) {
          switch (state) {
            case AssetFormSuccess():
              SadayaMessage.success(context, 'Aset tercatat di inventaris');
              Navigator.of(context).pop(true);
            case AssetFormFailure(:final message):
              SadayaMessage.error(context, message);
            default:
              break;
          }
        },
        builder: (context, state) {
          final saving = state is AssetFormSaving;
          final cost = _parseAmount(_costController.text);
          final salvage = _parseAmount(_salvageController.text);
          final life = int.tryParse(_lifeController.text) ?? 0;
          final annual = life > 0
              ? ((cost - salvage).clamp(0, double.infinity)) / life
              : 0.0;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(
                    title: widget.asset == null ? 'Tambah Aset' : 'Ubah Aset',
                  ),
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Aset *',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                      hintText: 'mis. Vacuum Frying',
                    ),
                    validator: Validators.required('Nama aset'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: saving ? null : _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Perolehan *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(AppFormatters.date(_date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Nilai Perolehan (Rp) *',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: Validators.positiveAmount(
                      label: 'Nilai perolehan',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _salvageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Nilai Residu (Rp)',
                      prefixIcon: Icon(Icons.savings_outlined),
                      hintText: 'kosongkan bila tidak ada',
                    ),
                    validator: (value) {
                      final v = _parseAmount(value ?? '');
                      if (v < 0) return 'Nilai residu tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lifeController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Umur Pakai (tahun) *',
                      prefixIcon: Icon(Icons.timelapse),
                      hintText: 'mis. 5',
                    ),
                    validator: (value) {
                      final v = int.tryParse(value ?? '') ?? 0;
                      if (v < 1 || v > 50) return 'Umur pakai harus 1-50 tahun';
                      return null;
                    },
                  ),
                  if (annual > 0) ...[
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_down, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Penyusutan ± / tahun')),
                            Text(
                              AppFormatters.rupiah(annual),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan',
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      saving
                          ? 'Menyimpan...'
                          : widget.asset == null
                          ? 'Simpan'
                          : 'Simpan Perubahan',
                    ),
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
