import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';
import 'services/payment_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Load environment variables with fallback for missing .env file
  try {
    await dotenv.load(fileName: '.env');
    print('Environment variables loaded successfully');
  } catch (e) {
    print('Failed to load environment variables: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Create and provide the PaymentService
        ChangeNotifierProvider(
          create: (_) => PaymentService(),
          lazy: false, // Initialize immediately
        ),
        // Add other providers here as needed
      ],
      child: Consumer<PaymentService>(
        // Use Consumer to access PaymentService in the MaterialApp
        builder: (context, paymentService, child) {
          print('PaymentService initialized: ${paymentService.isAvailable}');
          return MaterialApp(
            title: 'Animal Identifier',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(),
            home: HomeScreen(),
          );
        },
      ),
    );
  }
}