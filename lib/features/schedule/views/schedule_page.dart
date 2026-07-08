import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:rentalin/core/theme/app_colors.dart';
import 'package:rentalin/core/widgets/app_chip.dart';
import 'package:rentalin/core/widgets/app_empty_state.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:rentalin/features/booking/views/booking_detail_sheet.dart';
import 'package:rentalin/features/booking/views/booking_form_page.dart';
import 'package:rentalin/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:rentalin/features/schedule/viewmodels/schedule_viewmodel.dart';
import 'package:rentalin/core/widgets/app_skeleton.dart';
import 'package:rentalin/core/navigation/app_page_route.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    // TASK-05: pass role + userId so operators load only their own schedule.
    final auth = context.read<AuthViewModel>();
    final isAdmin = auth.currentUser?.isAdmin ?? false;
    final userId = auth.currentUser?.userId;
    return ChangeNotifierProvider(
      create: (_) => ScheduleViewModel(isAdmin: isAdmin, userId: userId)
        ..loadMonth(DateTime.now()),
      child: const _ScheduleContent(),
    );
  }
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScheduleViewModel>();
    final isAdmin = context.watch<AuthViewModel>().currentUser?.isAdmin ?? false;
    final fmt = DateFormat('EEEE, dd MMMM yyyy', 'id');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Buat Booking',
              onPressed: () => Navigator.push(
                context,
                AppPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => BookingViewModel()..loadActiveBookings(),
                    child: const BookingFormPage(),
                  ),
                ),
              ).then((_) => vm.loadMonth(vm.focusedDay)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Kalender
          TableCalendar<BookingModel>(
            locale: 'id_ID',
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: vm.focusedDay,
            selectedDayPredicate: (day) => isSameDay(vm.selectedDay, day),
            eventLoader: vm.getEventsForDay,
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(8),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final activeEvents = events
                    .where((e) => e.bookingStatus != BookingStatus.cancelled)
                    .toList();
                if (activeEvents.isEmpty) return const SizedBox();
                final isSelected = isSameDay(date, vm.selectedDay);
                final markerColor = isSelected ? Colors.white : AppColors.primary;

                if (activeEvents.length > 3) {
                  // Opsi A: 2 titik biasa, 1 tanda plus
                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: markerColor,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: markerColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1.5),
                          child: Text(
                            '+',
                            style: TextStyle(
                              color: markerColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Menampilkan titik bulat biasa sejumlah activeEvents (1, 2, atau 3)
                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        activeEvents.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: markerColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            onDaySelected: (selected, focused) {
              vm.selectDay(selected, focused);
            },
            onPageChanged: (focused) {
              vm.focusedDay = focused;
              Future.delayed(const Duration(milliseconds: 300), () {
                vm.loadMonth(focused);
              });
            },
          ),

          const Divider(height: 1),

          // Header selected day
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fmt.format(vm.selectedDay),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${vm.selectedDayBookings.length} booking',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),

          // List booking untuk hari terpilih dengan animasi transisi halus
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: vm.isLoading
                  ? const _ScheduleSkeleton(key: ValueKey('loading'))
                  : vm.selectedDayBookings.isEmpty
                      ? const AppEmptyState(
                          key: ValueKey('empty'),
                          title: 'Tidak ada jadwal',
                          icon: Icons.event_available,
                        )
                      : RefreshIndicator(
                          key: ValueKey('list_${vm.selectedDay.millisecondsSinceEpoch}'),
                          onRefresh: () => vm.loadMonth(vm.focusedDay),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            itemCount: vm.selectedDayBookings.length,
                            separatorBuilder: (_, a) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final b = vm.selectedDayBookings[i];
                              return _ScheduleBookingCard(
                                key: ValueKey(b.bookingId),
                                booking: b,
                                isAdmin: isAdmin,
                                index: i,
                              );
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleBookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isAdmin;
  final int index;

  const _ScheduleBookingCard({
    super.key,
    required this.booking,
    required this.isAdmin,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm', 'id');

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 50).clamp(0, 150)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1.0 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final vm = context.read<ScheduleViewModel>();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (ctx) => ChangeNotifierProvider(
                create: (_) => BookingViewModel()..loadActiveBookings(),
                child: BookingDetailSheet(booking: booking, isAdmin: isAdmin),
              ),
            ).then((_) => vm.loadMonth(vm.focusedDay));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Time indicator
                Column(
                  children: [
                    Text(timeFmt.format(booking.startDateTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Icon(Icons.more_vert, size: 14, color: Colors.grey),
                    Text(timeFmt.format(booking.endDateTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 12),
                Container(width: 3, height: 50, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          AppChip(label: booking.effectiveStatusLabel),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${booking.vehicleName} • ${booking.driverName}', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 2),
                      if (booking.routes.isNotEmpty)
                        Text(booking.routes.join(' -> '), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleSkeleton extends StatelessWidget {
  const _ScheduleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, _) => const AppSkeleton(height: 85, borderRadius: 14),
    );
  }
}
