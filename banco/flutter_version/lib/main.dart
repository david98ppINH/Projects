import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/bda_theme.dart';
import 'services/local_storage_service.dart';
import 'screens/registration_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/game_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'models/player_lead.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      home: const KioskScaleWrapper(
        child: KioskFlowNavigator(),
      ),
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
      backgroundColor: Colors.black, // Fondo negro para márgenes (si la pantalla no es 9:16)
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 540,
              height: 960,
              child: ClipRect(
                child: child,
              ),
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
  String _currentScreen = 'registration'; // registration, menu, game, leaderboard
  PlayerLead? _currentPlayer;
  String _activeGameType = 'penalty'; // penalty, keepie, reflex

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

  void _onGameFinished(int score) async {
    if (_currentPlayer != null) {
      // Registrar puntaje localmente
      await LocalStorageService().registerScore(
        firstName: _currentPlayer!.firstName,
        lastName: _currentPlayer!.lastName,
        score: score,
        gameType: _activeGameType,
      );
      
      // Actualizar puntaje del jugador actual para mostrar en el leaderboard
      _currentPlayer!.score = score;
    }
    
    setState(() {
      _currentScreen = 'leaderboard';
    });
  }

  void _onRestartSession() {
    setState(() {
      _currentPlayer = null;
      _currentScreen = 'registration';
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
