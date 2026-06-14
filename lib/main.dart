import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/order_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/user_provider.dart';
import 'providers/client_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/login_screen.dart';
import 'services/sync_service.dart';
import 'repositories/order_repository_sqlite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SyncService.instance.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderProvider(repository: SqliteOrderRepository())..fetchOrders()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()..fetchVehicles()),
        ChangeNotifierProvider(create: (_) => UserProvider()..fetchUsers()),
        ChangeNotifierProvider(create: (_) => ClientProvider()..fetchClients()),
      ],
      child: MaterialApp(
        title: 'Qúbico Transportes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
