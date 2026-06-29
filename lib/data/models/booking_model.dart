import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { unpaid, dp, paid }

enum BookingStatus { upcoming, active, completed, cancelled }

extension PaymentStatusExt on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.unpaid: return 'Belum Bayar';
      case PaymentStatus.dp: return 'DP';
      case PaymentStatus.paid: return 'Lunas';
    }
  }
  String get value => name;
}

extension BookingStatusExt on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.upcoming: return 'Upcoming';
      case BookingStatus.active: return 'Aktif';
      case BookingStatus.completed: return 'Selesai';
      case BookingStatus.cancelled: return 'Dibatalkan';
    }
  }
  String get value => name;
}

class BookingModel {
  final String bookingId;

  // Customer (denormalized)
  final String customerName;
  final String customerPhone;

  // Vehicle (denormalized)
  final String vehicleId;
  final String vehicleName;
  final String vehiclePlate;

  // Driver (denormalized)
  final String driverId;
  final String driverName;

  // Trip info
  final List<String> routes;
  final DateTime startDateTime;
  final DateTime endDateTime;

  // Financial
  final double rentalPrice;
  final PaymentStatus paymentStatus;

  // Status
  final BookingStatus bookingStatus;

  /// M-8: Compute effective status from current time — no scheduler needed.
  /// upcoming → active when startDateTime <= now < endDateTime.
  BookingStatus get effectiveStatus {
    if (bookingStatus == BookingStatus.completed || bookingStatus == BookingStatus.cancelled) {
      return bookingStatus;
    }
    final now = DateTime.now();
    if (bookingStatus == BookingStatus.upcoming &&
        !now.isBefore(startDateTime) &&
        now.isBefore(endDateTime)) {
      return BookingStatus.active;
    }
    return bookingStatus;
  }

  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.bookingId,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehiclePlate,
    required this.driverId,
    required this.driverName,
    required this.routes,
    required this.startDateTime,
    required this.endDateTime,
    required this.rentalPrice,
    required this.paymentStatus,
    required this.bookingStatus,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookingModel(
      bookingId: doc.id,
      customerName: d['customerName'] ?? '',
      customerPhone: d['customerPhone'] ?? '',
      vehicleId: d['vehicleId'] ?? '',
      vehicleName: d['vehicleName'] ?? '',
      vehiclePlate: d['vehiclePlate'] ?? '',
      driverId: d['driverId'] ?? '',
      driverName: d['driverName'] ?? '',
      routes: List<String>.from(d['routes'] ?? []),
      // H-4: null-safe casts — a missing/pending field won't crash the whole list
      startDateTime: (d['startDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDateTime:   (d['endDateTime']   as Timestamp?)?.toDate() ?? DateTime.now(),
      rentalPrice:   (d['rentalPrice']   as num?)?.toDouble() ?? 0,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.value == d['paymentStatus'],
        orElse: () => PaymentStatus.unpaid,
      ),
      bookingStatus: BookingStatus.values.firstWhere(
        (e) => e.value == d['bookingStatus'],
        orElse: () => BookingStatus.upcoming,
      ),
      notes: d['notes'],
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'vehicleId': vehicleId,
        'vehicleName': vehicleName,
        'vehiclePlate': vehiclePlate,
        'driverId': driverId,
        'driverName': driverName,
        'routes': routes,
        'startDateTime': Timestamp.fromDate(startDateTime),
        'endDateTime': Timestamp.fromDate(endDateTime),
        'rentalPrice': rentalPrice,
        'paymentStatus': paymentStatus.value,
        'bookingStatus': bookingStatus.value,
        'notes': notes,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  BookingModel copyWith({
    PaymentStatus? paymentStatus,
    BookingStatus? bookingStatus,
    DateTime? endDateTime,
    double? rentalPrice,
  }) {
    return BookingModel(
      bookingId: bookingId,
      customerName: customerName,
      customerPhone: customerPhone,
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      vehiclePlate: vehiclePlate,
      driverId: driverId,
      driverName: driverName,
      routes: routes,
      startDateTime: startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      rentalPrice: rentalPrice ?? this.rentalPrice,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
