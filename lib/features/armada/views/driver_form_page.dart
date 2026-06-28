import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_button.dart';
import 'package:rentalin/core/widgets/app_input.dart';
import 'package:rentalin/data/models/driver_model.dart';
import 'package:rentalin/features/armada/viewmodels/driver_viewmodel.dart';

class DriverFormPage extends StatefulWidget {
  final DriverModel? driver; // null = tambah, non-null = edit

  const DriverFormPage({super.key, this.driver});

  @override
  State<DriverFormPage> createState() => _DriverFormPageState();
}

class _DriverFormPageState extends State<DriverFormPage> {
  final _nameCtrl = TextEditingController();
  final _codeIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;

  bool get _isEdit => widget.driver != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.driver!.name;
      _codeIdCtrl.text = widget.driver!.codeId;
      _phoneCtrl.text = widget.driver!.phone;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeIdCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_nameCtrl.text.isEmpty || _codeIdCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama, Kode ID, dan No HP wajib diisi.')),
      );
      return;
    }

    if (!_isEdit && (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password wajib diisi untuk supir baru.')),
      );
      return;
    }

    final vm = context.read<DriverViewModel>();
    bool ok;

    if (_isEdit) {
      ok = await vm.updateDriver(
        driver: widget.driver!,
        name: _nameCtrl.text.trim(),
        codeId: _codeIdCtrl.text.trim().toUpperCase(),
        phone: _phoneCtrl.text.trim(),
      );
    } else {
      ok = await vm.addDriver(
        name: _nameCtrl.text.trim(),
        codeId: _codeIdCtrl.text.trim().toUpperCase(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Gagal menyimpan.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DriverViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Supir' : 'Tambah Supir')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppInput(label: 'Nama Lengkap', controller: _nameCtrl, hint: 'Budi Santoso'),
            const SizedBox(height: 16),

            AppInput(label: 'Kode ID Supir', controller: _codeIdCtrl, hint: 'DRV001'),
            const SizedBox(height: 16),

            AppInput(label: 'Nomor HP', controller: _phoneCtrl, hint: '08123456789', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),

            if (!_isEdit) ...[
              AppInput(label: 'Email Login', controller: _emailCtrl, hint: 'supir@rentalin.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              AppInput(
                label: 'Password',
                controller: _passwordCtrl,
                obscureText: !_passwordVisible,
                suffixIcon: IconButton(
                  icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Akun ini digunakan supir untuk login ke aplikasi.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_isEdit) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Email dan password tidak bisa diubah dari sini.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 12),
            AppButton(
              label: _isEdit ? 'Simpan Perubahan' : 'Tambah Supir',
              onPressed: vm.isLoading ? null : _onSave,
              isLoading: vm.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
