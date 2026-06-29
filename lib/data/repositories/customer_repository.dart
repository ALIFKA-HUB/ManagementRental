import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final _col = FirebaseFirestore.instance.collection('customers');

  Future<List<CustomerModel>> searchByName(String query) async {
    if (query.isEmpty) return [];
    // L-1: query nameLower for case-insensitive prefix search.
    // Requires customers to store a 'nameLower' field = name.toLowerCase().
    final lower = query.toLowerCase();
    final snap = await _col
        .where('nameLower', isGreaterThanOrEqualTo: lower)
        .where('nameLower', isLessThanOrEqualTo: '$lower\uf8ff')
        .limit(5)
        .get();
    return snap.docs.map(CustomerModel.fromFirestore).toList();
  }

  Future<void> upsertCustomer(String name, String phone) async {
    // L-2: key on phone+name to avoid merging distinct people on shared lines.
    final snap = await _col
        .where('phone', isEqualTo: phone)
        .where('nameLower', isEqualTo: name.toLowerCase())
        .limit(1)
        .get();
    final now = DateTime.now();

    try {
      if (snap.docs.isNotEmpty) {
        await _col.doc(snap.docs.first.id).update({
          'bookingCount': FieldValue.increment(1),
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        await _col.add({
          ...CustomerModel(
            customerId: '',
            name: name,
            phone: phone,
            bookingCount: 1,
            createdAt: now,
            updatedAt: now,
          ).toFirestore(),
          'nameLower': name.toLowerCase(), // for L-1 search
        });
      }
    } catch (e) {
      // L-2: log but don't rethrow — booking already committed
      debugPrint('upsertCustomer failed (non-critical): $e');
    }
  }
}
