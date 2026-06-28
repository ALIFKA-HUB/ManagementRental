import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/features/booking/viewmodels/booking_viewmodel.dart';
import 'booking_list_view.dart';
import 'booking_form_page.dart';
import 'package:rentalin/core/theme/app_colors.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingViewModel()..loadActiveBookings(),
      child: const _BookingPageContent(),
    );
  }
}

class _BookingPageContent extends StatelessWidget {
  const _BookingPageContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<BookingViewModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BookingListView(isHistory: false),
            BookingListView(isHistory: true),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text('Buat Booking'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: const BookingFormPage(),
              ),
            ),
          ).then((_) => vm.loadActiveBookings()),
        ),
      ),
    );
  }
}
