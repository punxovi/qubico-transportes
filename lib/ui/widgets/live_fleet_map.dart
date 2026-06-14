import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../models/order_model.dart';
import '../theme/app_theme.dart';

class LiveFleetMap extends StatefulWidget {
  final List<Order> orders;

  const LiveFleetMap({super.key, required this.orders});

  @override
  State<LiveFleetMap> createState() => _LiveFleetMapState();
}

class _LiveFleetMapState extends State<LiveFleetMap> {
  static const _santiago = ll.LatLng(-33.4489, -70.6693);
  final _positions = <int, ll.LatLng>{};
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _geocodeAll(widget.orders);
  }

  @override
  void didUpdateWidget(LiveFleetMap old) {
    super.didUpdateWidget(old);
    final fresh = widget.orders
        .where((o) => o.id != null && !_positions.containsKey(o.id))
        .toList();
    if (fresh.isNotEmpty) _geocodeAll(fresh);
  }

  Future<void> _geocodeAll(List<Order> orders) async {
    if (orders.isEmpty || !mounted) return;
    setState(() => _isGeocoding = true);
    for (final order in orders) {
      if (order.id == null || !mounted) break;
      try {
        final locs = await locationFromAddress('${order.address}, Santiago, Chile');
        if (locs.isNotEmpty && mounted) {
          setState(() {
            _positions[order.id!] =
                ll.LatLng(locs.first.latitude, locs.first.longitude);
          });
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _isGeocoding = false);
  }

  List<Marker> _buildMarkers() {
    return widget.orders
        .where((o) => o.id != null && _positions.containsKey(o.id!))
        .map((o) {
      final pos = _positions[o.id!]!;
      final Color color;
      final IconData icon;
      switch (o.status) {
        case 'En camino':
          color = AppTheme.accentOrange;
          icon = Icons.local_shipping;
          break;
        case 'Entregado':
          color = const Color(0xFF137333);
          icon = Icons.check_circle;
          break;
        case 'Incidencia':
          color = AppTheme.errorColor;
          icon = Icons.warning;
          break;
        default:
          color = AppTheme.primaryBlue;
          icon = Icons.location_on;
      }
      return Marker(
        point: pos,
        width: 40,
        height: 40,
        child: Icon(icon, color: color, size: 32),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();
    final center = markers.isNotEmpty ? markers.first.point : _santiago;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.qubico',
              maxZoom: 18.0,
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        if (_isGeocoding)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 6),
                  Text('Localizando...', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
        if (markers.isEmpty && !_isGeocoding)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Sin entregas activas en el mapa',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ),
          ),
        // Leyenda
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendItem(color: AppTheme.accentOrange, icon: Icons.local_shipping, label: 'En camino'),
                SizedBox(height: 2),
                _LegendItem(color: Color(0xFF137333), icon: Icons.check_circle, label: 'Entregado'),
                SizedBox(height: 2),
                _LegendItem(color: AppTheme.primaryBlue, icon: Icons.location_on, label: 'Pendiente'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87)),
      ],
    );
  }
}
