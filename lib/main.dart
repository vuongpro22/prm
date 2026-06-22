import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:prm_project/firebase_options.dart';
import 'package:prm_project/viewmodels/auth_viewmodel.dart';
import 'package:prm_project/viewmodels/product_viewmodel.dart';
import 'package:prm_project/viewmodels/cart_viewmodel.dart';
import 'package:prm_project/viewmodels/notification_viewmodel.dart';
import 'package:prm_project/viewmodels/chat_viewmodel.dart';
import 'package:prm_project/viewmodels/map_viewmodel.dart';
import 'package:prm_project/views/auth/login_screen.dart';
import 'package:prm_project/views/dashboard/dashboard_screen.dart';
import 'package:prm_project/views/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProductViewModel()),
        ChangeNotifierProvider(create: (_) => MapViewModel()),
        
        // ProxyProviders to inject auth credentials and catalog list automatically
        ChangeNotifierProxyProvider2<AuthViewModel, ProductViewModel, CartViewModel>(
          create: (_) => CartViewModel(),
          update: (_, auth, product, cart) {
            cart!.setUserId(auth.currentUser?.id, product.allProducts);
            return cart;
          },
        ),
        ChangeNotifierProxyProvider<AuthViewModel, NotificationViewModel>(
          create: (_) => NotificationViewModel(),
          update: (_, auth, notif) {
            notif!.setUserId(auth.currentUser?.id);
            return notif;
          },
        ),
        ChangeNotifierProxyProvider<AuthViewModel, ChatViewModel>(
          create: (_) => ChatViewModel(),
          update: (_, auth, chat) {
            chat!.setUserId(auth.currentUser?.id);
            return chat;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Luxura Store',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthenticationWrapper(),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context);

    if (authVm.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryNeon,
          ),
        ),
      );
    }

    if (authVm.isLoggedIn) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
