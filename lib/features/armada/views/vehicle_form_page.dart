import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  XFile? _pickedImage;
  final _picker = ImagePicker();

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

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (img != null) setState(() => _pickedImage = img);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (img != null) setState(() => _pickedImage = img);
              },
            ),
          ],
        ),
      ),
    );
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
        imageFile: _pickedImage,
      );
    } else {
      ok = await vm.addVehicle(
        name: _nameCtrl.text.trim(),
        plateNumber: _plateCtrl.text.trim(),
        category: _selectedCategory,
        conditionNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        imageFile: _pickedImage,
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
            // Image picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(_pickedImage!.path, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 36, color: Colors.grey),
                            SizedBox(height: 6),
                            Text('Tambah Foto', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            AppInput(label: 'Nama Kendaraan', controller: _nameCtrl, hint: 'Toyota Hiace'),
            const SizedBox(height: 16),

            AppInput(label: 'Plat Nomor', controller: _plateCtrl, hint: 'B 1234 XY'),
            const SizedBox(height: 16),

            // Kategori dropdown
            DropdownButtonFormField<VehicleCategory>(
              value: _selectedCategory,
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
