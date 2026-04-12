// lib/main.dart

import 'package:flutter/material.dart' hide ImageProvider;
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/space_provider.dart';
import 'services/storage_service.dart';
import 'models/models.dart';
import 'utils/app_theme.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  runApp(const GrabPicApp());
}

class GrabPicApp extends StatelessWidget {
  const GrabPicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SpaceProvider()),
      ],
      child: MaterialApp(
        title: 'GrabPic AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _AuthWrapper(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Determines start screen based on persisted session.
// ─────────────────────────────────────────────────────────────────────────────
class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final storage = StorageService();
    final token   = storage.getJwtToken();
    final uid     = storage.getUserId();

    if (token != null && uid != null) {
      // Restore in-memory auth state
      context.read<AuthProvider>().user = AuthResponse(
        id: uid, token: token, message: 'Restored session',
      );
      // Kick off space load
      context.read<SpaceProvider>().loadSpaces();
    }

    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.heroGradient),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
            ),
          ]),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated ? const HomeScreen() : const LandingScreen();
  }
}