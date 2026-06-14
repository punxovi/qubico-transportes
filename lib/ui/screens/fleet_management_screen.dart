import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../theme/app_theme.dart';

class FleetManagementScreen extends StatelessWidget {
  const FleetManagementScreen({super.key});

  void _showVehicleDialog(BuildContext context, {Vehicle? vehicle}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: vehicle?.name ?? '');
    final patenteController = TextEditingController(text: vehicle?.patente ?? '');
    final weightController = TextEditingController(text: vehicle?.maxWeight.toString() ?? '');
    
    final users = context.read<UserProvider>().users;
    final drivers = users.where((u) => u.isActive && u.role == UserRole.conductor).toList();
    
    String? selectedDriverName = vehicle?.driverName;
    String? selectedDriverId = vehicle?.driverId;
    if (selectedDriverName != null && selectedDriverName.isEmpty) {
      selectedDriverName = null;
      selectedDriverId = null;
    }

    // If the previously assigned driver no longer exists or is inactive, add them
    // temporarily so the dropdown can show the current value without crashing.
    bool driverExists = drivers.any((d) => d.fullName == selectedDriverName);
    if (selectedDriverName != null && !driverExists) {
      drivers.add(User(id: selectedDriverId ?? 'temp', fullName: selectedDriverName, email: '', password: '', role: UserRole.conductor));
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vehicle == null ? 'Registrar Vehículo' : 'Editar Vehículo'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre (Ej: Furgón A)'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: patenteController,
                  decoration: const InputDecoration(labelText: 'Patente'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: 'Capacidad Máxima (kg)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedDriverName,
                  decoration: const InputDecoration(labelText: 'Conductor Asignado'),
                  items: drivers.map((driver) {
                    return DropdownMenuItem<String>(
                      value: driver.fullName,
                      child: Text(driver.fullName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedDriverName = value;
                    try {
                      selectedDriverId = drivers.firstWhere((d) => d.fullName == value).id;
                      if (selectedDriverId == 'temp') selectedDriverId = null;
                    } catch (_) {
                      selectedDriverId = null;
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newVehicle = Vehicle(
                  id: vehicle?.id,
                  name: nameController.text,
                  patente: patenteController.text.toUpperCase(),
                  maxWeight: double.tryParse(weightController.text) ?? 0.0,
                  driverName: selectedDriverName ?? '',
                  driverId: selectedDriverId,
                );

                if (vehicle == null) {
                  context.read<VehicleProvider>().addVehicle(newVehicle);
                } else {
                  context.read<VehicleProvider>().updateVehicle(newVehicle);
                }

                Navigator.pop(context);
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Flota'),
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.vehicles.isEmpty) {
            return const Center(child: Text('No hay vehículos registrados.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = provider.vehicles[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.local_shipping, color: AppTheme.primaryBlue, size: 32),
                  title: Text('${vehicle.name} (${vehicle.patente})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Max: ${vehicle.maxWeight} kg\nConductor: ${vehicle.driverName}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () => _showVehicleDialog(context, vehicle: vehicle),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVehicleDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
