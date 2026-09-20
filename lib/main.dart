import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  // Garante a inicialização das rotinas nativas antes do Firebase
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NexusApp());
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Usa FutureBuilder para inicializar o Firebase com tratamento de tela preta/branca
      home: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          // Exibe tela de carregamento estilizada enquanto o Firebase conecta
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryPurple),
              ),
            );
          }

          // Se houver erro na inicialização, exibe o erro na tela ao invés da tela em branco
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Erro ao inicializar Firebase:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  ),
                ),
              ),
            );
          }

          // Firebase inicializado com sucesso -> Direciona conforme autenticação
          return const AuthWrapper();
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().userChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPurple),
            ),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// Tela temporária pós-login para testar o logout
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexus - Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.greenAccent),
            const SizedBox(height: 16),
            Text(
              'Logado como:\n${user?.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}