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
        titleSpacing: 16,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, ${auth.currentUser?.displayName ?? 'Operator'}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(dateFmt.format(now), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Keluar',
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
          const SizedBox(width: 8),
        ],
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
    final theme = Theme.of(context);
    final isLast = !isHighlighted; // Simplification just to have some line logic, ideally we pass isLast from ListView

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Jam
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(timeFmt.format(booking.startDateTime), style: theme.textTheme.titleSmall),
                Text(timeFmt.format(booking.endDateTime), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Garis Timeline
          Column(
            children: [
              Container(
                width: 12, height: 12,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: isHighlighted ? AppColors.primary : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: (isHighlighted ? AppColors.primary : Colors.grey.shade400).withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Konten
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isHighlighted ? AppColors.primary.withOpacity(0.5) : theme.colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking.customerName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          AppChip(label: booking.effectiveStatusLabel),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (booking.vehicleName.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.directions_car, size: 15, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('${booking.vehicleName} • ${booking.vehiclePlate}',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (booking.routes.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.route, size: 15, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                booking.routes.join(' -> '),
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 15, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(booking.customerPhone, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
