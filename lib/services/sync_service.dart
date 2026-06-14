import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  final ConnectivityService _connectivityService = ConnectivityService();

  SyncService._init() {
    _connectivityService.connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncPendingItems();
      }
    });
  }

  /// Inicializa el worker para que escuche cambios de red
  void start() {
    debugPrint('DEBUG QUBICO: SyncService worker started.');
    // Try to sync immediately if online
    _connectivityService.isConnected().then((connected) {
      if (connected) _syncPendingItems();
    });
  }

  /// Encola una operación en modo offline-first
  Future<void> enqueue(String entity, String entityId, String action, Map<String, dynamic> payload) async {
    final record = {
      'entity': entity,
      'entity_id': entityId,
      'action': action,
      'payload': jsonEncode(payload),
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending',
    };
    await DatabaseService.instance.insert('sync_queue', record);
    
    // Intenta sincronizar inmediatamente si hay internet
    final isOnline = await _connectivityService.isConnected();
    if (isOnline) {
      await _syncPendingItems();
    }
  }

  /// Sincroniza los elementos pendientes con el backend (Simulado para el MVP)
  Future<void> _syncPendingItems() async {
    final db = await DatabaseService.instance.database;
    final pendingItems = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'id ASC',
    );

    if (pendingItems.isEmpty) return;

    debugPrint('DEBUG QUBICO: Sincronizando ${pendingItems.length} elementos pendientes...');

    for (var item in pendingItems) {
      try {
        // Marca como sincronizado (aquí iría la llamada HTTP al backend real)
        await db.update(
          'sync_queue',
          {'status': 'synced'},
          where: 'id = ?',
          whereArgs: [item['id']],
        );
        debugPrint('DEBUG QUBICO: Sincronización exitosa para ID local ${item['id']}');
      } catch (e) {
        debugPrint('DEBUG QUBICO: Error al sincronizar elemento ${item['id']}: $e');
        // Si falla, se queda en estado 'pending' para el siguiente intento
      }
    }
  }
}
