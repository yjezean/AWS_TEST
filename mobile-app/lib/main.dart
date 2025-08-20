import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:provider/provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Configure Amplify
    await _configureAmplify();
    
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error configuring Amplify: $e');
  }
}

Future<void> _configureAmplify() async {
  // Add Amplify plugins
  await Amplify.addPlugin(AmplifyAuthCognito());
  await Amplify.addPlugin(AmplifyStorageS3());
  await Amplify.addPlugin(AmplifyAPI());
  
  // Configure Amplify
  // Note: Replace with your actual amplifyconfiguration.dart file
  // await Amplify.configure(amplifyconfig);
  
  // For now, we'll use a placeholder configuration
  // You'll need to generate this using: amplify init
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'AWS Mobile App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}
