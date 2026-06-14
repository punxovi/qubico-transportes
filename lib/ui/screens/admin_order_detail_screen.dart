import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/client_model.dart';
import '../../models/vehicle_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../theme/app_theme.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final Order order;

  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoadingLogs = true;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    if (widget.order.id == null) return;
    final orderProvider = context.read<OrderProvider>();
    final logs = await orderProvider.getAuditLogsForOrder(widget.order.id!);
    setState(() {
      _auditLogs = logs;
      _isLoadingLogs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.read<ClientProvider>();
    final vehicleProvider = context.read<VehicleProvider>();

    // 1. Fetch Client info
    Client client;
    try {
      client = clientProvider.clients.firstWhere(
        (c) => c.rut == widget.order.clientId,
      );
    } catch (_) {
      client = Client(
        rut: widget.order.clientId,
        name: 'Cliente Desconocido',
        phone: 'No disponible',
        email: 'No disponible',
        billingAddress: widget.order.address,
      );
    }

    // 2. Fetch Vehicle & Driver info
    Vehicle? vehicle;
    try {
      vehicle = vehicleProvider.vehicles.firstWhere(
        (v) => v.driverId == widget.order.driverId,
      );
    } catch (_) {
      // fallback
    }

    // 3. Status branding
    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    String statusLabel = widget.order.status;

    switch (widget.order.status) {
      case 'Entregado':
        statusColor = const Color(0xFF137333);
        statusBg = const Color(0xFFE6F4EA);
        statusIcon = Icons.check_circle;
        break;
      case 'Incidencia':
        statusColor = AppTheme.errorColor;
        statusBg = const Color(0xFFFCE8E6);
        statusIcon = Icons.warning;
        break;
      case 'En camino':
        statusColor = const Color(0xFFE65100);
        statusBg = const Color(0xFFFFF4E5);
        statusIcon = Icons.local_shipping;
        break;
      default:
        statusColor = AppTheme.primaryBlue;
        statusBg = const Color(0xFFE8F0FE);
        statusIcon = Icons.access_time;
        statusLabel = 'Pendiente';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedido #${widget.order.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const Text(
              'Detalles de Monitoreo en Tiempo Real',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTADO: ${statusLabel.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (widget.order.deliveryTime != null)
                          Text(
                            'Actualizado: ${widget.order.deliveryTime!.toLocal().toString().substring(0, 19)}',
                            style: TextStyle(
                              color: statusColor.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          )
                        else
                          Text(
                            'Programado para: ${widget.order.timeWindow}',
                            style: TextStyle(
                              color: statusColor.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Decrypted ID Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'P-${widget.order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: Client details (Decrypted)
            _buildSectionHeader(
              'INFORMACIÓN DEL CLIENTE',
              Icons.person_outline,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
                          child: Text(
                            client.name.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'RUT: ${client.rut}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      Icons.phone_outlined,
                      'Teléfono de Contacto',
                      client.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.mail_outline,
                      'Correo Electrónico',
                      client.email,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      'Dirección de Despacho',
                      widget.order.address,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: Logistics / Route Assignment
            _buildSectionHeader(
              'ASIGNACIÓN LOGÍSTICA',
              Icons.local_shipping_outlined,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      Icons.person_pin_circle_outlined,
                      'Conductor Asignado',
                      widget.order.driverId ?? 'No asignado',
                      subtitle: 'Responsable de la Hoja de Ruta',
                    ),
                    if (vehicle != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        Icons.airport_shuttle_outlined,
                        'Vehículo Transportador',
                        vehicle.name,
                        subtitle:
                            'Patente: ${vehicle.patente} (Máx: ${vehicle.maxWeight} kg)',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card 3: Package details & Load Specs
            _buildSectionHeader(
              'ESPECIFICACIONES DE LA CARGA',
              Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tipo de Carga',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.order.loadType,
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLogSpecsColumn(
                            Icons.fitness_center_outlined,
                            'Peso Total',
                            '${widget.order.weight} kg',
                          ),
                        ),
                        Expanded(
                          child: _buildLogSpecsColumn(
                            Icons.straighten_outlined,
                            'Volumen / Dim',
                            '${widget.order.length}x${widget.order.width}x${widget.order.height} m',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card 4: Proof of Delivery (if completed / incident)
            if (widget.order.status == 'Entregado' ||
                widget.order.status == 'Incidencia') ...[
              _buildSectionHeader(
                'EVIDENCIA DE ENTREGA EN TIEMPO REAL',
                Icons.fact_check_outlined,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.order.status == 'Incidencia' &&
                          widget.order.incidentReason != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.errorColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.errorColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'MOTIVO DE INCIDENCIA REPORTADO',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.errorColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.order.incidentReason!,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      const Text(
                        'Evidencia Fotográfica',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.order.evidencePath != null &&
                          widget.order.evidencePath!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              widget.order.evidencePath!.startsWith('/') ||
                                  widget.order.evidencePath!.contains(':')
                              ? Image.file(
                                  File(widget.order.evidencePath!),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 120,
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image_outlined,
                                                color: Colors.grey,
                                                size: 36,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Evidencia no disponible localmente',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                )
                              : Container(
                                  height: 120,
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: Text('Simulated Evidence Path'),
                                  ),
                                ),
                        )
                      else
                        Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Sin evidencia de imagen registrada',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Firma de Recepción',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Firma Digital Capturada y Validada',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Card 5: Real-time Audit Timeline (Bitácora de Eventos)
            _buildSectionHeader(
              'BITÁCORA DE EVENTOS (TIEMPO REAL)',
              Icons.history,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _isLoadingLogs
                    ? const Center(child: CircularProgressIndicator())
                    : _auditLogs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No hay registros de auditoría para este pedido.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _auditLogs
                            .map((log) => _buildTimelineItem(log))
                            .toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGET BUILDERS ====================

  Widget _buildSectionHeader(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogSpecsColumn(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> log) {
    final timestamp = DateTime.parse(log['timestamp'].toString()).toLocal();
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final dateStr = '${timestamp.day}/${timestamp.month}/${timestamp.year}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator & Line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.accentOrange,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(child: Container(width: 2, color: Colors.grey[200])),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          log['action'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$dateStr $timeStr',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      children: [
                        const TextSpan(text: 'Realizado por: '),
                        TextSpan(
                          text: log['user_id'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      children: [
                        const TextSpan(text: 'Cambio: '),
                        TextSpan(
                          text: log['old_value'].toString(),
                          style: const TextStyle(
                            color: Colors.red,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const TextSpan(text: ' → '),
                        TextSpan(
                          text: log['new_value'].toString(),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
