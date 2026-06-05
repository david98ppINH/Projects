import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/player_lead.dart';
import '../theme/bda_theme.dart';
import '../game/penalty_game.dart';
import '../game/reflex_game.dart';

class GameScreen extends StatefulWidget {
  final PlayerLead? player;
  final String gameType;
  final Function(int) onGameFinished;

  const GameScreen({
    super.key,
    required this.player,
    required this.gameType,
    required this.onGameFinished,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late FlameGame _game;
  int _score = 0;
  
  // Específico de Penales
  int _attempts = 0;
  
  // Específico de Reflejos
  int _lives = 3;
  int _remainingTime = ReflexGame.gameDurationSeconds;

  String _hudMessage = '';
  bool _showMessage = false;
  late AnimationController _messageAnimationController;
  late Animation<double> _scaleAnimation;

  PenaltyGame get _penaltyGame => _game as PenaltyGame;
  ReflexGame get _reflexGame => _game as ReflexGame;

  @override
  void initState() {
    super.initState();
    
    // Configurar animación para mensajes gigantes de overlay
    _messageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.elasticOut,
    );

    // Inicializar el juego correspondiente
    if (widget.gameType == 'reflex') {
      _game = ReflexGame(
        onProgressUpdate: (score, lives, remainingTime) {
          _safeSetState(() {
            _score = score;
            _lives = lives;
            _remainingTime = remainingTime;
          });
        },
        onMessageTrigger: _triggerMessageOverlay,
        onGameOver: (finalScore) {
          _safeSetState(() {
            widget.onGameFinished(finalScore);
          });
        },
      );
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

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(fn);
      }
    });
  }

  void _triggerMessageOverlay(String msg) {
    _safeSetState(() {
      _hudMessage = msg;
      _showMessage = true;
    });
    _messageAnimationController.forward(from: 0.0);
    
    // Ocultar mensaje después de 1.1 segundos
    Future.delayed(const Duration(milliseconds: 1100), () {
      _safeSetState(() {
        _showMessage = false;
        _messageAnimationController.reverse();
      });
    });
  }

  @override
  void dispose() {
    _messageAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReflex = widget.gameType == 'reflex';

    return Container(
      color: BdaColors.navy,
      child: Stack(
        children: [
          // 1. Motor de Juego Flame con Detección de Gestos Separada
          Positioned.fill(
            child: GestureDetector(
              onTapUp: isReflex
                  ? (details) {
                      _reflexGame.handleTap(details.localPosition);
                    }
                  : null,
              onPanStart: !isReflex
                  ? (details) {
                      _penaltyGame.handleSwipeStart(details.localPosition);
                    }
                  : null,
              onPanUpdate: !isReflex
                  ? (details) {
                      _penaltyGame.handleSwipeUpdate(details.localPosition);
                    }
                  : null,
              onPanEnd: !isReflex
                  ? (details) {
                      _penaltyGame.handleSwipeEnd();
                    }
                  : null,
              child: GameWidget(game: _game),
            ),
          ),

          // 2. HUD Superior - Panel del Jugador y Puntaje (Izquierda)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: BdaColors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: BdaColors.navy.withOpacity(0.10),
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

          // 3. HUD Superior Derecho (Depende del juego)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: BdaColors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: BdaColors.navy.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isReflex
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TIEMPO: ${_remainingTime}s',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: BdaColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 3.0),
                              child: Icon(
                                Icons.sports_soccer,
                                color: index < _lives ? BdaColors.red : Colors.grey[300],
                                size: 14,
                              ),
                            );
                          }),
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

          // 4. Letrero de Mensajes Animados Gigantes
          if (_showMessage)
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: (_hudMessage == '¡GOLAZO!' || _hudMessage == '¡TOQUE!')
                          ? BdaColors.navy
                          : (_hudMessage == '¡ATAJADA!' || _hudMessage == '¡FALLO!' || _hudMessage == '¡SIN VIDAS!'
                              ? BdaColors.red
                              : Colors.grey),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    _hudMessage,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: (_hudMessage == '¡GOLAZO!' || _hudMessage == '¡TOQUE!')
                          ? BdaColors.navy
                          : (_hudMessage == '¡ATAJADA!' || _hudMessage == '¡FALLO!' || _hudMessage == '¡SIN VIDAS!'
                              ? BdaColors.red
                              : Colors.grey[700]),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

          // 5. Ayuda Visual Táctil para Deslizamiento (Solo en Penales al inicio)
          if (!isReflex && _attempts == 0 && !_penaltyGame.isKicked && !_penaltyGame.isDragging)
            Positioned(
              bottom: 220,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: BdaColors.navy.withOpacity(0.8),
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
}
