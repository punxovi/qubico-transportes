import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/user_model.dart';
import '../../utils/validators.dart';
import '../../services/security_service.dart';
import '../theme/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _auditLogFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _auditLogFuture = context.read<OrderProvider>().getGlobalAuditLogs();
  }

  void _refreshAuditLog() {
    setState(() {
      _auditLogFuture = context.read<OrderProvider>().getGlobalAuditLogs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Seguridad y Perfiles'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gestión de Cuentas'),
            Tab(text: 'Bitácora de Auditoría'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccountsTab(),
          _buildAuditTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(),
        backgroundColor: AppTheme.accentOrange,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAccountsTab() {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        if (provider.users.isEmpty) {
          return const Center(child: Text('No hay usuarios registrados'));
        }

        final currentUserId = provider.currentUser?.id;

        return ListView.builder(
          itemCount: provider.users.length,
          itemBuilder: (context, index) {
            final user = provider.users[index];
            final isSelf = user.id == currentUserId;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.isActive ? AppTheme.primaryBlue : Colors.grey,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(user.fullName, style: TextStyle(
                  decoration: user.isActive ? TextDecoration.none : TextDecoration.lineThrough,
                  color: user.isActive ? Colors.black : Colors.grey,
                )),
                subtitle: Text('${user.email}\nRol: ${user.role.name.toUpperCase()}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: user.isActive,
                      onChanged: isSelf
                          ? null // Prevent deactivating self
                          : (value) {
                              provider.toggleUserStatus(user.id, user.isActive);
                            },
                    ),
                    if (!isSelf)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar Usuario'),
                              content: Text('¿Está seguro de que desea eliminar permanentemente al usuario "${user.fullName}"? Esta acción no se puede deshacer.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('CANCELAR'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                                  child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await provider.deleteUser(user.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Usuario eliminado exitosamente')),
                            );
                            _refreshAuditLog();
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAuditTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _auditLogFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No hay eventos en la bitácora.', style: TextStyle(color: Colors.grey)),
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final ts = DateTime.parse(log['timestamp'].toString()).toLocal();
            final timeStr =
                '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year} '
                '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: const Icon(Icons.history, color: AppTheme.primaryBlue),
                title: Text(
                  log['action'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  '${log['user_id']} · $timeStr\n'
                  '${log['old_value']} → ${log['new_value']}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.conductor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Usuario'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'RUT'),
                  validator: Validators.validateRut,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre Completo'),
                  validator: (v) => Validators.validateRequired(v, 'El nombre'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (v.length < 8) return 'Mínimo 8 caracteres';
                    if (!v.contains(RegExp(r'[A-Z]'))) return 'Debe contener una mayúscula';
                    if (!v.contains(RegExp(r'[0-9]'))) return 'Debe contener un número';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserRole>(
                  initialValue: selectedRole,
                  items: UserRole.values
                      .where((role) => role == UserRole.admin || role == UserRole.conductor)
                      .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role == UserRole.admin ? 'ADMINISTRADOR' : 'CONDUCTOR'),
                      )).toList(),
                  onChanged: (v) => selectedRole = v!,
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newUser = User(
                  id: idController.text,
                  fullName: nameController.text,
                  email: emailController.text,
                  password: SecurityService.generateHash(passwordController.text),
                  role: selectedRole,
                );
                final messenger = ScaffoldMessenger.of(context);
                context.read<UserProvider>().addUser(newUser);
                Navigator.pop(context);
                _refreshAuditLog();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Usuario creado exitosamente')),
                );
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }
}
