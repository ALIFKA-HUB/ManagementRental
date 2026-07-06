import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/theme/app_dimens.dart';
import 'package:rentalin/core/widgets/app_empty_state.dart';
import 'package:rentalin/core/widgets/app_skeleton.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/features/income/viewmodels/income_viewmodel.dart';

class IncomePage extends StatelessWidget {
  const IncomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IncomeViewModel()..load(),
      child: const _IncomeContent(),
    );
  }
}

class _IncomeContent extends StatelessWidget {
  const _IncomeContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IncomeViewModel>();
    final currency =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemasukan'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter chips
          _FilterBar(currentFilter: vm.currentFilter, vm: vm),
          Expanded(
            child: vm.isLoading
                ? _buildSkeleton()
                : vm.errorMessage != null
                    ? AppEmptyState(
                        title: 'Gagal memuat data',
                        subtitle: vm.errorMessage!,
                        icon: Icons.error_outline,
                      )
                    : _buildContent(context, vm, currency),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: AppSkeleton(height: 220),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppListSkeleton(itemCount: 3, height: 80),
        ),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context, IncomeViewModel vm, NumberFormat currency) {
    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Summary cards
          _SummaryRow(vm: vm, currency: currency),
          const SizedBox(height: AppSpacing.lg),

          // Chart
          if (vm.dailyRevenues.isNotEmpty) ...[
            _RevenueChart(vm: vm, currency: currency),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Booking list
          Text(
            'Detail Booking (${vm.bookingCount})',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          if (vm.paidBookings.isEmpty)
            const AppEmptyState(
              title: 'Tidak ada booking selesai',
              subtitle: 'Belum ada booking lunas dalam rentang ini.',
              icon: Icons.receipt_long_outlined,
            )
          else
            ...vm.paidBookings.map((b) => _BookingTile(b: b, currency: currency)),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final IncomeFilter currentFilter;
  final IncomeViewModel vm;
  const _FilterBar({required this.currentFilter, required this.vm});

  @override
  Widget build(BuildContext context) {
    final filters = [
      (IncomeFilter.today, 'Hari Ini'),
      (IncomeFilter.thisWeek, 'Minggu Ini'),
      (IncomeFilter.thisMonth, 'Bulan Ini'),
      (IncomeFilter.threeMonths, '3 Bulan'),
    ];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...filters.map((f) {
              final isSelected = currentFilter == f.$1;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilterChip(
                  label: Text(f.$2),
                  selected: isSelected,
                  onSelected: (_) => vm.setFilter(f.$1),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : null,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }),
            // Custom range chip
            FilterChip(
              label: const Text('Custom'),
              selected: currentFilter == IncomeFilter.custom,
              onSelected: (_) async {
                final now = DateTime.now();
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 2),
                  lastDate: now,
                  initialDateRange: vm.currentFilter == IncomeFilter.custom
                      ? DateTimeRange(
                          start: vm.customFrom ?? now,
                          end: vm.customTo ?? now)
                      : null,
                );
                if (range != null) {
                  vm.setCustomRange(range.start, range.end);
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: currentFilter == IncomeFilter.custom ? AppColors.primary : null,
                fontWeight: currentFilter == IncomeFilter.custom
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IncomeViewModel vm;
  final NumberFormat currency;
  const _SummaryRow({required this.vm, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryCard(
          label: 'Total Pemasukan',
          value: currency.format(vm.totalRevenue),
          icon: Icons.payments_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          label: 'Rata-rata/Hari',
          value: currency.format(vm.avgPerDay),
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          label: 'Jumlah Booking',
          value: '${vm.bookingCount}',
          icon: Icons.receipt_long_rounded,
          color: AppColors.secondary,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatefulWidget {
  final IncomeViewModel vm;
  final NumberFormat currency;
  const _RevenueChart({required this.vm, required this.currency});

  @override
  State<_RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<_RevenueChart> {
  @override
  Widget build(BuildContext context) {
    final revenues = widget.vm.dailyRevenues;
    final maxY = revenues.isEmpty
        ? 100.0
        : revenues.map((r) => r.amount).reduce((a, b) => a > b ? a : b) * 1.2;

    final spots = revenues.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.amount);
    }).toList();

    final dateFmt = revenues.length <= 7
        ? DateFormat('dd/MM', 'id')
        : DateFormat('dd', 'id');

    return Container(
      height: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Pendapatan',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Theme.of(context).dividerColor,
                    strokeWidth: 0.8,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: revenues.length > 14
                          ? (revenues.length / 7).ceilToDouble()
                          : 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= revenues.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            dateFmt.format(revenues[idx].date),
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final date = idx < revenues.length
                            ? revenues[idx].date
                            : null;
                        return LineTooltipItem(
                          '${date != null ? DateFormat('dd MMM', 'id').format(date) : ''}\n${widget.currency.format(spot.y)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: revenues.length <= 30,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.primary,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final BookingModel b;
  final NumberFormat currency;
  const _BookingTile({required this.b, required this.currency});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'id');
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${b.vehicleName} • ${fmt.format(b.startDateTime)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Text(
            currency.format(b.rentalPrice),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
