import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_chip.dart';
import 'package:rentalin/core/widgets/app_empty_state.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';
import 'package:rentalin/core/widgets/app_skeleton.dart';

/// TASK-11: all bookings for a single customer (keyed by phone), with a small
/// summary header (total trips + total spend). Read-only.
class CustomerHistoryPage extends StatefulWidget {
  final String customerName;
  final String customerPhone;

  const CustomerHistoryPage({
    super.key,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<CustomerHistoryPage> createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends State<CustomerHistoryPage> {
  final BookingRepository _repo = BookingRepository();
  late Future<List<BookingModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getBookingsByCustomerPhone(widget.customerPhone);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final fmt = DateFormat('dd MMM yyyy', 'id');

    return Scaffold(
      appBar: AppBar(title: Text('Riwayat: ${widget.customerName}')),
      body: FutureBuilder<List<BookingModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _HistorySkeleton();
          }
          if (snapshot.hasError) {
            return const AppEmptyState(
              title: 'Gagal memuat riwayat',
              subtitle: 'Periksa koneksi atau konfigurasi index database.',
              icon: Icons.error_outline,
            );
          }
          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return AppEmptyState(
              title: 'Belum ada riwayat',
              subtitle: '${widget.customerName} belum punya booking.',
              icon: Icons.history,
            );
          }

          final total = bookings.fold<double>(0, (s, b) => s + b.rentalPrice);

          return Column(
            children: [
              // Summary header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _SummaryItem(label: 'Total Booking', value: '${bookings.length}'),
                    const SizedBox(width: 24),
                    _SummaryItem(label: 'Total Nilai', value: currency.format(total)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: bookings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final b = bookings[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${b.vehicleName} (${b.vehiclePlate})',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              AppChip(label: b.effectiveStatusLabel),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${fmt.format(b.startDateTime)} - ${fmt.format(b.endDateTime)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(currency.format(b.rentalPrice),
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary header skeleton
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: const AppSkeleton(height: 70, borderRadius: 12),
        ),
        // List skeleton
        const Expanded(
          child: AppListSkeleton(itemCount: 4, height: 100),
        ),
      ],
    );
  }
}
