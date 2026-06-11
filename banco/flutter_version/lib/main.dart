import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

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
      resizeToAvoidBottomInset: false,
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
  late String
  _currentScreen; // registration, splash, menu, game, saving, leaderboard
  PlayerLead? _currentPlayer;
  String _activeGameType = 'penalty'; // penalty, keepie, trivia
  String? _pendingScreen;
  PlayerLead? _pendingPlayer;
  String? _pendingGameType;

  @override
  void initState() {
    super.initState();
    _currentScreen = 'menu';
    if (_currentScreen == 'menu') {
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
    }
  }

  void _onRegister(PlayerLead player) {
    setState(() {
      _pendingPlayer = player;
      _pendingScreen = 'menu';
      _currentScreen = 'splash';
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
      _currentPlayer = _guestPlayer();
      _currentScreen = 'registration';
    });
  }

  void _onRestartSessionFromScoreboard() {
    setState(() {
      _pendingPlayer = _guestPlayer();
      _pendingScreen = 'registration';
      _currentScreen = 'splash';
    });
  }

  void _onChangeGameFromScoreboard() {
    setState(() {
      _pendingScreen = 'menu';
      _currentScreen = 'splash';
    });
  }

  PlayerLead _guestPlayer() {
    return PlayerLead(
      id: 'temp_kiosk_user',
      firstName: 'Invitado',
      lastName: '',
      email: 'invitado@banco.com',
      identificacion: '9999999999',
      score: 0,
      gameType: 'penalty',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  void _onSplashFinished() {
    setState(() {
      if (_pendingPlayer != null) {
        _currentPlayer = _pendingPlayer;
      }
      if (_pendingGameType != null) {
        _activeGameType = _pendingGameType!;
      }
      _currentScreen = _pendingScreen ?? 'menu';
      _pendingPlayer = null;
      _pendingGameType = null;
      _pendingScreen = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    late final Widget screen;
    switch (_currentScreen) {
      case 'registration':
        screen = RegistrationScreen(onRegister: _onRegister);
        break;
      case 'splash':
        screen = SplashVideoScreen(onFinished: _onSplashFinished);
        break;
      case 'menu':
        screen = MenuScreen(
          player: _currentPlayer,
          onSelectGame: _onSelectGame,
          onRestartSession: _onRestartSession,
        );
        break;
      case 'game':
        screen = GameScreen(
          player: _currentPlayer,
          gameType: _activeGameType,
          onGameFinished: _onGameFinished,
        );
        break;
      case 'saving':
        screen = SavingScoreScreen(gameType: _activeGameType);
        break;
      case 'leaderboard':
        screen = LeaderboardScreen(
          gameType: _activeGameType,
          currentPlayer: _currentPlayer,
          onRestartSession: _onRestartSessionFromScoreboard,
          onChangeGame: _onChangeGameFromScoreboard,
        );
        break;
      default:
        screen = RegistrationScreen(onRegister: _onRegister);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey(_currentScreen), child: screen),
    );
  }
}

class SplashVideoScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashVideoScreen({super.key, required this.onFinished});

  @override
  State<SplashVideoScreen> createState() => _SplashVideoScreenState();
}

class _SplashVideoScreenState extends State<SplashVideoScreen> {
  late final VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _didFinish = false;
  bool _isFadingOut = false;
  DateTime? _startedAt;

  static const _minimumVisibleDuration = Duration(milliseconds: 3000);
  static const _transitionDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/animacion_bda.mp4')
      ..addListener(_handleVideoTick)
      ..initialize()
          .then((_) async {
            if (!mounted) return;
            await _controller.setLooping(false);
            await _controller.setVolume(0);
            setState(() {
              _isInitialized = true;
            });
            await Future<void>.delayed(const Duration(milliseconds: 80));
            if (!mounted) return;
            _startedAt = DateTime.now();
            await _controller.seekTo(Duration.zero);
            await _controller.play();
          })
          .catchError((_) {
            _finishAfterMinimumDelay();
          });
  }

  void _handleVideoTick() {
    if (!_controller.value.isInitialized || _didFinish) return;
    if (_controller.value.hasError) {
      _finishAfterMinimumDelay();
      return;
    }

    final duration = _controller.value.duration;
    final position = _controller.value.position;
    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 120)) {
      _finishAfterMinimumDelay();
    }
  }

  Future<void> _finishAfterMinimumDelay() async {
    if (_didFinish) return;
    _didFinish = true;
    final startedAt = _startedAt;
    if (startedAt != null) {
      final elapsed = DateTime.now().difference(startedAt);
      final remaining = _minimumVisibleDuration - elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
    }
    if (!mounted) return;
    setState(() {
      _isFadingOut = true;
    });
    await Future<void>.delayed(_transitionDuration);
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleVideoTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isFadingOut ? 0 : 1,
      duration: _transitionDuration,
      curve: Curves.easeInOut,
      child: Container(
        color: Colors.black,
        child: Center(
          child: AnimatedOpacity(
            opacity: _isInitialized ? 1 : 0,
            duration: _transitionDuration,
            curve: Curves.easeOut,
            child: _isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  )
                : const SizedBox.expand(child: ColoredBox(color: Colors.black)),
          ),
        ),
      ),
    );
  }
}
