import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_chip.dart';
import 'package:rentalin/core/widgets/app_empty_state.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:rentalin/features/booking/views/booking_detail_sheet.dart';
import 'package:rentalin/features/home_operator/viewmodels/operator_home_viewmodel.dart';

class OperatorHomePage extends StatelessWidget {
  const OperatorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final userId = auth.currentUser?.userId ?? '';

    return ChangeNotifierProvider(
      create: (_) => OperatorHomeViewModel()..load(userId),
      child: _OperatorHomeContent(userId: userId),
    );
  }
}

class _OperatorHomeContent extends StatelessWidget {
  final String userId;
  const _OperatorHomeContent({required this.userId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OperatorHomeViewModel>();
    final auth = context.watch<AuthViewModel>();
    final dateFmt = DateFormat('EEEE, dd MMMM yyyy', 'id');
    final timeFmt = DateFormat('HH:mm', 'id');
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, ${auth.currentUser?.displayName ?? 'Operator'}!',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(dateFmt.format(now), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: vm.isLoading && vm.todayBookings.isEmpty && vm.upcomingBookings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => vm.load(userId),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Status Banner ─────────────────────────────────────
                    _StatusBanner(
                      isDriver: vm.isDriver,
                      todayCount: vm.todayBookings.length,
                    ),
                    const SizedBox(height: 20),

                    // ── Jadwal Hari Ini ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text('Jadwal Hari Ini',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        Text('${vm.todayBookings.length} trip',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    vm.todayBookings.isEmpty
                        ? const AppEmptyState(
                            title: 'Tidak ada jadwal hari ini',
                            icon: Icons.event_available,
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: vm.todayBookings.length,
                            separatorBuilder: (_, _a) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final b = vm.todayBookings[i];
                              return _TripCard(
                                booking: b,
                                timeFmt: timeFmt,
                                isHighlighted: i == 0,
                                onTap: () => _openDetail(context, b, vm, userId),
                              );
                            },
                          ),

                    // ── Upcoming (hanya untuk supir) ──────────────────────
                    if (vm.isDriver && vm.upcomingBookings.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Trip Berikutnya',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vm.upcomingBookings.length,
                        separatorBuilder: (_, _a) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final b = vm.upcomingBookings[i];
                          return _TripCard(
                            booking: b,
                            timeFmt: timeFmt,
                            isHighlighted: false,
                            onTap: () => _openDetail(context, b, vm, userId),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Logout ────────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Keluar?'),
                              content: const Text('Apakah kamu yakin ingin keluar dari aplikasi?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Keluar', style: TextStyle(color: AppColors.error)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            context.read<AuthViewModel>().logout();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  void _openDetail(BuildContext context, BookingModel booking, OperatorHomeViewModel vm, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider(
        create: (_) => BookingViewModel()..loadActiveBookings(),
        child: BookingDetailSheet(booking: booking, isAdmin: false),
      ),
    ).then((_) => vm.load(userId));
  }
}

// ── Sub-Widgets ───────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final bool isDriver;
  final int todayCount;

  const _StatusBanner({required this.isDriver, required this.todayCount});

  @override
  Widget build(BuildContext context) {
    final hasTrip = todayCount > 0;
    final color = hasTrip ? AppColors.primary : Colors.grey.shade100;
    final textColor = hasTrip ? Colors.black : Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            hasTrip ? Icons.directions_car : Icons.event_available_outlined,
            color: hasTrip ? Colors.black87 : Colors.grey,
            size: 36,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasTrip ? '$todayCount Trip Hari Ini' : 'Tidak Ada Trip',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                Text(
                  isDriver
                      ? (hasTrip ? 'Siap berangkat!' : 'Istirahat dulu ya 😊')
                      : 'Tampil semua jadwal hari ini',
                  style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final BookingModel booking;
  final DateFormat timeFmt;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _TripCard({
    required this.booking,
    required this.timeFmt,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: isHighlighted ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.customerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  AppChip(label: booking.effectiveStatusLabel),
                ],
              ),
              const SizedBox(height: 8),

              // Waktu
              Row(
                children: [
                  const Icon(Icons.schedule, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${timeFmt.format(booking.startDateTime)} - ${timeFmt.format(booking.endDateTime)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              // Kendaraan
              if (booking.vehicleName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 15, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('${booking.vehicleName} • ${booking.vehiclePlate}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],

              // Rute
              if (booking.routes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.route, size: 15, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.routes.join(' -> '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Customer phone
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(booking.customerPhone, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
