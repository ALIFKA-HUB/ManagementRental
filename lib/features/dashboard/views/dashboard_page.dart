import 'dart:async';
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
import 'package:rentalin/core/widgets/app_skeleton.dart';

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
        titleSpacing: AppSpacing.lg,
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
                  Text(
                    'Halo, ${auth.currentUser?.displayName.isNotEmpty == true ? auth.currentUser!.displayName : 'Admin'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(dateFmt.format(now), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            label: 'btn_logout',
            child: IconButton(
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
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: vm.isLoading && vm.stats == null
          ? const _DashboardSkeleton()
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (vm.stats != null) ...[
                    // HERO METRIC
                    Semantics(
                      label: 'card_pendapatan',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pendapatan Hari Ini', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(currency.format(vm.stats!.todayRevenue), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // SECONDARY METRICS (Marquee)
                    ContinuousMarquee(
                      children: [
                        _CompactStat(label: 'Bulan Ini', value: currency.format(vm.stats!.monthRevenue), icon: Icons.calendar_month),
                        _CompactStat(label: 'Booking Aktif', value: '${vm.stats!.activeBookings}', icon: Icons.receipt_long, color: AppColors.primary),
                        _CompactStat(label: 'Belum Lunas', value: '${vm.stats!.pendingPayment}', icon: Icons.payments, color: AppColors.warning),
                        _CompactStat(label: 'Mobil Siap', value: '${vm.stats!.readyVehicles}/${vm.stats!.totalVehicles}', icon: Icons.directions_car, color: AppColors.success),
                        _CompactStat(label: 'Supir Standby', value: '${vm.stats!.standbyDrivers}/${vm.stats!.totalDrivers}', icon: Icons.person, color: AppColors.secondary),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),

                  // COMMAND ROW (Quick Actions)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 500;
                      
                      if (isWide) {
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _ActionCard(
                                  title: 'Buat Booking',
                                  subtitle: 'Transaksi Baru',
                                  icon: Icons.add_circle_outline,
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
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _ActionCard(
                                  title: 'Kelola Armada',
                                  subtitle: 'Cek Kendaraan',
                                  icon: Icons.directions_car_outlined,
                                  color: AppColors.secondary,
                                  onTap: onGoToArmada ?? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ArmadaPage()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Column(
                          children: [
                            _ActionCard(
                              title: 'Buat Booking',
                              subtitle: 'Transaksi Baru',
                              icon: Icons.add_circle_outline,
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
                            const SizedBox(height: AppSpacing.md),
                            _ActionCard(
                              title: 'Kelola Armada',
                              subtitle: 'Cek Kendaraan',
                              icon: Icons.directions_car_outlined,
                              color: AppColors.secondary,
                              onTap: onGoToArmada ?? () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ArmadaPage()),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // TIMELINE JADWAL
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
                    ...vm.upcomingToday.asMap().entries.map((e) {
                      final isLast = e.key == vm.upcomingToday.length - 1;
                      return _TimelineBookingCard(
                        booking: e.value,
                        isLast: isLast,
                        onTap: () {
                          final dashVm = context.read<DashboardViewModel>();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => ChangeNotifierProvider(
                              create: (_) => BookingViewModel()..loadActiveBookings(),
                              child: BookingDetailSheet(booking: e.value, isAdmin: true),
                            ),
                          ).then((_) => dashVm.load());
                        },
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CompactStat({required this.label, required this.value, required this.icon, this.color = AppColors.textSecondaryLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Hari Ini Kosong', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Belum ada jadwal trip yang harus dijalankan hari ini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}

class _TimelineBookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineBookingCard({required this.booking, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat('HH:mm', 'id');

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
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                )
              else 
                const Expanded(child: SizedBox()),
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
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(booking.customerName, style: theme.textTheme.titleSmall)),
                          AppChip(label: booking.effectiveStatusLabel),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${booking.vehicleName} • ${booking.driverName}', style: theme.textTheme.bodySmall),
                      if (booking.routes.isNotEmpty)
                        Text(booking.routes.join(' -> '), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight), overflow: TextOverflow.ellipsis),
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

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const AppSkeleton(height: 140, borderRadius: 16),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 78,
          child: PageView.builder(
            controller: PageController(initialPage: 1, viewportFraction: 0.7),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: AppSkeleton(height: 78, borderRadius: 12),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Row(
          children: [
            Expanded(child: AppSkeleton(height: 56, borderRadius: 30)),
            SizedBox(width: 16),
            Expanded(child: AppSkeleton(height: 56, borderRadius: 30)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppSkeleton(height: 30, width: 150),
        const SizedBox(height: AppSpacing.md),
        const AppListSkeleton(itemCount: 3, height: 100),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: theme.colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}

class ContinuousMarquee extends StatefulWidget {
  final List<Widget> children;
  const ContinuousMarquee({super.key, required this.children});

  @override
  State<ContinuousMarquee> createState() => _ContinuousMarqueeState();
}

class _ContinuousMarqueeState extends State<ContinuousMarquee> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.children.length * 10000;
    _pageController = PageController(initialPage: initialPage, viewportFraction: 0.7);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  void _pauseAutoScroll() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Listener(
        onPointerDown: (_) => _pauseAutoScroll(),
        onPointerUp: (_) => _startAutoScroll(),
        onPointerCancel: (_) => _startAutoScroll(),
        child: PageView.builder(
          controller: _pageController,
          itemBuilder: (context, index) {
            final len = widget.children.length;
            final normalizedIndex = index % len;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: widget.children[normalizedIndex],
            );
          },
        ),
      ),
    );
  }
}
