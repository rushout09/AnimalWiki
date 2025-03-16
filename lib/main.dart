import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

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
    // Provide a fallback with the API key directly in code
    dotenv.env['GEMINI_API_KEY'] = 'AIzaSyA4SoDN2lAF4zjOUYmkr0QPfDrtrEe22ek';
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Identifier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      home: HomeScreen(),
    );
  }
}