import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

class OrderProvider with ChangeNotifier {
  final OrderRepository repository;

  List<Order> _orders = [];
  bool _isLoading = false;

  OrderProvider({required this.repository});

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  final List<Map<String, dynamic>> _generatedReports = [];
  List<Map<String, dynamic>> get generatedReports => _generatedReports;

  void addGeneratedReport(String date, String type, String filePath) {
    _generatedReports.add({
      'date': date,
      'type': type,
      'generatedAt': DateTime.now().toIso8601String(),
      'filePath': filePath,
    });
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await repository.fetchOrders();
    } catch (e) {
      debugPrint('Repository Error in fetchOrders, using resilient in-memory fallback: $e');
      if (_orders.isEmpty) {
        _orders = [];
      }
    }
    
    // RF6: Sort by time window start, then FIFO
    _sortOrders();

    _isLoading = false;
    notifyListeners();
  }

  void _sortOrders() {
    _orders.sort((a, b) {
      // Simple parse of "HH:mm - HH:mm"
      final aStart = a.timeWindow.split(' - ').first;
      final bStart = b.timeWindow.split(' - ').first;
      
      int cmp = aStart.compareTo(bStart);
      if (cmp == 0) {
        // FIFO: Assuming lower ID means registered earlier
        return (a.id ?? 0).compareTo(b.id ?? 0);
      }
      return cmp;
    });
  }

  Future<void> addOrder(Order order, {String createdBy = 'Admin'}) async {
    try {
      await repository.addOrder(order, createdBy);
    } catch (e) {
      debugPrint('Repository Error in addOrder, performing resilient in-memory add: $e');
      final newId = _orders.isEmpty ? 1 : (_orders.map((o) => o.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      final newOrder = Order(
        id: newId,
        clientId: order.clientId,
        weight: order.weight,
        height: order.height,
        length: order.length,
        width: order.width,
        loadType: order.loadType,
        timeWindow: order.timeWindow,
        address: order.address,
        status: order.status,
        scheduledDate: order.scheduledDate,
        driverId: order.driverId,
      );
      _orders.add(newOrder);
      _sortOrders();
      notifyListeners();
      return;
    }

    await fetchOrders();
  }

  Future<void> updateOrderStatus(int id, String newStatus, String updatedBy, {String? incidentReason, String? evidencePath, String? signaturePath}) async {
    String oldStatus = 'Pendiente';
    try {
      final oldOrder = _orders.firstWhere((o) => o.id == id);
      oldStatus = oldOrder.status;
    } catch (_) {}

    try {
      await repository.updateOrderStatus(
        id, 
        newStatus, 
        updatedBy, 
        oldStatus: oldStatus,
        incidentReason: incidentReason,
        evidencePath: evidencePath,
        signaturePath: signaturePath,
      );
    } catch (e) {
      debugPrint('Repository Error in updateOrderStatus, performing resilient in-memory update: $e');
      final idx = _orders.indexWhere((o) => o.id == id);
      if (idx != -1) {
        final o = _orders[idx];
        _orders[idx] = Order(
          id: o.id,
          clientId: o.clientId,
          weight: o.weight,
          height: o.height,
          length: o.length,
          width: o.width,
          loadType: o.loadType,
          timeWindow: o.timeWindow,
          address: o.address,
          status: newStatus,
          scheduledDate: o.scheduledDate,
          driverId: o.driverId,
          incidentReason: incidentReason ?? o.incidentReason,
          evidencePath: evidencePath ?? o.evidencePath,
          signaturePath: signaturePath ?? o.signaturePath,
          deliveryTime: DateTime.now(),
        );
        _sortOrders();
        notifyListeners();
      }
      return;
    }

    await fetchOrders();
  }

  Future<List<Map<String, dynamic>>> getAuditLogsForOrder(int orderId) async {
    return await repository.getAuditLogsForOrder(orderId);
  }

  Future<List<Map<String, dynamic>>> getGlobalAuditLogs() async {
    return await repository.getGlobalAuditLogs();
  }

  Future<void> updateOrder(Order order) async {
    if (order.id == null) return;
    await repository.updateOrder(order);
    await fetchOrders();
  }

  Future<void> deleteOrder(int id) async {
    await repository.deleteOrder(id);
    await fetchOrders();
  }

  // RF13: Punctuality Indicator
  String getPunctualityStatus(Order order) {
    if (order.deliveryTime == null) return "Pendiente";
    
    // Extract end of window "HH:mm"
    final endWindowStr = order.timeWindow.split(' - ').last;
    final parts = endWindowStr.split(':');
    final endWindow = DateTime(
      order.scheduledDate.year,
      order.scheduledDate.month,
      order.scheduledDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    if (order.deliveryTime!.isAfter(endWindow)) {
      final diff = order.deliveryTime!.difference(endWindow).inMinutes;
      return "Atrasado ($diff min)";
    }
    return "A tiempo";
  }
}
