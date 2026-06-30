import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/api_client.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/splash_screen.dart';
import 'features/dashboard/dashboard_provider.dart';
import 'features/bills/bill_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize French date formatting for transaction history
  await initializeDateFormatting('fr_FR', null);

  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(apiClient),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (context) => DashboardProvider(apiClient),
        ),
        ChangeNotifierProvider<BillProvider>(
          create: (context) => BillProvider(apiClient),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BadWallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
