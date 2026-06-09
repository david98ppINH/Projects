import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'models/player_lead.dart';
import 'screens/game_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/saving_screen.dart';
import 'services/local_storage_service.dart';
import 'theme/bda_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Bloquear orientación en vertical (Portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar almacenamiento local
  final storage = LocalStorageService();
  await storage.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banco del Austro - Fan Fest Mundialista',
      debugShowCheckedModeBanner: false,
      theme: BdaTheme.lightTheme,
      home: const KioskScaleWrapper(child: KioskFlowNavigator()),
    );
  }
}

// Wrapper para escalar la app a un lienzo lógico de 540x960 (9:16)
class KioskScaleWrapper extends StatelessWidget {
  final Widget child;

  const KioskScaleWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black, // Fondo negro para márgenes (si la pantalla no es 9:16)
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 540,
              height: 960,
              child: ClipRect(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

// Controlador de Flujos del Kiosco (Evita el historial del Navigator para prevenir fallos táctiles)
class KioskFlowNavigator extends StatefulWidget {
  const KioskFlowNavigator({super.key});

  @override
  State<KioskFlowNavigator> createState() => _KioskFlowNavigatorState();
}

class _KioskFlowNavigatorState extends State<KioskFlowNavigator> {
  late String _currentScreen; // registration, menu, game, saving, leaderboard
  PlayerLead? _currentPlayer;
  String _activeGameType = 'penalty'; // penalty, keepie, trivia

  @override
  void initState() {
    super.initState();
    _currentScreen = 'registration';
  }

  void _onRegister(PlayerLead player) {
    setState(() {
      _currentPlayer = player;
      _currentScreen = 'menu';
    });
  }

  void _onSelectGame(String gameType) {
    setState(() {
      _activeGameType = gameType;
      _currentScreen = 'game';
    });
  }

  void _onGameFinished(int score, {int? timeElapsed}) async {
    setState(() {
      _currentScreen = 'saving';
    });

    if (_currentPlayer != null) {
      // Actualizar en Firebase
      try {
        final gameData = <String, dynamic>{'score': score};
        if (timeElapsed != null) {
          gameData['timeElapsed'] = timeElapsed;
        }

        await FirebaseFirestore.instance
            .collection('jugadores')
            .doc(_currentPlayer!.id)
            .set({
              'puntajes': {_activeGameType: gameData},
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firebase save error: $e');
      }

      // Registrar puntaje localmente
      await LocalStorageService().registerScore(
        firstName: _currentPlayer!.firstName,
        lastName: _currentPlayer!.lastName,
        score: score,
        gameType: _activeGameType,
        timeElapsed: timeElapsed,
      );

      // Actualizar puntaje del jugador actual para mostrar en el leaderboard
      _currentPlayer!.score = score;
    }

    if (!mounted) return;
    setState(() {
      _currentScreen = 'leaderboard';
    });
  }

  void _onRestartSession() {
    setState(() {
      _currentPlayer = PlayerLead(
        id: 'temp_kiosk_user',
        firstName: 'Invitado',
        lastName: '',
        email: 'invitado@banco.com',
        identificacion: '9999999999',
        score: 0,
        gameType: 'penalty',
        timestamp: DateTime.now().toIso8601String(),
      );
      _currentScreen = 'menu';
    });
  }

  void _onChangeGame() {
    setState(() {
      _currentScreen = 'menu';
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case 'registration':
        return RegistrationScreen(onRegister: _onRegister);
      case 'menu':
        return MenuScreen(
          player: _currentPlayer,
          onSelectGame: _onSelectGame,
          onRestartSession: _onRestartSession,
        );
      case 'game':
        return GameScreen(
          player: _currentPlayer,
          gameType: _activeGameType,
          onGameFinished: _onGameFinished,
        );
      case 'saving':
        return SavingScoreScreen(gameType: _activeGameType);
      case 'leaderboard':
        return LeaderboardScreen(
          gameType: _activeGameType,
          currentPlayer: _currentPlayer,
          onRestartSession: _onRestartSession,
          onChangeGame: _onChangeGame,
        );
      default:
        return RegistrationScreen(onRegister: _onRegister);
    }
  }
}
