import 'package:hive/hive.dart';
import '../customer_model.dart';

class CustomerRepository {
  final Box<CustomerModel> _box;

  CustomerRepository(this._box);

  // Get all customers
  List<CustomerModel> getAllCustomers() {
    return _box.values.where((c) => c.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get customer by ID
  CustomerModel? getCustomerById(String id) {
    try {
      return _box.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Search customers by name or phone
  List<CustomerModel> searchCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    return _box.values
        .where((c) =>
            c.isActive &&
            (c.name.toLowerCase().contains(lowerQuery) ||
                (c.phone?.contains(query) ?? false)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Add customer
  Future<void> addCustomer(CustomerModel customer) async {
    await _box.put(customer.id, customer);
  }

  // Update customer
  Future<void> updateCustomer(CustomerModel customer) async {
    await _box.put(customer.id, customer);
  }

  // Delete customer (soft delete)
  Future<void> deleteCustomer(String id) async {
    final customer = getCustomerById(id);
    if (customer != null) {
      await _box.put(
          id,
          customer.copyWith(
            isActive: false,
            updatedAt: DateTime.now(),
          ));
    }
  }

  // Hard delete
  Future<void> hardDeleteCustomer(String id) async {
    await _box.delete(id);
  }

  // Check if name exists
  bool customerExists(String name, {String? excludeId}) {
    return _box.values.any((c) =>
        c.name.toLowerCase() == name.toLowerCase() &&
        c.id != excludeId &&
        c.isActive);
  }

  // Stream customers
  Stream<List<CustomerModel>> watchCustomers() {
    return _box.watch().map((_) => getAllCustomers());
  }
}
