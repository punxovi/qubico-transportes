import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/order_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../models/order_model.dart';
import '../../models/client_model.dart';
import '../../models/vehicle_model.dart';
import '../theme/app_theme.dart';
import 'order_detail_screen.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import '../../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (!mounted) return;
      final orderProvider = context.read<OrderProvider>();
      final currentUserId = context.read<UserProvider>().currentUser?.id;
      final prevCount = _getTodaysOrders(orderProvider.orders, currentUserId).length;

      await orderProvider.fetchOrders();

      if (!mounted) return;
      final newCount = _getTodaysOrders(orderProvider.orders, currentUserId).length;
      if (newCount > prevCount) {
        final diff = newCount - prevCount;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$diff nuevo${diff > 1 ? 's' : ''} pedido${diff > 1 ? 's' : ''} asignado${diff > 1 ? 's' : ''}'),
          backgroundColor: AppTheme.primaryBlue,
          duration: const Duration(seconds: 4),
        ));
      }
    });
  }

  List<Order> _getTodaysOrders(List<Order> orders, String? currentUserId) {
    final today = DateTime.now();
    return orders.where((o) =>
      o.scheduledDate.year == today.year &&
      o.scheduledDate.month == today.month &&
      o.scheduledDate.day == today.day &&
      o.driverId == currentUserId &&
      o.status != 'Anulado'
    ).toList();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Icon(Icons.local_shipping, color: AppTheme.accentOrange, size: 28),
        ),
        title: const Text(
          'Qúbico Conductor',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              context.read<UserProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConductorHeader(context),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildRutaTab(context),
                _buildCargasTab(context),
                _buildPerfilTab(context),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.accentOrange,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Ruta'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Cargas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildConductorHeader(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final driverName = userProvider.currentUser?.fullName ?? 'Conductor';
    final initials = driverName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();
    final firstName = driverName.split(' ').first;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.1),
            child: Text(
              initials,
              style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Buen viaje, $firstName!',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 4),
              const Text(
                'Conductor de Ruta',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TABS ====================

  Widget _buildRutaTab(BuildContext context) {
    return Column(
      children: [
        _buildHeader(
          context,
          title: 'Hoja de Ruta',
          subtitleBuilder: (orders) => '${orders.length} paradas programadas',
        ),
        Expanded(
          child: _buildRouteTimeline(context),
        ),
      ],
    );
  }

  Widget _buildCargasTab(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUserId = userProvider.currentUser?.id;
    final driverName = userProvider.currentUser?.fullName ?? 'Conductor';
    final todaysOrders = _getTodaysOrders(provider.orders, currentUserId);
    final vehicleProvider = context.watch<VehicleProvider>();
    Vehicle assignedVehicle;
    try {
      assignedVehicle = vehicleProvider.vehicles.firstWhere((v) => v.driverId == currentUserId);
    } catch (_) {
      // Fallback: match by name for vehicles without driverId yet
      try {
        assignedVehicle = vehicleProvider.vehicles.firstWhere((v) => v.driverName == driverName);
      } catch (_) {
        assignedVehicle = Vehicle(name: '—', patente: '—', maxWeight: 1000.0, driverName: driverName);
      }
    }

    final activeOrders = todaysOrders.where((o) => o.status != 'Entregado').toList();
    final totalWeight = activeOrders.fold<double>(0.0, (sum, order) => sum + order.weight);
    final capacityPercentage = (totalWeight / assignedVehicle.maxWeight).clamp(0.0, 1.0);

    return Column(
      children: [
        _buildHeader(
          context,
          title: 'Mis Cargas',
          subtitleBuilder: (orders) => 'Carga actual: ${totalWeight.toStringAsFixed(1)} / ${assignedVehicle.maxWeight.toStringAsFixed(1)} kg',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Vehicle Info & Capacity Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignedVehicle.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  assignedVehicle.patente,
                                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.local_shipping_outlined, color: AppTheme.primaryBlue, size: 36),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Capacidad Utilizada', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                          Text(
                            '${(capacityPercentage * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: capacityPercentage > 0.9 ? AppTheme.errorColor : AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: capacityPercentage,
                          minHeight: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            capacityPercentage > 0.9
                                ? AppTheme.errorColor
                                : capacityPercentage > 0.7
                                    ? AppTheme.accentOrange
                                    : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Carga total actual: ${totalWeight.toStringAsFixed(1)} kg. Límite máximo: ${assignedVehicle.maxWeight.toStringAsFixed(1)} kg.',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'DETALLE DE CARGAS DEL DÍA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2, color: Colors.grey),
                ),
              ),
              if (todaysOrders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No hay cargas registradas para hoy.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...todaysOrders.map((order) => _buildCargoItemCard(order)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerfilTab(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;
    final driverName = currentUser?.fullName ?? 'Conductor';
    final driverEmail = currentUser?.email ?? '';
    final driverId = currentUser?.id ?? '';
    final initials = driverName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();

    final todaysOrders = _getTodaysOrders(provider.orders, currentUser?.id);

    final deliveredCount = todaysOrders.where((o) => o.status == 'Entregado').length;
    final inRouteCount = todaysOrders.where((o) => o.status == 'En camino').length;
    final incidentsCount = todaysOrders.where((o) => o.status == 'Incidencia').length;

    return Column(
      children: [
        _buildHeader(
          context,
          title: 'Mi Perfil',
          subtitleBuilder: (_) => 'Conductor de Ruta',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Identity Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        child: Text(
                          initials,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryBlue),
                            ),
                            const SizedBox(height: 4),
                            Text('ID: $driverId', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(driverEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Statistics Grid Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'RESUMEN OPERATIVO DE HOY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2, color: Colors.grey),
                ),
              ),

              // 2x2 Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatItem('Asignadas', '${todaysOrders.length}', Icons.assignment_outlined, Colors.blue),
                  _buildStatItem('Entregadas', '$deliveredCount', Icons.check_circle_outline, Colors.green),
                  _buildStatItem('En Tránsito', '$inRouteCount', Icons.local_shipping_outlined, AppTheme.accentOrange),
                  _buildStatItem('Incidencias', '$incidentsCount', Icons.warning_amber_rounded, AppTheme.errorColor),
                ],
              ),

              const SizedBox(height: 32),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<UserProvider>().logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== SUB-WIDGETS & BUILDERS ====================

  Widget _buildHeader(BuildContext context, {required String title, required String Function(List<Order>) subtitleBuilder}) {
    final provider = context.watch<OrderProvider>();
    final currentUserId = context.watch<UserProvider>().currentUser?.id;
    final todaysOrders = _getTodaysOrders(provider.orders, currentUserId);
    
    final now = DateTime.now();
    final List<String> months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final dateStr = '${now.day} ${months[now.month - 1]}';

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  context.read<UserProvider>().logout();
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                },
                child: const Text('Cerrar App', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Hoy, $dateStr', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitleBuilder(todaysOrders), style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRouteTimeline(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final clientProvider = context.read<ClientProvider>();
    final currentUserId = context.watch<UserProvider>().currentUser?.id;
    final todaysOrders = _getTodaysOrders(provider.orders, currentUserId);

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (todaysOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<OrderProvider>().fetchOrders(),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No hay paradas hoy.', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    // Find the next active order (first one that is 'Pendiente' or 'En camino')
    int nextOrderIndex = todaysOrders.indexWhere((o) => o.status == 'Pendiente' || o.status == 'En camino');

    return RefreshIndicator(
      onRefresh: () => context.read<OrderProvider>().fetchOrders(),
      child: ListView.builder(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 24),
      itemCount: todaysOrders.length,
      itemBuilder: (context, index) {
        final order = todaysOrders[index];
        Client client;
        try {
          client = clientProvider.clients.firstWhere((c) => c.rut == order.clientId);
        } catch (e) {
          client = Client(rut: order.clientId, name: 'Cliente Desconocido', phone: '', email: '', billingAddress: '');
        }
        
        final isNext = index == nextOrderIndex;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline line and dot
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isNext ? AppTheme.accentOrange : Colors.grey[300]!, width: 4),
                      color: Colors.white,
                    ),
                  ),
                  if (index < todaysOrders.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey[300],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildOrderCard(order, client, isNext),
                ),
              ),
            ],
          ),
        );
      },
    ),
    );
  }

  Widget _buildOrderCard(Order order, Client client, bool isNext) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: isNext ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNext ? const BorderSide(color: AppTheme.accentOrange, width: 2) : BorderSide(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNext)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: const BoxDecoration(
                color: AppTheme.accentOrange,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('PRÓXIMO DESPACHO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  Icon(Icons.navigation, color: Colors.white, size: 16),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue)),
                    ),
                    _buildStatusBadge(order.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.primaryBlue),
                    const SizedBox(width: 4),
                    Expanded(child: Text(order.address, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppTheme.primaryBlue),
                      const SizedBox(width: 4),
                      Text(order.timeWindow, style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makePhoneCall(client.phone),
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Llamar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          backgroundColor: Colors.blue[50],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (order.status == 'Entregado' || order.status == 'Incidencia') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
                          } else if (order.status == 'Pendiente') {
                            final updatedBy = context.read<UserProvider>().currentUser?.fullName ?? 'Conductor';
                            context.read<OrderProvider>().updateOrderStatus(order.id!, 'En camino', updatedBy);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(selectedOrder: order)));
                          } else if (order.status == 'En camino') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isNext ? AppTheme.accentOrange : AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          (order.status == 'Entregado' || order.status == 'Incidencia')
                            ? 'Ver Resumen'
                            : (order.status == 'Pendiente')
                                ? 'Iniciar Entrega'
                                : 'Terminar Entrega',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoItemCard(Order order) {
    Color badgeColor = AppTheme.primaryBlue;
    if (order.loadType == 'Construcción') badgeColor = AppTheme.accentOrange;
    if (order.loadType == 'Eventos') badgeColor = Colors.purple;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Carga #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.loadType,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.fitness_center_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Peso: ', style: const TextStyle(color: Colors.grey)),
                Text('${order.weight} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.straighten_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Dim: ', style: const TextStyle(color: Colors.grey)),
                Text(
                  '${order.length} x ${order.width} x ${order.height} m',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.address,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status) {
      case 'Entregado':
        badgeColor = Colors.green;
        break;
      case 'Incidencia':
        badgeColor = AppTheme.errorColor;
        break;
      case 'En camino':
        badgeColor = AppTheme.accentOrange;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
