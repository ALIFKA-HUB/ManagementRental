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

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduleViewModel()..loadMonth(DateTime.now()),
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
      appBar: AppBar(title: const Text('Jadwal')),
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
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              markerDecoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            onDaySelected: (selected, focused) {
              vm.selectDay(selected, focused);
            },
            onPageChanged: (focused) {
              vm.loadMonth(focused);
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

          // List booking untuk hari terpilih
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.selectedDayBookings.isEmpty
                    ? const AppEmptyState(
                        title: 'Tidak ada jadwal',
                        icon: Icons.event_available,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: vm.selectedDayBookings.length,
                        separatorBuilder: (_, _a) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final b = vm.selectedDayBookings[i];
                          return _ScheduleBookingCard(booking: b, isAdmin: isAdmin);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'schedule_fab',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text('Buat Booking'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => BookingViewModel()..loadActiveBookings(),
                    child: const BookingFormPage(),
                  ),
                ),
              ).then((_) => vm.loadMonth(vm.focusedDay)),
            )
          : null,
    );
  }
}

class _ScheduleBookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isAdmin;

  const _ScheduleBookingCard({required this.booking, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm', 'id');

    return Card(
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
                    Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${booking.vehicleName} · ${booking.driverName}', style: Theme.of(context).textTheme.bodySmall),
                    if (booking.routes.isNotEmpty)
                      Text(booking.routes.join(' → '), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey), overflow: TextOverflow.ellipsis),
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
