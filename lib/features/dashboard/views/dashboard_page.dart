import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_chip.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:rentalin/features/booking/views/booking_form_page.dart';
import 'package:rentalin/features/booking/views/booking_detail_sheet.dart';
import 'package:rentalin/features/dashboard/viewmodels/dashboard_viewmodel.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel()..load(),
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final auth = context.watch<AuthViewModel>();
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final now = DateTime.now();
    final dateFmt = DateFormat('EEEE, dd MMMM yyyy', 'id');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, ${auth.currentUser?.displayName ?? 'Admin'}! 👋',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(dateFmt.format(now), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: vm.isLoading && vm.stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: vm.load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stat Cards ───────────────────────────────────────
                    if (vm.stats != null) ...[
                      // Revenue row
                      Row(
                        children: [
                          Expanded(
                            child: _RevenueCard(
                              label: 'Pendapatan Hari Ini',
                              value: currency.format(vm.stats!.todayRevenue),
                              icon: Icons.today,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RevenueCard(
                              label: 'Pendapatan Bulan Ini',
                              value: currency.format(vm.stats!.monthRevenue),
                              icon: Icons.calendar_month,
                              color: AppColors.secondary,
                              lightText: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stats grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _StatCard(
                            label: 'Booking Aktif',
                            value: '${vm.stats!.activeBookings}',
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                          _StatCard(
                            label: 'Belum Lunas',
                            value: '${vm.stats!.pendingPayment}',
                            icon: Icons.payments_outlined,
                            color: AppColors.warning,
                          ),
                          _StatCard(
                            label: 'Kendaraan Siap',
                            value: '${vm.stats!.readyVehicles}/${vm.stats!.totalVehicles}',
                            icon: Icons.directions_car,
                            color: AppColors.success,
                          ),
                          _StatCard(
                            label: 'Supir Standby',
                            value: '${vm.stats!.standbyDrivers}/${vm.stats!.totalDrivers}',
                            icon: Icons.person,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Quick Actions ─────────────────────────────────────
                    Text('Aksi Cepat', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.add_circle,
                            label: 'Buat Booking',
                            color: AppColors.primary,
                            onTap: () {
                              final bookingVm = BookingViewModel()..loadActiveBookings();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: bookingVm,
                                    child: const BookingFormPage(),
                                  ),
                                ),
                              ).then((_) => vm.load());
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.directions_car,
                            label: 'Kelola Armada',
                            color: AppColors.secondary,
                            onTap: () {
                              // Navigate to Armada tab (index 3)
                              final scaffold = Scaffold.of(context);
                              if (scaffold.hasDrawer) scaffold.openDrawer();
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Booking Hari Ini ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Jadwal Hari Ini',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (vm.upcomingToday.isNotEmpty)
                          Text('${vm.upcomingToday.length} trip', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (vm.upcomingToday.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Tidak ada jadwal hari ini', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vm.upcomingToday.length,
                        separatorBuilder: (_, _a) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final b = vm.upcomingToday[i];
                          return _TodayBookingCard(booking: b, onTap: () {
                            final dashVm = context.read<DashboardViewModel>();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (_) => ChangeNotifierProvider(
                                create: (_) => BookingViewModel()..loadActiveBookings(),
                                child: BookingDetailSheet(booking: b, isAdmin: true),
                              ),
                            ).then((_) => dashVm.load());
                          });
                        },
                      ),

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
}

// ── Sub-Widgets ───────────────────────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool lightText;

  const _RevenueCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.lightText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: lightText ? Colors.white70 : Colors.black54, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: lightText ? Colors.white : Colors.black,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                color: lightText ? Colors.white70 : Colors.black54,
              )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TodayBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _TodayBookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm', 'id');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Column(
                children: [
                  Text(timeFmt.format(booking.startDateTime),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Icon(Icons.more_vert, size: 14, color: Colors.grey),
                  Text(timeFmt.format(booking.endDateTime),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 10),
              Container(width: 3, height: 48, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${booking.vehicleName} · ${booking.driverName}',
                        style: Theme.of(context).textTheme.bodySmall),
                    if (booking.routes.isNotEmpty)
                      Text(booking.routes.join(' → '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              AppChip(label: booking.bookingStatus.label),
            ],
          ),
        ),
      ),
    );
  }
}
