import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_chip.dart';
import 'package:rentalin/core/widgets/app_empty_state.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:rentalin/core/widgets/app_skeleton.dart';
import 'booking_detail_sheet.dart';

class BookingListView extends StatefulWidget {
  final bool isHistory;
  const BookingListView({super.key, required this.isHistory});

  @override
  State<BookingListView> createState() => _BookingListViewState();
}

class _BookingListViewState extends State<BookingListView> {
  // TASK-10: drives infinite scroll on the history tab.
  final ScrollController _historyScrollController = ScrollController();

  // TASK-11: debounced search on the active tab.
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.isHistory) {
      _historyScrollController.addListener(_onHistoryScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isHistory) {
        context.read<BookingViewModel>().loadHistoryBookings();
      }
    });
  }

  @override
  void dispose() {
    _historyScrollController.dispose();
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onHistoryScroll() {
    // Prefetch the next page ~300px before the bottom for a seamless scroll.
    if (_historyScrollController.position.pixels >=
        _historyScrollController.position.maxScrollExtent - 300) {
      context.read<BookingViewModel>().loadMoreHistory();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) context.read<BookingViewModel>().searchBookings(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    final isAdmin = context.watch<AuthViewModel>().currentUser?.isAdmin ?? false;

    if (widget.isHistory) {
      return _buildHistoryTab(vm, isAdmin);
    }
    return _buildActiveTab(vm, isAdmin);
  }

  // ── Tab Aktif ──────────────────────────────────────────────────────────────

  Widget _buildActiveTab(BookingViewModel vm, bool isAdmin) {
    return Column(
      children: [
        // TASK-11: search by customer / plate / driver.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari nama, plat, atau supir...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _debounce?.cancel();
                        vm.searchBookings('');
                        setState(() {});
                      },
                    ),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BookingFilter.values.map((f) {
                final labels = {
                  BookingFilter.all: 'Semua',
                  BookingFilter.today: 'Hari Ini',
                  BookingFilter.thisWeek: 'Minggu Ini',
                };
                final isSelected = vm.currentFilter == f;
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    showCheckmark: false,
                    label: Text(labels[f]!),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
                    side: BorderSide(
                      color: isSelected 
                          ? AppColors.primary 
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    onSelected: (_) => vm.filterBookings(f),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Expanded(
          child: vm.isLoading && vm.filteredBookings.isEmpty
              ? const AppListSkeleton(height: 140)
              : vm.filteredBookings.isEmpty
                  ? const AppEmptyState(
                      title: 'Tidak ada booking aktif',
                      subtitle: 'Buat booking baru dengan tombol +',
                      icon: Icons.receipt_long_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: vm.loadActiveBookings,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: vm.filteredBookings.length,
                        separatorBuilder: (_, _a) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final b = vm.filteredBookings[i];
                          return _BookingCard(booking: b, isAdmin: isAdmin);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // ── Tab Riwayat ────────────────────────────────────────────────────────────

  Widget _buildHistoryTab(BookingViewModel vm, bool isAdmin) {
    if (vm.isLoadingHistory && vm.historyBookings.isEmpty) {
      return const AppListSkeleton(height: 140);
    }
    if (vm.historyBookings.isEmpty) {
      return const AppEmptyState(
        title: 'Belum ada riwayat booking',
        subtitle: 'Booking yang selesai atau dibatalkan akan muncul di sini',
        icon: Icons.history,
      );
    }
    // TASK-10: extra trailing slot for the "load more" spinner / end indicator.
    final itemCount = vm.historyBookings.length + (vm.historyHasMore ? 1 : 0);
    return RefreshIndicator(
      onRefresh: vm.loadHistoryBookings,
      child: ListView.separated(
        controller: _historyScrollController,
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        separatorBuilder: (_, _a) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i >= vm.historyBookings.length) {
            // Footer while the next page loads (or waiting for the scroll to
            // trigger it). hasMore == false removes this slot entirely.
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            );
          }
          final b = vm.historyBookings[i];
          return _BookingCard(booking: b, isAdmin: isAdmin);
        },
      ),
    );
  }
}

// ── Card ───────────────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isAdmin;

  const _BookingCard({required this.booking, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM, HH:mm', 'id');
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final vm = context.read<BookingViewModel>();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => ChangeNotifierProvider.value(
              value: vm,
              child: BookingDetailSheet(booking: booking, isAdmin: isAdmin),
            ),
          ).then((_) => vm.loadActiveBookings());
        },
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
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.directions_car, text: '${booking.vehicleName} • ${booking.vehiclePlate}'),
              _InfoRow(icon: Icons.person, text: booking.driverName),
              _InfoRow(icon: Icons.schedule, text: '${fmt.format(booking.startDateTime)} - ${fmt.format(booking.endDateTime)}'),
              if (booking.routes.isNotEmpty)
                _InfoRow(icon: Icons.route, text: booking.routes.join(' -> ')),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppChip(label: booking.paymentStatus.label),
                  Text(currency.format(booking.rentalPrice), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
