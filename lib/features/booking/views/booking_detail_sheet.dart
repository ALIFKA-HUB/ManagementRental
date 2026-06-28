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
    final authVM = context.read<AuthViewModel>();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Row(
                  children: [
                    Expanded(child: Text(booking.customerName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
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
                _DetailRow(label: 'Rute', value: booking.routes.join(' → ')),
                _DetailRow(label: 'Harga', value: currency.format(booking.rentalPrice)),
                _DetailRow(label: 'Pembayaran', value: booking.paymentStatus.label),
                if (booking.notes != null && booking.notes!.isNotEmpty)
                  _DetailRow(label: 'Catatan', value: booking.notes!),

                const SizedBox(height: 20),

                // Actions — admin only
                if (isAdmin) ...[
                  if (booking.bookingStatus == BookingStatus.upcoming ||
                      booking.bookingStatus == BookingStatus.active)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Batalkan Booking'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Batalkan Booking?'),
                            content: const Text('Kendaraan dan supir akan diset kembali ke status awal.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Batalkan', style: TextStyle(color: AppColors.error))),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          final vm = context.read<BookingViewModel>();
                          final ok = await vm.cancelBooking(
                            booking.bookingId,
                            authVM.currentUser!.userId,
                            authVM.currentUser!.displayName,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (!ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(vm.errorMessage ?? 'Gagal'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        }
                      },
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
