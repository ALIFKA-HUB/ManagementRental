import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_button.dart';
import 'package:rentalin/core/widgets/app_input.dart';
import 'package:rentalin/data/models/vehicle_model.dart';
import 'package:rentalin/features/armada/viewmodels/vehicle_viewmodel.dart';

class VehicleFormPage extends StatefulWidget {
  final VehicleModel? vehicle; // null = tambah, non-null = edit

  const VehicleFormPage({super.key, this.vehicle});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _nameCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  VehicleCategory _selectedCategory = VehicleCategory.mpv;

  bool get _isEdit => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.vehicle!.name;
      _plateCtrl.text = widget.vehicle!.plateNumber;
      _notesCtrl.text = widget.vehicle!.conditionNotes ?? '';
      _selectedCategory = widget.vehicle!.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _plateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_nameCtrl.text.isEmpty || _plateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan plat nomor wajib diisi.')),
      );
      return;
    }

    final vm = context.read<VehicleViewModel>();
    bool ok;

    if (_isEdit) {
      ok = await vm.updateVehicle(
        vehicle: widget.vehicle!,
        name: _nameCtrl.text.trim(),
        plateNumber: _plateCtrl.text.trim(),
        category: _selectedCategory,
        conditionNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    } else {
      ok = await vm.addVehicle(
        name: _nameCtrl.text.trim(),
        plateNumber: _plateCtrl.text.trim(),
        category: _selectedCategory,
        conditionNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
    final vm = context.watch<VehicleViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder icon kendaraan (no photo upload)
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.directions_car, size: 48, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),

            AppInput(label: 'Nama Kendaraan', controller: _nameCtrl, hint: 'Toyota Hiace'),
            const SizedBox(height: 16),

            AppInput(label: 'Plat Nomor', controller: _plateCtrl, hint: 'B 1234 XY'),
            const SizedBox(height: 16),

            // Kategori dropdown
            DropdownButtonFormField<VehicleCategory>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: VehicleCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 16),

            AppInput(
              label: 'Catatan Kondisi (opsional)',
              controller: _notesCtrl,
              hint: 'Contoh: AC dingin, ban baru',
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            AppButton(
              label: _isEdit ? 'Simpan Perubahan' : 'Tambah Kendaraan',
              onPressed: vm.isLoading ? null : _onSave,
              isLoading: vm.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
