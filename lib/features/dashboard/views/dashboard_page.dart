import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/theme/app_dimens.dart';
import 'package:rentalin/core/widgets/app_chip.dart';
import 'package:rentalin/core/widgets/app_section_header.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/features/armada/views/armada_page.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:rentalin/features/booking/views/booking_form_page.dart';
import 'package:rentalin/features/booking/views/booking_detail_sheet.dart';
import 'package:rentalin/features/dashboard/viewmodels/dashboard_viewmodel.dart';

class DashboardPage extends StatelessWidget {
  final VoidCallback? onGoToArmada;
  const DashboardPage({super.key, this.onGoToArmada});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel()..load(),
      child: _DashboardContent(onGoToArmada: onGoToArmada),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final VoidCallback? onGoToArmada;
  const _DashboardContent({this.onGoToArmada});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final auth = context.watch<AuthViewModel>();
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final now = DateTime.now();
    final dateFmt = DateFormat('EEEE, dd MMMM yyyy', 'id');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: vm.isLoading && vm.stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: vm.load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile Card ─────────────────────────────────────
                    _ProfileCard(
                      name: auth.currentUser?.displayName ?? 'Admin',
                      role: auth.currentUser?.role.name.toUpperCase() ?? 'ADMIN',
                      date: dateFmt.format(now),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Revenue ──────────────────────────────────────────
                    if (vm.stats != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _RevenueCard(
                              label: 'Pendapatan Hari Ini',
                              value: currency.format(vm.stats!.todayRevenue),
                              icon: Icons.trending_up_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _RevenueCard(
                              label: 'Pendapatan Bulan Ini',
                              value: currency.format(vm.stats!.monthRevenue),
                              icon: Icons.calendar_month_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Stat grid ──────────────────────────────────────
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.7,
                        children: [
                          _StatCard(
                            label: 'Booking Aktif',
                            value: '${vm.stats!.activeBookings}',
                            icon: Icons.receipt_long_rounded,
                            accent: AppColors.primary,
                          ),
                          _StatCard(
                            label: 'Belum Lunas',
                            value: '${vm.stats!.pendingPayment}',
                            icon: Icons.payments_outlined,
                            accent: AppColors.warning,
                          ),
                          _StatCard(
                            label: 'Kendaraan Siap',
                            value: '${vm.stats!.readyVehicles}/${vm.stats!.totalVehicles}',
                            icon: Icons.directions_car_rounded,
                            accent: AppColors.success,
                          ),
                          _StatCard(
                            label: 'Supir Standby',
                            value: '${vm.stats!.standbyDrivers}/${vm.stats!.totalDrivers}',
                            icon: Icons.person_rounded,
                            accent: AppColors.secondary,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // ── Quick Actions ────────────────────────────────────
                    const AppSectionHeader(title: 'Aksi Cepat'),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Buat Booking',
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
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.directions_car_outlined,
                            label: 'Kelola Armada',
                            onTap: onGoToArmada ?? () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ArmadaPage()),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Jadwal Hari Ini ──────────────────────────────────
                    AppSectionHeader(
                      title: 'Jadwal Hari Ini',
                      trailing: vm.upcomingToday.isEmpty
                          ? null
                          : Text('${vm.upcomingToday.length} trip',
                              style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (vm.upcomingToday.isEmpty)
                      _EmptyToday()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vm.upcomingToday.length,
                        separatorBuilder: (_, _a) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final b = vm.upcomingToday[i];
                          return _TodayBookingCard(
                            booking: b,
                            onTap: () {
                              final dashVm = context.read<DashboardViewModel>();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => ChangeNotifierProvider(
                                  create: (_) => BookingViewModel()..loadActiveBookings(),
                                  child: BookingDetailSheet(booking: b, isAdmin: true),
                                ),
                              ).then((_) => dashVm.load());
                            },
                          );
                        },
                      ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Logout ───────────────────────────────────────────
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        foregroundColor: AppColors.error,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text('Keluar'),
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
                    const SizedBox(height: AppSpacing.xl),
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

  const _RevenueCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondaryLight, size: 18),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatCard({required this.label, required this.value, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: theme.textTheme.titleLarge),
                Text(label, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
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
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.onSurface, size: 26),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: theme.textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, color: AppColors.textSecondaryLight, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text('Tidak ada jadwal hari ini', style: theme.textTheme.bodyMedium),
        ],
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
    final theme = Theme.of(context);
    final timeFmt = DateFormat('HH:mm', 'id');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Column(
                children: [
                  Text(timeFmt.format(booking.startDateTime),
                      style: theme.textTheme.titleSmall),
                  Icon(Icons.more_vert, size: 14, color: theme.colorScheme.outline),
                  Text(timeFmt.format(booking.endDateTime), style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 3,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.customerName, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text('${booking.vehicleName} · ${booking.driverName}',
                        style: theme.textTheme.bodySmall),
                    if (booking.routes.isNotEmpty)
                      Text(booking.routes.join(' → '),
                          style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppChip(label: booking.bookingStatus.label),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  final String date;

  const _ProfileCard({required this.name, required this.role, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceMutedLight,
            child: Icon(Icons.person, size: 32, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, $name! 👋', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(date, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              role,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
