import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final _col = FirebaseFirestore.instance.collection('customers');

  Future<List<CustomerModel>> searchByName(String query) async {
    if (query.isEmpty) return [];
    final snap = await _col
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(5)
        .get();
    return snap.docs.map(CustomerModel.fromFirestore).toList();
  }

  Future<void> upsertCustomer(String name, String phone) async {
    final snap = await _col.where('phone', isEqualTo: phone).limit(1).get();
    final now = DateTime.now();

    if (snap.docs.isNotEmpty) {
      await _col.doc(snap.docs.first.id).update({
        'bookingCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });
    } else {
      await _col.add(CustomerModel(
        customerId: '',
        name: name,
        phone: phone,
        bookingCount: 1,
        createdAt: now,
        updatedAt: now,
      ).toFirestore());
    }
  }
}
