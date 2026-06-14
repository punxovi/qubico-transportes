import '../models/order_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import 'order_repository.dart';

class SqliteOrderRepository implements OrderRepository {
  @override
  Future<List<Order>> fetchOrders() async {
    final data = await DatabaseService.instance.queryAll('orders');
    return data.map((e) => Order.fromMap(e)).toList();
  }

  @override
  Future<void> addOrder(Order order, String createdBy) async {
    final id = await DatabaseService.instance.insert('orders', order.toMap());
    
    await DatabaseService.instance.insert('audit_logs', {
      'user_id': createdBy,
      'action': 'Creación Pedido #$id',
      'timestamp': DateTime.now().toIso8601String(),
      'old_value': 'Ninguno',
      'new_value': 'Creado y Asignado a ${order.driverId}',
    });

    await SyncService.instance.enqueue('orders', id.toString(), 'INSERT', order.toMap());
  }

  @override
  Future<void> updateOrderStatus(int id, String newStatus, String updatedBy, {String? oldStatus, String? incidentReason, String? evidencePath, String? signaturePath}) async {
    final Map<String, dynamic> updates = {'status': newStatus};
    if (newStatus == 'Entregado' || newStatus == 'Incidencia') {
      updates['delivery_time'] = DateTime.now().toIso8601String();
    }
    if (incidentReason != null) updates['incident_reason'] = incidentReason;
    if (evidencePath != null) updates['evidence_path'] = evidencePath;
    if (signaturePath != null) updates['signature_path'] = signaturePath;

    await DatabaseService.instance.update('orders', updates, 'id', id);

    await DatabaseService.instance.insert('audit_logs', {
      'user_id': updatedBy,
      'action': 'Actualización Estado Pedido #$id',
      'timestamp': DateTime.now().toIso8601String(),
      'old_value': oldStatus ?? 'Pendiente',
      'new_value': newStatus + (incidentReason != null ? ' ($incidentReason)' : ''),
    });

    await SyncService.instance.enqueue('orders', id.toString(), 'UPDATE', updates);
  }

  @override
  Future<void> updateOrder(Order order) async {
    if (order.id == null) return;
    await DatabaseService.instance.update('orders', order.toMap(), 'id', order.id);
  }

  @override
  Future<void> deleteOrder(int id) async {
    await DatabaseService.instance.delete('orders', 'id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> getAuditLogsForOrder(int orderId) async {
    final db = await DatabaseService.instance.database;
    return await db.query(
      'audit_logs',
      where: 'action LIKE ?',
      whereArgs: ['%#$orderId%'],
      orderBy: 'timestamp DESC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getGlobalAuditLogs() async {
    final db = await DatabaseService.instance.database;
    return await db.query('audit_logs', orderBy: 'timestamp DESC');
  }
}
