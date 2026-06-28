import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentalin/features/booking/viewmodels/booking_viewmodel.dart';
import 'booking_list_view.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingViewModel()..loadActiveBookings(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const BookingListView(),
      ),
    );
  }
}
