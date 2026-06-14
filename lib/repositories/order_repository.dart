import '../models/order_model.dart';

abstract class OrderRepository {
  Future<List<Order>> fetchOrders();
  Future<void> addOrder(Order order, String createdBy);
  Future<void> updateOrderStatus(int id, String newStatus, String updatedBy, {String? oldStatus, String? incidentReason, String? evidencePath, String? signaturePath});
  Future<void> updateOrder(Order order);
  Future<void> deleteOrder(int id);
  Future<List<Map<String, dynamic>>> getAuditLogsForOrder(int orderId);
  Future<List<Map<String, dynamic>>> getGlobalAuditLogs();
}
