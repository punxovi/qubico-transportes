import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../providers/order_provider.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text('Reportes de Gestión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          final filteredOrders = provider.orders.where((order) {
            final orderDate = DateTime.parse(order.scheduledDate.toIso8601String());
            return orderDate.year == _selectedDate.year &&
                orderDate.month == _selectedDate.month &&
                orderDate.day == _selectedDate.day;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monitoreo del Día',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Fecha: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Cambiar Fecha'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.accentOrange),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', filteredOrders.length, Colors.blue),
                    _buildStatCard('Entregados', filteredOrders.where((o) => o.status == 'Entregado').length, Colors.green),
                    _buildStatCard('Incidencias', filteredOrders.where((o) => o.status == 'Incidencia').length, Colors.red),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Historial de Exportaciones Generadas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Reportes solicitados y exportados desde la pestaña Historial:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: provider.generatedReports.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No hay reportes exportados aún.\nGenera reportes por fecha en Historial.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.generatedReports.length,
                          itemBuilder: (context, index) {
                            final rep = provider.generatedReports[index];
                            final isPdf = rep['type'] == 'PDF';
                            final generatedTime = DateTime.parse(rep['generatedAt']);
                            final timeStr = DateFormat('HH:mm').format(generatedTime);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  isPdf ? Icons.picture_as_pdf : Icons.table_view,
                                  color: isPdf ? Colors.red : Colors.green,
                                  size: 28,
                                ),
                                title: Text(
                                  'Reporte ${rep['type']} - ${rep['date']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  'Exportado hoy a las $timeStr hrs.\nRuta: ${rep['filePath'].split('/').last}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.open_in_new, color: AppTheme.primaryBlue),
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final file = File(rep['filePath']);
                                    if (await file.exists()) {
                                      if (isPdf) {
                                        await Printing.layoutPdf(onLayout: (format) async => file.readAsBytes());
                                      } else {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('Archivo CSV guardado en: ${rep['filePath']}'),
                                            action: SnackBarAction(label: 'OK', onPressed: () {}),
                                          ),
                                        );
                                      }
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('El archivo temporal ya no existe, por favor regenéralo.')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
