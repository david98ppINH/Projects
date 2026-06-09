import 'dart:async';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/player_lead.dart';
import '../theme/bda_theme.dart';
import '../game/penalty_game.dart';
import '../game/trivia_questions.dart';

class GameScreen extends StatefulWidget {
  final PlayerLead? player;
  final String gameType;
  final Function(int, {int? timeElapsed}) onGameFinished;

  const GameScreen({
    super.key,
    required this.player,
    required this.gameType,
    required this.onGameFinished,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  FlameGame? _game;
  int _score = 0;

  // Específico de Penales
  int _attempts = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Específico de Trivia
  List<TriviaQuestion> _triviaQuestions = [];
  int _currentQuestionIndex = 0;
  final Stopwatch _triviaStopwatch = Stopwatch();
  Timer? _triviaTimer;
  List<String> _currentOptions = [];
  bool _isAnswerSelected = false;
  String? _selectedOption;

  String _hudMessage = '';
  bool _showMessage = false;
  late AnimationController _messageAnimationController;
  late Animation<double> _scaleAnimation;

  PenaltyGame get _penaltyGame => _game as PenaltyGame;

  @override
  void initState() {
    super.initState();

    _messageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.elasticOut,
    );

    // Inicializar el video publicitario para ambos modos de juego
    _initPenaltyVideo();

    // Inicializar el juego correspondiente
    if (widget.gameType == 'trivia') {
      _initTrivia();
    } else {
      _game = PenaltyGame(
        onProgressUpdate: (score, attempts) {
          _safeSetState(() {
            _score = score;
            _attempts = attempts;
          });
        },
        onMessageTrigger: _triggerMessageOverlay,
        onGameOver: (finalScore) {
          _safeSetState(() {
            widget.onGameFinished(finalScore);
          });
        },
      );
    }
  }

  void _initTrivia() {
    final rand = Random();
    _triviaQuestions = List.from(triviaQuestions)..shuffle(rand);
    _triviaQuestions = _triviaQuestions.take(10).toList();
    _loadTriviaQuestion();

    _triviaStopwatch.start();
    _triviaTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _safeSetState(() {});
    });
  }

  void _loadTriviaQuestion() {
    if (_currentQuestionIndex >= _triviaQuestions.length) {
      _triviaTimer?.cancel();
      _triviaStopwatch.stop();
      widget.onGameFinished(
        _score,
        timeElapsed: _triviaStopwatch.elapsedMilliseconds,
      );
      return;
    }

    _isAnswerSelected = false;
    _selectedOption = null;
    final q = _triviaQuestions[_currentQuestionIndex];
    _currentOptions = [q.correctAnswer, ...q.incorrectAnswers];
    _currentOptions.shuffle(Random());
  }

  void _initPenaltyVideo() {
    _videoController = VideoPlayerController.asset('assets/animacion.mp4')
      ..addListener(_keepPenaltyVideoPlaying)
      ..initialize().then((_) async {
        final controller = _videoController;
        if (controller == null) return;

        await controller.setLooping(true);
        await controller.setVolume(0.0); // Mudo para permitir autoplay en web
        await controller.play();

        _safeSetState(() {
          _isVideoInitialized = true;
        });
      });
  }

  void _keepPenaltyVideoPlaying() {
    final controller = _videoController;
    if (!mounted || controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.hasError) return;

    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 120)) {
      controller.seekTo(Duration.zero);
      controller.play();
      return;
    }

    if (!controller.value.isPlaying) {
      controller.play();
    }
  }

  void _onTriviaAnswerSelected(String selected) {
    if (_isAnswerSelected) return;
    _safeSetState(() {
      _isAnswerSelected = true;
      _selectedOption = selected;
    });

    final q = _triviaQuestions[_currentQuestionIndex];
    final isCorrect = selected == q.correctAnswer;

    if (isCorrect) {
      _score++;
    }

    String feedbackMsg = isCorrect ? '¡CORRECTO!' : '¡INCORRECTO!';
    if (q.extra != null && q.extra!.isNotEmpty) {
      String extraText = q.extra!;
      extraText = extraText[0].toUpperCase() + extraText.substring(1);
      feedbackMsg += '\n$extraText';
    }

    _triggerMessageOverlay(feedbackMsg, durationMs: 1400);

    Future.delayed(const Duration(milliseconds: 1400), () {
      _safeSetState(() {
        _currentQuestionIndex++;
        _loadTriviaQuestion();
      });
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _triggerMessageOverlay(String msg, {int durationMs = 1100}) {
    _safeSetState(() {
      _hudMessage = msg;
      _showMessage = true;
    });
    _messageAnimationController.forward(from: 0.0);

    // Ocultar mensaje después de X milisegundos
    Future.delayed(Duration(milliseconds: durationMs), () {
      _safeSetState(() {
        _showMessage = false;
        _messageAnimationController.reverse();
      });
    });
  }

  @override
  void dispose() {
    _triviaTimer?.cancel();
    _triviaStopwatch.stop();
    _messageAnimationController.dispose();
    _videoController?.removeListener(_keepPenaltyVideoPlaying);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTrivia = widget.gameType == 'trivia';

    return Container(
      color: BdaColors.navy,
      child: Stack(
        children: [
          // Fondo o Video según el juego
          if (!isTrivia && _game != null)
            Positioned.fromRect(
              rect: _penaltyGame.billboardRect,
              child: _buildBanner(),
            ),

          // Motor de Juego Flame o Interfaz de Trivia
          if (!isTrivia && _game != null)
            Positioned.fill(
              child: GestureDetector(
                onPanStart: (details) {
                  _penaltyGame.handleSwipeStart(details.localPosition);
                },
                onPanUpdate: (details) {
                  _penaltyGame.handleSwipeUpdate(details.localPosition);
                },
                onPanEnd: (details) {
                  _penaltyGame.handleSwipeEnd();
                },
                child: GameWidget(
                  game: _game!,
                  backgroundBuilder: (context) =>
                      Container(color: Colors.transparent),
                ),
              ),
            ),

          if (isTrivia) _buildTriviaUI(),

          // HUD Superior - Panel del Jugador y Puntaje (Izquierda)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: BdaColors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: BdaColors.navy.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JUGADOR: ${widget.player?.firstName ?? "Invitado"}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: BdaColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PUNTOS: $_score',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: BdaColors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // HUD Superior Derecho
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: BdaColors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: BdaColors.navy.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isTrivia
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'TIEMPO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: BdaColors.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getFormattedTime(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: BdaColors.red,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'DISPAROS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: BdaColors.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_attempts / ${PenaltyGame.maxAttempts}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: BdaColors.red,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Letrero de Mensajes Animados Gigantes
          if (_showMessage)
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          _hudMessage.contains('GOLAZO') ||
                              _hudMessage.contains('CORRECTO')
                          ? BdaColors.navy
                          : BdaColors.red,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    _hudMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color:
                          _hudMessage.contains('GOLAZO') ||
                              _hudMessage.contains('CORRECTO')
                          ? BdaColors.navy
                          : BdaColors.red,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

          // Ayuda Visual Táctil para Deslizamiento (Solo en Penales al inicio)
          if (!isTrivia &&
              _attempts == 0 &&
              !_penaltyGame.isKicked &&
              !_penaltyGame.isDragging)
            Positioned(
              bottom: 220,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: BdaColors.navy.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.swipe, color: BdaColors.gold, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '¡Desliza hacia arriba para patear!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    if (_isVideoInitialized && _videoController != null) {
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  String _getFormattedTime() {
    final ms = _triviaStopwatch.elapsedMilliseconds;
    final sec = ms ~/ 1000;
    final fractions = (ms % 1000) ~/ 10;
    return '$sec.${fractions.toString().padLeft(2, '0')}s';
  }

  Widget _buildTriviaUI() {
    if (_triviaQuestions.isEmpty ||
        _currentQuestionIndex >= _triviaQuestions.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final question = _triviaQuestions[_currentQuestionIndex];

    return Container(
      color: BdaColors.lightBackground,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
      child: Column(
        children: [
          // Progreso
          Text(
            'PREGUNTA ${_currentQuestionIndex + 1} DE ${_triviaQuestions.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Pregunta
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: BdaColors.navy.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: BdaColors.lightGrey, width: 2),
            ),
            child: Text(
              question.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: BdaColors.navy,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Opciones de respuesta
          Expanded(
            child: ListView.separated(
              itemCount: _currentOptions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final option = _currentOptions[index];
                final isSelected = _selectedOption == option;
                final isCorrect = option == question.correctAnswer;

                Color btnColor = Colors.white;
                Color borderColor = BdaColors.lightGrey;
                Color textColor = BdaColors.navy;

                if (_isAnswerSelected) {
                  if (isCorrect) {
                    btnColor = Colors.green;
                    textColor = Colors.white;
                    borderColor = Colors.green;
                  } else if (isSelected && !isCorrect) {
                    btnColor = BdaColors.red;
                    textColor = Colors.white;
                    borderColor = BdaColors.red;
                  }
                }

                return GestureDetector(
                  onTap: () => _onTriviaAnswerSelected(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: btnColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                      boxShadow: [
                        if (!_isAnswerSelected)
                          BoxShadow(
                            color: BdaColors.navy.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Text(
                      option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 27.0),
            child: SizedBox(
              height: 68,
              width: double.infinity,
              child: _buildBanner(),
            ),
          ),
        ],
      ),
    );
  }
}
