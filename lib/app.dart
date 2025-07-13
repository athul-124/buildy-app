import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart'; // Make sure this points to the correct file
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/data_service.dart';
import 'services/cache_service.dart';
import 'services/booking_service.dart';
import 'services/payment_service.dart';

class BuildlyApp extends StatelessWidget {
  const BuildlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirebaseService()),
        Provider(create: (_) => DataService()),
        Provider(create: (_) => CacheService()),
        ChangeNotifierProvider(create: (_) => BookingService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          // Cache theme to prevent rebuilds
          final lightTheme = AppTheme.lightTheme;
          final darkTheme = AppTheme.darkTheme;
          
          return MaterialApp(
            title: 'Buildly',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            home: _getInitialScreen(authService),
            routes: {
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }

  Widget _getInitialScreen(AuthService authService) {
    if (authService.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (authService.currentUser != null) {
      return const HomeScreen();
    }
    
    return const WelcomeScreen();
  }
}
