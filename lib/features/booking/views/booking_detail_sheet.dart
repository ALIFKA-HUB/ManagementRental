import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_chip.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/booking/viewmodels/booking_viewmodel.dart';

class BookingDetailSheet extends StatelessWidget {
  final BookingModel booking;
  final bool isAdmin;

  const BookingDetailSheet({super.key, required this.booking, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'id');
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final auth = context.read<AuthViewModel>();
    final vm = context.watch<BookingViewModel>();
    final isActive = booking.bookingStatus == BookingStatus.active ||
        booking.bookingStatus == BookingStatus.upcoming;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.customerName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    AppChip(label: booking.bookingStatus.label),
                  ],
                ),
                const SizedBox(height: 4),
                Text(booking.customerPhone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                const Divider(height: 24),

                _DetailRow(label: 'Kendaraan', value: '${booking.vehicleName} (${booking.vehiclePlate})'),
                _DetailRow(label: 'Supir', value: booking.driverName),
                _DetailRow(label: 'Mulai', value: fmt.format(booking.startDateTime)),
                _DetailRow(label: 'Selesai', value: fmt.format(booking.endDateTime)),
                if (booking.routes.isNotEmpty)
                  _DetailRow(label: 'Rute', value: booking.routes.join(' → ')),
                _DetailRow(label: 'Harga', value: currency.format(booking.rentalPrice)),
                _DetailRow(label: 'Pembayaran', value: booking.paymentStatus.label),
                if (booking.notes != null && booking.notes!.isNotEmpty)
                  _DetailRow(label: 'Catatan', value: booking.notes!),

                if (isAdmin && isActive) ...[
                  const Divider(height: 28),
                  Text('Aksi', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 12),

                  // Update Payment
                  _ActionButton(
                    icon: Icons.payments_outlined,
                    label: 'Update Status Bayar',
                    color: AppColors.primary,
                    textColor: Colors.black,
                    onTap: () => _showPaymentDialog(context, vm, auth),
                  ),
                  const SizedBox(height: 10),

                  // Extend
                  _ActionButton(
                    icon: Icons.schedule_outlined,
                    label: 'Perpanjang Booking',
                    color: Colors.orange,
                    textColor: Colors.white,
                    onTap: () => _showExtendDialog(context, vm, auth),
                  ),
                  const SizedBox(height: 10),

                  // Complete
                  _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Selesaikan Booking',
                    color: AppColors.success,
                    textColor: Colors.white,
                    onTap: () => _confirmComplete(context, vm, auth),
                  ),
                  const SizedBox(height: 10),

                  // Cancel
                  _ActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Batalkan Booking',
                    color: AppColors.error,
                    textColor: Colors.white,
                    onTap: () => _confirmCancel(context, vm, auth),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  void _showPaymentDialog(BuildContext context, BookingViewModel vm, AuthViewModel auth) {
    PaymentStatus selected = booking.paymentStatus;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Update Status Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: PaymentStatus.values.map((p) => ListTile(
              leading: Icon(
                selected == p ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected == p ? AppColors.primary : Colors.grey,
              ),
              title: Text(p.label),
              onTap: () => setState(() => selected = p),
              dense: true,
            )).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (selected == booking.paymentStatus) return;
                final ok = await vm.updatePaymentStatus(
                  bookingId: booking.bookingId,
                  newStatus: selected,
                  uid: auth.currentUser!.userId,
                  displayName: auth.currentUser!.displayName,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(vm.errorMessage ?? 'Gagal'), backgroundColor: AppColors.error),
                  );
                } else if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExtendDialog(BuildContext context, BookingViewModel vm, AuthViewModel auth) {
    final extraCtrl = TextEditingController();
    DateTime? newEnd;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Perpanjang Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(newEnd != null
                    ? DateFormat('dd MMM yyyy, HH:mm', 'id').format(newEnd!)
                    : 'Pilih Waktu Selesai Baru'),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: booking.endDateTime.add(const Duration(hours: 1)),
                    firstDate: booking.endDateTime,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null) return;
                  if (!ctx.mounted) return;
                  final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(booking.endDateTime));
                  if (time == null) return;
                  setState(() => newEnd = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: extraCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tambahan Biaya (Rp)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (newEnd == null) return;
                Navigator.pop(ctx);
                // M-4: strip non-digits to fix Indonesian "10.000" → 10000 parsing
                final extra = double.tryParse(extraCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                final ok = await vm.extendBooking(
                  bookingId: booking.bookingId,
                  newEnd: newEnd!,
                  extraPrice: extra,
                  uid: auth.currentUser!.userId,
                  displayName: auth.currentUser!.displayName,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(vm.errorMessage ?? 'Gagal'), backgroundColor: AppColors.error),
                  );
                } else if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Perpanjang'),
            ),
          ],
        ),
      ),
    // M-5: dispose controller when dialog is dismissed to prevent memory leak
    ).then((_) => extraCtrl.dispose());
  }

  void _confirmComplete(BuildContext context, BookingViewModel vm, AuthViewModel auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Booking?'),
        content: const Text('Kendaraan dan supir akan kembali ke status standby.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Selesaikan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final ok = await vm.completeBooking(booking.bookingId, auth.currentUser!.userId, auth.currentUser!.displayName);
      if (context.mounted) {
        Navigator.pop(context);
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(vm.errorMessage ?? 'Gagal'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _confirmCancel(BuildContext context, BookingViewModel vm, AuthViewModel auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Booking?'),
        content: const Text('Kendaraan dan supir akan kembali ke status standby.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final ok = await vm.cancelBooking(booking.bookingId, auth.currentUser!.userId, auth.currentUser!.displayName);
      if (context.mounted) {
        Navigator.pop(context);
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(vm.errorMessage ?? 'Gagal'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

// ── Helper Widgets ──────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey))),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.textColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onTap,
      ),
    );
  }
}
