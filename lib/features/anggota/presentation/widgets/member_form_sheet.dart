import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/sadaya_message.dart';
import '../../domain/entities/member_entity.dart';
import '../cubit/member_form_cubit.dart';

class MemberFormSheet extends StatefulWidget {
  const MemberFormSheet({super.key, this.member});

  final MemberEntity? member;

  static Future<bool> show(BuildContext context, {MemberEntity? member}) async {
    return await showSadayaBottomSheet<bool>(
          context: context,
          builder: (_) => MemberFormSheet(member: member),
        ) ??
        false;
  }

  @override
  State<MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<MemberFormSheet> {
  late final MemberFormCubit _cubit = GetIt.I<MemberFormCubit>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  final _formKey = GlobalKey<FormState>();
  DateTime? _joinDate;

  bool get _isEdit => widget.member != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name);
    _addressController = TextEditingController(text: widget.member?.address);
    _phoneController = TextEditingController(text: widget.member?.phone);
    _notesController = TextEditingController(text: widget.member?.notes);
    _joinDate = widget.member?.joinDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Tanggal Bergabung',
    );
    if (picked != null) setState(() => _joinDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_joinDate == null) return;
    FocusScope.of(context).unfocus();
    _cubit.save(
      id: widget.member?.id,
      memberNumber: widget.member?.memberNumber ?? 0,
      name: _nameController.text,
      address: _addressController.text,
      phone: _phoneController.text,
      joinDate: _joinDate!,
      notes: _notesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<MemberFormCubit, MemberFormState>(
        listener: (context, state) {
          switch (state) {
            case MemberFormSuccess(:final isEdit):
              SadayaMessage.success(
                context,
                isEdit ? 'Anggota diperbarui' : 'Anggota ditambahkan',
              );

              /// Tutup sheet sendiri dengan hasil true —
              /// halaman pemanggil yang me-reload daftar.
              Navigator.of(context).pop(true);
            case MemberFormFailure(:final message):
              SadayaMessage.error(context, message);
            default:
              break;
          }
        },
        builder: (context, state) {
          final saving = state is MemberFormSaving;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(
                    title: _isEdit
                        ? 'Edit Anggota #${widget.member!.memberNumber}'
                        : 'Tambah Anggota Baru',
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Anggota *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: Validators.required('Nama anggota'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Alamat',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'No. Telepon',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: Validators.optionalPhone,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: saving ? null : _pickJoinDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Bergabung *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _joinDate == null
                            ? 'Pilih tanggal'
                            : AppFormatters.date(_joinDate!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
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
