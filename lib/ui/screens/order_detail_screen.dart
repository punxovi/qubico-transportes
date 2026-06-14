import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/order_model.dart';
import '../../models/client_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/user_provider.dart';
import '../theme/app_theme.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  final bool isAdmin;

  const OrderDetailScreen({super.key, required this.order, this.isAdmin = false});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String? _selectedIncidentReason;
  final List<String> _incidentReasons = [
    'Cliente ausente',
    'Dirección incorrecta',
    'Rechazado por cliente',
    'Problema con vehículo',
  ];

  late SignatureController _signatureController;
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: AppTheme.primaryBlue,
      exportBackgroundColor: Colors.white,
    );
    _signatureController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (photo != null) {
      setState(() {
        _capturedImage = File(photo.path);
      });
    }
  }

  Future<void> _updateStatus(String status, {String? signaturePath, String? evidencePath, String? incidentReason}) async {
    final updatedBy = context.read<UserProvider>().currentUser?.fullName ?? 'Conductor';
    await context.read<OrderProvider>().updateOrderStatus(
      widget.order.id!,
      status,
      updatedBy,
      signaturePath: signaturePath,
      evidencePath: evidencePath,
      incidentReason: incidentReason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pedido actualizado: $status')),
    );
    Navigator.pop(context);
  }

  void _showIncidentDialog() {
    _capturedImage = null;
    _selectedIncidentReason = null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reportar Incidencia'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  hint: const Text('Seleccionar motivo'),
                  initialValue: _selectedIncidentReason,
                  items: _incidentReasons.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                  onChanged: (val) => setDialogState(() => _selectedIncidentReason = val),
                  decoration: const InputDecoration(labelText: 'Motivo'),
                ),
                const SizedBox(height: 24),
                if (_capturedImage == null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                      if (photo != null) {
                        setDialogState(() => _capturedImage = File(photo.path));
                        setState(() => _capturedImage = File(photo.path)); // update main state too
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('CAPTURAR FOTO (OBLIGATORIO)'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, minimumSize: const Size(double.infinity, 50)),
                  )
                else
                  Column(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_capturedImage!, height: 150, width: double.infinity, fit: BoxFit.cover)),
                      TextButton.icon(
                        onPressed: () async {
                          final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                          if (photo != null) setDialogState(() => _capturedImage = File(photo.path));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('REPETIR FOTO'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: (_selectedIncidentReason == null || _capturedImage == null)
                  ? null
                  : () {
                      final path = _capturedImage!.path;
                      final reason = _selectedIncidentReason;
                      Navigator.pop(context);
                      _updateStatus('Incidencia', incidentReason: reason, evidencePath: path);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
              child: const Text('REPORTAR'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.read<ClientProvider>();
    Client client;
    try {
      client = clientProvider.clients.firstWhere((c) => c.rut == widget.order.clientId);
    } catch (e) {
      client = Client(rut: widget.order.clientId, name: 'Cliente Desconocido', phone: '', email: '', billingAddress: '');
    }

    final isReadOnly = widget.isAdmin || widget.order.status == 'Entregado' || widget.order.status == 'Incidencia';
    final bool canConfirm = _capturedImage != null && _signatureController.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cierre de Entrega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Pedido #${widget.order.id}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[300]!)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 4),
                    Text(widget.order.address, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Photo Evidence
            Row(
              children: const [
                Icon(Icons.camera_alt_outlined, color: AppTheme.primaryBlue, size: 20),
                SizedBox(width: 8),
                Text('Evidencia Fotográfica', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              ],
            ),
            const SizedBox(height: 12),
            if (isReadOnly && widget.order.evidencePath != null)
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(widget.order.evidencePath!), width: double.infinity, height: 200, fit: BoxFit.cover))
            else if (!isReadOnly)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                  ),
                  child: _capturedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_capturedImage!, width: double.infinity, height: 120, fit: BoxFit.cover))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_outlined, size: 32, color: AppTheme.primaryBlue),
                            SizedBox(height: 8),
                            Text('Capturar Foto de Entrega', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)),
                          ],
                        ),
                ),
              ),
            const SizedBox(height: 24),

            // Signature
            Row(
              children: const [
                Icon(Icons.draw_outlined, color: AppTheme.primaryBlue, size: 20),
                SizedBox(width: 8),
                Text('Firma Digital del Cliente', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              ],
            ),
            const SizedBox(height: 12),
            if (isReadOnly)
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                child: const Center(child: Text('Firma guardada', style: TextStyle(color: Colors.grey))),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 150,
                      child: Stack(
                        children: [
                          if (_signatureController.isEmpty)
                            const Center(child: Text('Firme aquí', style: TextStyle(color: Colors.grey, fontSize: 18))),
                          Signature(
                            controller: _signatureController,
                            backgroundColor: Colors.transparent,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () => _signatureController.clear(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('LÍNEA DE FIRMA', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Action Buttons
            if (!isReadOnly) ...[
              OutlinedButton.icon(
                onPressed: _showIncidentDialog,
                icon: const Icon(Icons.warning_amber_rounded, size: 20),
                label: const Text('Registrar Incidencia'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: AppTheme.primaryBlue,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: canConfirm
                    ? () {
                        _updateStatus('Entregado', signaturePath: 'simulated_path', evidencePath: _capturedImage?.path);
                      }
                    : null,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Confirmar Entrega'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primaryBlue,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ] else if (widget.order.incidentReason != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text('Motivo de Incidencia:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorColor)),
              Text(widget.order.incidentReason!, style: const TextStyle(color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }
}
