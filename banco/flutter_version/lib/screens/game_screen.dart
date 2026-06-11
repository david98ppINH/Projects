import 'dart:async';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/player_lead.dart';
import '../theme/bda_theme.dart';
import '../game/penalty_game.dart';
import '../game/trivia_questions.dart';
import '../services/audio_service.dart';

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
  bool _lastTriviaAnswerCorrect = false;
  String _lastTriviaCorrectAnswer = '';
  String _lastTriviaExtra = '';
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
          AudioService().playSilbato();
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

    // Play start whistle
    AudioService().playSilbato();

    _triviaStopwatch.start();
    _triviaTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _safeSetState(() {});
    });
  }

  void _loadTriviaQuestion() {
    if (_currentQuestionIndex >= _triviaQuestions.length) {
      _triviaTimer?.cancel();
      _triviaStopwatch.stop();
      AudioService().playSilbato();
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
      AudioService().playAplausos();
    } else {
      AudioService().playFalla();
    }

    String feedbackMsg = isCorrect ? '¡CORRECTO!' : '¡INCORRECTO!';
    _lastTriviaAnswerCorrect = isCorrect;
    _lastTriviaCorrectAnswer = q.correctAnswer;
    _lastTriviaExtra = q.extra ?? '';
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

          if (!isTrivia) ..._buildPenaltyHud(),

          // Letrero de Mensajes Animados Gigantes
          if (_showMessage)
            isTrivia ? _buildTriviaFeedbackOverlay() : _buildPenaltyMessage(),

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

  List<Widget> _buildPenaltyHud() {
    return [
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
          child: Column(
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
    ];
  }

  Widget _buildPenaltyMessage() {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hudMessage.contains('GOLAZO')
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
              color: _hudMessage.contains('GOLAZO')
                  ? BdaColors.navy
                  : BdaColors.red,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
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
    final progress = (_currentQuestionIndex + 1) / _triviaQuestions.length;

    return Container(
      color: BdaColors.sipySoftGrey,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              color: BdaColors.sipyHeaderBackground,
              border: Border(
                bottom: BorderSide(
                  color: BdaColors.sipyInputBorder.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Center(
              child: Image.asset(
                BdaAssets.sippyLogo,
                width: 94,
                height: 47,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTriviaMetricCard(
                          label:
                              'JUGADOR: ${widget.player?.firstName ?? "Invitado"}',
                          value: 'PUNTOS: $_score',
                          alignEnd: false,
                        ),
                      ),
                      const SizedBox(width: 22),
                      SizedBox(
                        width: 150,
                        child: _buildTriviaMetricCard(
                          label: 'TIEMPO',
                          value: _getFormattedTime(),
                          alignEnd: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'PREGUNTA ${_currentQuestionIndex + 1} DE ${_triviaQuestions.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: BdaFonts.gotham,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: BdaColors.sipyBodyText,
                      letterSpacing: 3.8,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: BdaColors.sipyNeutralBar,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        BdaColors.sipyBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 180),
                    padding: const EdgeInsets.fromLTRB(36, 28, 32, 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                        left: BorderSide(
                          color: BdaColors.sipyOptionGreen,
                          width: 5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        question.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: BdaFonts.gotham,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: BdaColors.sipyDarkText,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      itemCount: _currentOptions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        final option = _currentOptions[index];
                        return _buildTriviaAnswerButton(
                          option: option,
                          correctAnswer: question.correctAnswer,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriviaMetricCard({
    required String label,
    required String value,
    required bool alignEnd,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BdaColors.sipyInputBorder),
      ),
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: BdaFonts.gotham,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BdaColors.sipyBodyText,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: BdaFonts.gotham,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: BdaColors.sipyBlue,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriviaAnswerButton({
    required String option,
    required String correctAnswer,
  }) {
    final isSelected = _selectedOption == option;
    final isCorrect = option == correctAnswer;

    Color backgroundColor = Colors.white;
    Color borderColor = BdaColors.sipyInputBorder.withValues(alpha: 0.3);
    Color textColor = BdaColors.sipyDarkText;
    double opacity = 1;
    Widget? trailing;

    if (_isAnswerSelected) {
      if (isCorrect) {
        backgroundColor = BdaColors.sipyOptionGreen.withValues(alpha: 0.1);
        borderColor = BdaColors.sipyOptionGreen;
        textColor = BdaColors.sipyOptionGreen;
        trailing = const Icon(
          Icons.check_circle,
          color: BdaColors.sipyOptionGreen,
          size: 24,
        );
      } else if (isSelected) {
        backgroundColor = BdaColors.sipyErrorFill;
        borderColor = BdaColors.sipyErrorBorder;
        textColor = BdaColors.sipyError;
        trailing = const Icon(
          Icons.cancel,
          color: BdaColors.sipyError,
          size: 24,
        );
      } else {
        backgroundColor = BdaColors.sipyInputFill;
        textColor = BdaColors.sipyBodyText;
        opacity = 0.4;
      }
    }

    return GestureDetector(
      onTap: () => _onTriviaAnswerSelected(option),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 17),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _isAnswerSelected && (isCorrect || isSelected) ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: BdaFonts.gotham,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.25,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTriviaFeedbackOverlay() {
    return Positioned.fill(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          color: const Color(0xFFEFEFEF).withValues(alpha: 0.9),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: _lastTriviaAnswerCorrect
                ? _buildCorrectFeedbackCard()
                : _buildIncorrectFeedbackCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildIncorrectFeedbackCard() {
    final detail = _lastTriviaExtra.isEmpty
        ? 'La respuesta correcta es $_lastTriviaCorrectAnswer.'
        : _lastTriviaExtra;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(42, 54, 42, 44),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: const Border(
          top: BorderSide(color: BdaColors.sipyBlue, width: 8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 64,
            spreadRadius: -12,
            offset: const Offset(0, 32),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEAE7EA),
              shape: BoxShape.circle,
              border: Border.all(
                color: BdaColors.sipyInputBorder.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  spreadRadius: -3,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.priority_high,
              color: BdaColors.sipyErrorBorder,
              size: 42,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            '¡INCORRECTO!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: BdaFonts.gotham,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: BdaColors.sipyError,
              letterSpacing: -1.6,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: BdaFonts.gotham,
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: BdaColors.sipyDarkText,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectFeedbackCard() {
    final detail = _lastTriviaExtra.isEmpty
        ? '¡Excelente elección!'
        : '¡Excelente elección! $_lastTriviaExtra.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '¡CORRECTO!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: BdaFonts.gotham,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: BdaColors.sipyBlue,
            letterSpacing: -1.6,
            height: 1,
          ),
        ),
        const SizedBox(height: 58),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(36, 46, 36, 46),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: const Border(
              left: BorderSide(color: BdaColors.sipyGreen, width: 5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _lastTriviaCorrectAnswer.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: BdaFonts.gotham,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: BdaColors.sipyShadowBlue,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: BdaFonts.gotham,
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: BdaColors.sipyBodyText.withValues(alpha: 0.8),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
