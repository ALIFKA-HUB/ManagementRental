import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_button.dart';
import 'package:rentalin/core/widgets/app_input.dart';
import 'package:rentalin/core/widgets/customer_autocomplete.dart';
import 'package:rentalin/core/widgets/app_skeleton.dart';
import 'package:rentalin/core/widgets/multi_stop_input.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/data/models/driver_model.dart';
import 'package:rentalin/data/models/vehicle_model.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/booking/viewmodels/booking_viewmodel.dart';

class BookingFormPage extends StatefulWidget {
  /// TASK-11: when non-null the form runs in EDIT mode — fields are prefilled
  /// and saving calls editBooking instead of createBooking.
  final BookingModel? existing;
  const BookingFormPage({super.key, this.existing});

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  VehicleModel? _selectedVehicle;
  DriverModel? _selectedDriver;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  PaymentStatus _paymentStatus = PaymentStatus.unpaid;
  List<String> _routes = [];

  bool _formDataLoaded = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();

    // TASK-11: prefill scalar fields synchronously in edit mode; the
    // vehicle/driver objects are resolved once loadFormData populates the lists.
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.customerName;
      _phoneCtrl.text = e.customerPhone;
      _priceCtrl.text = e.rentalPrice.toStringAsFixed(0);
      _notesCtrl.text = e.notes ?? '';
      _startDateTime = e.startDateTime;
      _endDateTime = e.endDateTime;
      _paymentStatus = e.paymentStatus;
      _routes = List<String>.from(e.routes);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BookingViewModel>();
      vm.loadFormData().then((_) {
        if (!mounted) return;
        setState(() {
          _formDataLoaded = true;
          // Bind the dropdown selections to the actual instances in the loaded
          // lists (DropdownButton uses identity/equality for its value).
          if (e != null) {
            _selectedVehicle = vm.readyVehicles
                .where((v) => v.vehicleId == e.vehicleId)
                .cast<VehicleModel?>()
                .firstWhere((v) => true, orElse: () => null);
            _selectedDriver = vm.standbyDrivers
                .where((d) => d.driverId == e.driverId)
                .cast<DriverModel?>()
                .firstWhere((d) => true, orElse: () => null);
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    // L-4: capture vm before any await to avoid stale context access
    final vm = context.read<BookingViewModel>();

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;

    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDateTime = result;
        if (_endDateTime != null && _endDateTime!.isBefore(result)) _endDateTime = null;
      } else {
        _endDateTime = result;
      }

      // Hapus pilihan jika kendaraan/supir tidak tersedia di jadwal baru
      final availVehicles = vm.getAvailableVehicles(_startDateTime, _endDateTime,
          excludeBookingId: widget.existing?.bookingId);
      if (_selectedVehicle != null && !availVehicles.any((v) => v.vehicleId == _selectedVehicle!.vehicleId)) {
        _selectedVehicle = null;
      }
      final availDrivers = vm.getAvailableDrivers(_startDateTime, _endDateTime,
          excludeBookingId: widget.existing?.bookingId);
      if (_selectedDriver != null && !availDrivers.any((d) => d.driverId == _selectedDriver!.driverId)) {
        _selectedDriver = null;
      }
    });
  }

  bool _validate() {
    if (_nameCtrl.text.isEmpty) { _showSnack('Nama penyewa wajib diisi.'); return false; }
    if (_phoneCtrl.text.isEmpty) { _showSnack('Nomor HP wajib diisi.'); return false; }
    if (_selectedVehicle == null) { _showSnack('Pilih kendaraan.'); return false; }
    if (_selectedDriver == null) { _showSnack('Pilih supir.'); return false; }
    if (_startDateTime == null) { _showSnack('Pilih waktu mulai.'); return false; }
    if (_endDateTime == null) { _showSnack('Pilih waktu selesai.'); return false; }
    // M-2 (already validated in VM) + explicit end > start guard
    if (!_endDateTime!.isAfter(_startDateTime!)) { _showSnack('Waktu selesai harus setelah waktu mulai.'); return false; }
    // M-3: validate parsed numeric value, not just emptiness
    final parsedPrice = double.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsedPrice == null || parsedPrice <= 0) { _showSnack('Harga sewa tidak valid.'); return false; }
    if (_routes.isEmpty) { _showSnack('Minimal 1 rute harus diisi.'); return false; }
    return true;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onSave() async {
    if (!_validate()) return;

    final vm = context.read<BookingViewModel>();
    final auth = context.read<AuthViewModel>();

    // M-3: strip all non-digits before parsing
    final price = double.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    final bool ok;
    if (_isEdit) {
      ok = await vm.editBooking(
        bookingId: widget.existing!.bookingId,
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        vehicle: _selectedVehicle!,
        driver: _selectedDriver!,
        routes: _routes,
        startDateTime: _startDateTime!,
        endDateTime: _endDateTime!,
        rentalPrice: price,
        paymentStatus: _paymentStatus,
        uid: auth.currentUser!.userId,
        displayName: auth.currentUser!.displayName,
        notes: notes,
      );
    } else {
      ok = await vm.createBooking(
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        vehicle: _selectedVehicle!,
        driver: _selectedDriver!,
        routes: _routes,
        startDateTime: _startDateTime!,
        endDateTime: _endDateTime!,
        rentalPrice: price,
        paymentStatus: _paymentStatus,
        createdBy: auth.currentUser!.userId,
        createdByName: auth.currentUser!.displayName,
        notes: notes,
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
    final vm = context.watch<BookingViewModel>();
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'id');

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Booking' : 'Buat Booking')),
      body: !_formDataLoaded
          ? const _FormSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer
                  Text('Data Penyewa', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  CustomerAutocomplete(nameController: _nameCtrl, phoneController: _phoneCtrl),
                  const SizedBox(height: 12),
                  AppInput(label: 'Nomor HP', controller: _phoneCtrl, hint: '08123456789', keyboardType: TextInputType.phone),

                  const Divider(height: 32),

                  // Waktu (Jadwal dipindah ke atas agar logis)
                  Text('Jadwal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _DateTimeButton(
                          label: 'Mulai',
                          value: _startDateTime != null ? fmt.format(_startDateTime!) : null,
                          onTap: () => _pickDateTime(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateTimeButton(
                          label: 'Selesai',
                          value: _endDateTime != null ? fmt.format(_endDateTime!) : null,
                          onTap: () => _pickDateTime(false),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Kendaraan
                  Text('Kendaraan & Supir', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<VehicleModel>(
                    value: _selectedVehicle,
                    hint: Text((_startDateTime == null || _endDateTime == null) ? 'Pilih jadwal dahulu' : 'Pilih Kendaraan'),
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: (_startDateTime == null || _endDateTime == null) ? null : vm.getAvailableVehicles(_startDateTime, _endDateTime, excludeBookingId: widget.existing?.bookingId).map((v) => DropdownMenuItem(
                      value: v,
                      child: Text('${v.name} (${v.plateNumber})'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedVehicle = v),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<DriverModel>(
                    value: _selectedDriver,
                    hint: Text((_startDateTime == null || _endDateTime == null) ? 'Pilih jadwal dahulu' : 'Pilih Supir'),
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: (_startDateTime == null || _endDateTime == null) ? null : vm.getAvailableDrivers(_startDateTime, _endDateTime, excludeBookingId: widget.existing?.bookingId).map((d) => DropdownMenuItem(
                      value: d,
                      child: Text('${d.name} (${d.codeId})'),
                    )).toList(),
                    onChanged: (d) => setState(() => _selectedDriver = d),
                  ),

                  const Divider(height: 32),

                  // Rute
                  MultiStopInput(initialRoutes: _routes, onChanged: (r) => setState(() => _routes = r)),

                  const Divider(height: 32),

                  // Harga & Pembayaran
                  Text('Harga & Pembayaran', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  AppInput(label: 'Harga Sewa (Rp)', controller: _priceCtrl, keyboardType: TextInputType.number, hint: '500000'),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<PaymentStatus>(
                    value: _paymentStatus,
                    decoration: InputDecoration(
                      labelText: 'Status Pembayaran',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: PaymentStatus.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                    onChanged: (p) => setState(() => _paymentStatus = p!),
                  ),
                  const SizedBox(height: 12),

                  AppInput(label: 'Catatan (opsional)', controller: _notesCtrl, maxLines: 3),

                  const SizedBox(height: 28),

                  AppButton(
                    label: _isEdit ? 'Simpan Perubahan' : 'Buat Booking',
                    onPressed: vm.isLoading ? null : _onSave,
                    isLoading: vm.isLoading,
                  ),
                ],
              ),
            ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DateTimeButton({required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        alignment: Alignment.centerLeft,
      ),
      onPressed: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value ?? 'Pilih...',
            style: TextStyle(fontSize: 13, color: value != null ? null : Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        AppSkeleton(height: 24, width: 120),
        SizedBox(height: 12),
        AppSkeleton(height: 56),
        SizedBox(height: 12),
        AppSkeleton(height: 56),
        SizedBox(height: 32),
        AppSkeleton(height: 24, width: 100),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: AppSkeleton(height: 56)),
            SizedBox(width: 10),
            Expanded(child: AppSkeleton(height: 56)),
          ],
        ),
        SizedBox(height: 32),
        AppSkeleton(height: 24, width: 150),
        SizedBox(height: 12),
        AppSkeleton(height: 56),
        SizedBox(height: 12),
        AppSkeleton(height: 56),
        SizedBox(height: 48),
        AppSkeleton(height: 56),
      ],
    );
  }
}
