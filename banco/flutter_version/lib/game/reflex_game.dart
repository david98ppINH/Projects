import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class ReflexTarget {
  final double x;
  final double y;
  final double radius;
  String? feedbackState; // 'SUCCESS', 'FAILURE', or null
  int feedbackTimer = 0; // en fotogramas

  ReflexTarget({required this.x, required this.y, required this.radius});
}

class ReflexGame extends FlameGame {
  // Dimensiones lógicas fijas del canvas
  static const double logicalWidth = 540.0;
  static const double logicalHeight = 960.0;

  // Estado del Juego
  int score = 0;
  int lives = 3;
  static const int gameDurationSeconds = 45;
  late double startTimeSeconds;
  bool isGameOverTriggered = false;

  // Objetivos / Sensores
  List<ReflexTarget> targets = [];
  int activeTargetIndex = -1;
  late double lastSpawnTimeSeconds;
  late double currentTargetDurationSeconds;
  static const double baseTargetDurationSeconds = 1.5;

  // Callbacks para comunicar con la interfaz Flutter
  final Function(int score, int lives, int remainingTime) onProgressUpdate;
  final Function(String msg) onMessageTrigger;
  final Function(int finalScore) onGameOver;

  ReflexGame({
    required this.onProgressUpdate,
    required this.onMessageTrigger,
    required this.onGameOver,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    startTimeSeconds = DateTime.now().millisecondsSinceEpoch / 1000.0;
    lastSpawnTimeSeconds = startTimeSeconds;
    currentTargetDurationSeconds = baseTargetDurationSeconds;

    _initializeTargets();
    _spawnNewTarget();

    // Notificación inicial
    onProgressUpdate(score, lives, gameDurationSeconds);
  }

  void _initializeTargets() {
    const double radius = 55.0;
    // 6 posiciones de sensores táctiles
    targets = [
      ReflexTarget(
        x: logicalWidth * 0.22,
        y: logicalHeight * 0.40,
        radius: radius,
      ), // Alto Izquierda
      ReflexTarget(
        x: logicalWidth * 0.50,
        y: logicalHeight * 0.32,
        radius: radius,
      ), // Alto Centro∏
      ReflexTarget(
        x: logicalWidth * 0.78,
        y: logicalHeight * 0.40,
        radius: radius,
      ), // Alto Derecha
      ReflexTarget(
        x: logicalWidth * 0.22,
        y: logicalHeight * 0.65,
        radius: radius,
      ), // Bajo Izquierda
      ReflexTarget(
        x: logicalWidth * 0.50,
        y: logicalHeight * 0.73,
        radius: radius,
      ), // Bajo Centro
      ReflexTarget(
        x: logicalWidth * 0.78,
        y: logicalHeight * 0.65,
        radius: radius,
      ), // Bajo Derecha
    ];
  }

  void _spawnNewTarget() {
    final random = Random();
    int prevIndex = activeTargetIndex;
    int newIndex = prevIndex;

    // Asegurar que salga un sensor diferente al anterior
    while (newIndex == prevIndex) {
      newIndex = random.nextInt(targets.length);
    }

    activeTargetIndex = newIndex;
    lastSpawnTimeSeconds = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // Incremento de dificultad más agresivo: reduce 0.08s por acierto hasta un mínimo de 0.40s
    currentTargetDurationSeconds = (baseTargetDurationSeconds - (score * 0.08))
        .clamp(0.40, baseTargetDurationSeconds);
  }

  void handleTap(Offset localPosition) {
    if (isGameOverTriggered || lives <= 0) return;

    bool hitActive = false;
    int hitInactiveIndex = -1;

    // Aumentar radio de colisión en 1.3x para compensar el grosor del vidrio de 6.3mm del tótem
    const double collisionMultiplier = 1.3;

    for (int i = 0; i < targets.length; i++) {
      final t = targets[i];
      final distance = sqrt(
        pow(localPosition.dx - t.x, 2) + pow(localPosition.dy - t.y, 2),
      );

      if (distance <= t.radius * collisionMultiplier) {
        if (i == activeTargetIndex) {
          hitActive = true;
          break;
        } else {
          hitInactiveIndex = i;
        }
      }
    }

    if (hitActive) {
      score++;

      // Feedback exitoso (Verde) en el sensor presionado por medio segundo (~30 frames)
      targets[activeTargetIndex].feedbackState = 'SUCCESS';
      targets[activeTargetIndex].feedbackTimer = 30;

      _spawnNewTarget();
    } else if (hitInactiveIndex != -1) {
      lives--;

      // Feedback erróneo (Rojo) en el sensor presionado
      targets[hitInactiveIndex].feedbackState = 'FAILURE';
      targets[hitInactiveIndex].feedbackTimer = 25; // mostrar por 25 fotogramas

      onMessageTrigger('¡FALLO!');
      if (lives <= 0) {
        _endGame('¡SIN VIDAS!');
      } else {
        _spawnNewTarget();
      }
    }
  }

  void _endGame(String reasonMessage) {
    if (isGameOverTriggered) return;
    isGameOverTriggered = true;

    // Notificar el último estado (ej. vidas = 0) a la interfaz Flutter antes de pausar actualizaciones
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final elapsedGameTime = now - startTimeSeconds;
    final remainingTime = (gameDurationSeconds - elapsedGameTime).ceil().clamp(
      0,
      gameDurationSeconds,
    );
    onProgressUpdate(score, lives, remainingTime);

    onMessageTrigger(reasonMessage);

    Future.delayed(const Duration(milliseconds: 1400), () {
      onGameOver(score);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOverTriggered) return;

    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // 1. Control del tiempo del juego
    final elapsedGameTime = now - startTimeSeconds;
    final remainingTime = (gameDurationSeconds - elapsedGameTime).ceil().clamp(
      0,
      gameDurationSeconds,
    );

    onProgressUpdate(score, lives, remainingTime);

    if (remainingTime <= 0) {
      _endGame('¡TIEMPO!');
      return;
    }

    // 2. Control de expiración del sensor activo actual
    final timeSinceSpawn = now - lastSpawnTimeSeconds;
    if (timeSinceSpawn > currentTargetDurationSeconds) {
      lives--;

      // Registrar falla en el sensor activo por expirar
      if (activeTargetIndex != -1) {
        targets[activeTargetIndex].feedbackState = 'FAILURE';
        targets[activeTargetIndex].feedbackTimer = 25;
      }

      if (lives <= 0) {
        _endGame('¡SIN VIDAS!');
      } else {
        _spawnNewTarget();
      }
    }

    // 3. Temporizadores de feedback visual
    for (final t in targets) {
      if (t.feedbackTimer > 0) {
        t.feedbackTimer--;
        if (t.feedbackTimer == 0) {
          t.feedbackState = null;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Dibujar el estadio deportivo de fondo para consistencia visual
    _drawStadiumBackground(canvas);

    // 2. Dibujar título
    _drawTitle(canvas);

    // 3. Dibujar sensores
    _drawSensors(canvas);
  }

  void _drawStadiumBackground(Canvas canvas) {
    // Fondo grisáceo
    final bgPaint = Paint()..color = const Color(0xFFF0F2F5);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, logicalWidth, logicalHeight),
      bgPaint,
    );

    // Gradas
    final standsPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, logicalWidth, logicalHeight * 0.4),
      standsPaint,
    );

    final standsBndPaint = Paint()..color = const Color(0xFFCBD5E1);
    final pathStands = Path()
      ..moveTo(0, logicalHeight * 0.4)
      ..lineTo(logicalWidth, logicalHeight * 0.4)
      ..lineTo(logicalWidth, logicalHeight * 0.42)
      ..lineTo(0, logicalHeight * 0.42)
      ..close();
    canvas.drawPath(pathStands, standsBndPaint);

    // Valla Publicitaria del BDA
    final adBoardPaint = Paint()..color = const Color(0xFF00205B);
    canvas.drawRect(
      const Rect.fromLTWH(
        0,
        logicalHeight * 0.38,
        logicalWidth,
        logicalHeight * 0.05,
      ),
      adBoardPaint,
    );

    // Césped
    final fieldPaint = Paint()..color = const Color(0xFF4CAF50);
    final pathField = Path()
      ..moveTo(0, logicalHeight * 0.43)
      ..lineTo(logicalWidth, logicalHeight * 0.43)
      ..lineTo(logicalWidth, logicalHeight)
      ..lineTo(0, logicalHeight)
      ..close();
    canvas.drawPath(pathField, fieldPaint);

    // Líneas blancas del área
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pathArea = Path()
      ..moveTo(logicalWidth * 0.05, logicalHeight)
      ..lineTo(logicalWidth * 0.2, logicalHeight * 0.43)
      ..lineTo(logicalWidth * 0.8, logicalHeight * 0.43)
      ..lineTo(logicalWidth * 0.95, logicalHeight);
    canvas.drawPath(pathArea, linePaint);
  }

  void _drawTitle(Canvas canvas) {
    // Dibujar texto indicador superior en el canvas
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '¡TOCA EL SENSOR ACTIVO!',
        style: TextStyle(
          color: Color(0xFF00205B),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          fontFamily: 'Assistant',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((logicalWidth - textPainter.width) / 2, logicalHeight * 0.22),
    );
  }

  void _drawSensors(Canvas canvas) {
    final tick = DateTime.now().millisecondsSinceEpoch / 1000.0;

    for (int i = 0; i < targets.length; i++) {
      final t = targets[i];
      final isActive = (i == activeTargetIndex && !isGameOverTriggered);

      canvas.save();
      canvas.translate(t.x, t.y);

      if (t.feedbackState == 'SUCCESS') {
        // Dibujar sensor exitoso (Verde)
        final successPaint = Paint()..color = const Color(0xFF4CAF50);
        final borderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset.zero, t.radius, successPaint);
        canvas.drawCircle(Offset.zero, t.radius, borderPaint);

        // Marca de checkmark
        final checkPainter = TextPainter(
          text: const TextSpan(
            text: '✓',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        checkPainter.layout();
        checkPainter.paint(
          canvas,
          Offset(-checkPainter.width / 2, -checkPainter.height / 2 - 2),
        );
      } else if (t.feedbackState == 'FAILURE') {
        // Dibujar sensor fallido (Rojo)
        final failurePaint = Paint()..color = const Color(0xFFE4002B);
        final borderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset.zero, t.radius, failurePaint);
        canvas.drawCircle(Offset.zero, t.radius, borderPaint);

        // Marca de error
        final crossPainter = TextPainter(
          text: const TextSpan(
            text: '✗',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        crossPainter.layout();
        crossPainter.paint(
          canvas,
          Offset(-crossPainter.width / 2, -crossPainter.height / 2 - 2),
        );
      } else if (isActive) {
        // Dibujar sensor activo con animación de pulso y diseño de marca "Austro"
        final double pulse = sin(tick * 12.0) * 6.0;

        // Halo de brillo
        final glowPaint = Paint()
          ..color = const Color(0xFFFFB81C).withOpacity(0.35);
        canvas.drawCircle(Offset.zero, t.radius + pulse + 12.0, glowPaint);

        // Círculo blanco central
        final activePaint = Paint()..color = Colors.white;
        final activeBorder = Paint()
          ..color = const Color(0xFFFFB81C)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset.zero, t.radius + pulse, activePaint);
        canvas.drawCircle(Offset.zero, t.radius + pulse, activeBorder);

        // Anillo rojo interno
        final redRing = Paint()
          ..color = const Color(0xFFE4002B)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset.zero, t.radius + pulse - 6.0, redRing);

        // Texto "A" conceptual
        final letterPainter = TextPainter(
          text: const TextSpan(
            text: 'A',
            style: TextStyle(
              color: Color(0xFF00205B),
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        letterPainter.layout();
        letterPainter.paint(
          canvas,
          Offset(-letterPainter.width / 2, -letterPainter.height / 2 - 6.0),
        );

        // Subtexto "AUSTRO"
        final subtextPainter = TextPainter(
          text: const TextSpan(
            text: 'AUSTRO',
            style: TextStyle(
              color: Color(0xFF00205B),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        subtextPainter.layout();
        subtextPainter.paint(
          canvas,
          Offset(-subtextPainter.width / 2, t.radius * 0.4),
        );
      } else {
        // Dibujar sensor inactivo (Semi-transparente)
        final inactivePaint = Paint()..color = Colors.white.withOpacity(0.6);
        final inactiveBorder = Paint()
          ..color = const Color(0xFF00205B).withOpacity(0.2)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(Offset.zero, t.radius, inactivePaint);
        canvas.drawCircle(Offset.zero, t.radius, inactiveBorder);

        // Logotipo apagado
        final innerPaint = Paint()
          ..color = const Color(0xFF00205B).withOpacity(0.12);
        canvas.drawCircle(Offset.zero, t.radius * 0.35, innerPaint);
      }

      canvas.restore();
    }
  }
}
