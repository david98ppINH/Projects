import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class PenaltyGame extends FlameGame {
  // Dimensiones lógicas fijas del canvas de quiosco
  static const double logicalWidth = 540.0;
  static const double logicalHeight = 960.0;

  // Estado del juego
  double ballX = logicalWidth / 2;
  double ballY = logicalHeight * 0.82;
  double ballZ = 0.0; // 0.0 (cerca de la pantalla) a 1.0 (en la línea de gol)
  double ballVx = 0.0;
  double ballVy = 0.0;
  double ballVz = 0.0;
  bool isKicked = false;

  double goalieX = logicalWidth / 2;
  double goalieY = logicalHeight * 0.35;
  double goalieTargetX = logicalWidth / 2;
  double goalieTargetY = logicalHeight * 0.35;
  final double goalieSpeed = 0.09; // Agilidad de la IA

  // HUD y Sesión
  int score = 0;
  int attempts = 0;
  static const int maxAttempts = 5;

  // Feedback
  String displayMessage = '';
  int displayMessageDuration = 0; // en ciclos

  // Arrastre/Tiro
  Offset? swipeStart;
  Offset? swipeCurrent;
  bool isDragging = false;

  // Callbacks para comunicar con la interfaz Flutter
  final Function(int score, int attempts) onProgressUpdate;
  final Function(String msg) onMessageTrigger;
  final Function(int finalScore) onGameOver;

  PenaltyGame({
    required this.onProgressUpdate,
    required this.onMessageTrigger,
    required this.onGameOver,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    resetBall();
    resetGoalie();
  }

  void resetBall() {
    ballX = logicalWidth / 2;
    ballY = logicalHeight * 0.82;
    ballZ = 0.0;
    ballVx = 0.0;
    ballVy = 0.0;
    ballVz = 0.0;
    isKicked = false;
  }

  void resetGoalie() {
    goalieX = logicalWidth / 2;
    goalieY = logicalHeight * 0.35;
    goalieTargetX = logicalWidth / 2;
    goalieTargetY = logicalHeight * 0.35;
  }

  void handleSwipeStart(Offset localPosition) {
    if (isKicked || attempts >= maxAttempts) return;
    swipeStart = localPosition;
    swipeCurrent = localPosition;
    isDragging = true;
  }

  void handleSwipeUpdate(Offset localPosition) {
    if (!isDragging) return;
    swipeCurrent = localPosition;
  }

  void handleSwipeEnd() {
    if (!isDragging || swipeStart == null || swipeCurrent == null) return;
    isDragging = false;

    final start = swipeStart!;
    final end = swipeCurrent!;
    final vector = end - start;

    // Validar arrastre: distancia mínima y dirección ascendente
    if (vector.distance > 20 && end.dy < start.dy) {
      // Aplicar multiplicadores a las físicas para compensar pantallas de 55"
      ballVx = vector.dx * 0.052;
      ballVy = vector.dy * 0.078;
      ballVz = 0.038; // Velocidad de alejamiento 3D constante
      isKicked = true;

      // Calcular estirada del arquero inteligente basada en el tiro
      // La IA predice a dónde va a llegar la bola e intenta cubrir esa área
      goalieTargetX = end.dx.clamp(logicalWidth * 0.22, logicalWidth * 0.78);
      goalieTargetY = (end.dy * 0.7).clamp(
        logicalHeight * 0.22,
        logicalHeight * 0.48,
      );
    }

    swipeStart = null;
    swipeCurrent = null;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isKicked) {
      // Actualizar física del balón (2.5D)
      ballX += ballVx;
      ballY += ballVy;
      ballZ += ballVz;
      ballVy += 0.30; // Gravedad artificial

      // Movimiento del arquero
      goalieX = goalieX + (goalieTargetX - goalieX) * goalieSpeed;
      goalieY = goalieY + (goalieTargetY - goalieY) * goalieSpeed;

      // Evaluar gol o atajada cuando el balón pasa la meta en Z = 1.0
      if (ballZ >= 1.0) {
        isKicked = false;
        evaluateShot();
      }
    }
  }

  void evaluateShot() {
    const double gLeft = logicalWidth * 0.2;
    const double gRight = logicalWidth * 0.8;
    const double gTop = logicalHeight * 0.2;
    const double gBottom = logicalHeight * 0.55;

    // Calcular distancia al arquero
    final goalieWidth = logicalWidth * 0.09;

    final distToGoalie = sqrt(
      pow(ballX - goalieX, 2) + pow(ballY - goalieY, 2),
    );

    // Radio de colisión ampliado en 1.5x por regla de vidrio grueso
    final collisionRadius = goalieWidth * 1.5;

    if (distToGoalie < collisionRadius) {
      // ATAJADA
      onMessageTrigger('¡ATAJADA!');
    } else if (ballX > gLeft &&
        ballX < gRight &&
        ballY > gTop &&
        ballY < gBottom) {
      // GOL
      score++;
      onMessageTrigger('¡GOLAZO!');
    } else {
      // FUERA
      onMessageTrigger('¡FUERA!');
    }

    attempts++;
    onProgressUpdate(score, attempts);

    // Esperar un momento y reiniciar o terminar
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (attempts >= maxAttempts) {
        onGameOver(score);
      } else {
        resetBall();
        resetGoalie();
      }
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // 1. Dibujar el césped y gradas
    drawStadium(canvas);

    // 2. Dibujar portería
    drawGoalPost(canvas);

    // 3. Dibujar portero
    drawGoalieWidget(canvas);

    // 4. Dibujar balón (escalado 2.5D)
    drawBallWidget(canvas);

    // 5. Dibujar indicador de trayectoria
    if (isDragging && swipeStart != null && swipeCurrent != null) {
      final paint = Paint()
        ..color = const Color(0x99E4002B)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(swipeStart!, swipeCurrent!, paint);

      final pointerPaint = Paint()..color = const Color(0xFFE4002B);
      canvas.drawCircle(swipeCurrent!, 10, pointerPaint);
    }
  }

  void drawStadium(Canvas canvas) {
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

    // Valla Publicitaria
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

    // Punto Penal
    final penaltyPaint = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(logicalWidth / 2, logicalHeight * 0.82),
        width: 15,
        height: 7,
      ),
      penaltyPaint,
    );
  }

  void drawGoalPost(Canvas canvas) {
    // Red de portería
    final netPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.5;

    final double gLeft = logicalWidth * 0.2;
    final double gRight = logicalWidth * 0.8;
    final double gTop = logicalHeight * 0.2;
    final double gBottom = logicalHeight * 0.55;

    // Dibujar malla horizontal y vertical
    final double stepX = (gRight - gLeft) / 20;
    final double stepY = (gBottom - gTop) / 12;

    for (int i = 0; i <= 20; i++) {
      final double x = gLeft + i * stepX;
      canvas.drawLine(Offset(x, gTop), Offset(x, gBottom), netPaint);
    }
    for (int j = 0; j <= 12; j++) {
      final double y = gTop + j * stepY;
      canvas.drawLine(Offset(gLeft, y), Offset(gRight, y), netPaint);
    }

    // Marcos de metal
    final postPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final pathGoal = Path()
      ..moveTo(gLeft, gBottom)
      ..lineTo(gLeft, gTop)
      ..lineTo(gRight, gTop)
      ..lineTo(gRight, gBottom);
    canvas.drawPath(pathGoal, postPaint);
  }

  void drawGoalieWidget(Canvas canvas) {
    final double goalieWidth = logicalWidth * 0.09;
    final double goalieHeight = logicalHeight * 0.12;

    canvas.save();
    canvas.translate(goalieX, goalieY);

    // Sombra del portero
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, goalieHeight * 0.55),
        width: goalieWidth * 1.5,
        height: goalieHeight * 0.25,
      ),
      shadowPaint,
    );

    // Uniforme (Azul Marino del BDA)
    final bodyPaint = Paint()
      ..color = const Color(0xFF00205B)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final rectBody = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: goalieWidth,
        height: goalieHeight * 0.9,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(rectBody, bodyPaint);
    canvas.drawRRect(rectBody, borderPaint);

    // Guantes de portero (Dorado/Oro BDA)
    final glovesPaint = Paint()..color = const Color(0xFFFFB81C);
    canvas.drawCircle(
      Offset(-goalieWidth * 0.65, -goalieHeight * 0.1),
      goalieWidth * 0.16,
      glovesPaint,
    );
    canvas.drawCircle(
      Offset(goalieWidth * 0.65, -goalieHeight * 0.1),
      goalieWidth * 0.16,
      glovesPaint,
    );

    // Cabeza
    final headPaint = Paint()..color = const Color(0xFFFFCC80);
    canvas.drawCircle(
      Offset(0, -goalieHeight * 0.65),
      goalieWidth * 0.26,
      headPaint,
    );
    canvas.drawCircle(
      Offset(0, -goalieHeight * 0.65),
      goalieWidth * 0.26,
      borderPaint,
    );

    // Pelo / Detalle
    final hairPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, -goalieHeight * 0.84),
        width: goalieWidth * 0.35,
        height: goalieHeight * 0.15,
      ),
      hairPaint,
    );

    canvas.restore();
  }

  void drawBallWidget(Canvas canvas) {
    // Escala del balón basada en la profundidad Z
    final double scale = 1.0 / (1.0 + ballZ * 1.6);
    final double radius = (logicalWidth * 0.045) * scale;

    canvas.save();
    canvas.translate(ballX, ballY);

    // Sombra del balón
    final shadowOffset = ballZ * 42.0;
    final double shadowOpacity =
        (120.0 - ballZ * 80.0).clamp(0.0, 120.0) / 255.0;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(shadowOpacity);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, radius + shadowOffset),
        width: radius * 1.8,
        height: radius * 0.4,
      ),
      shadowPaint,
    );

    // Cuerpo del balón
    final ballPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = const Color(0xFF091526)
      ..strokeWidth = (3.0 * scale).clamp(1.5, 4.0)
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset.zero, radius, ballPaint);
    canvas.drawCircle(Offset.zero, radius, borderPaint);

    // Dibujar gajos hexagonales (Negros)
    final patchPaint = Paint()..color = const Color(0xFF091526);
    canvas.drawCircle(Offset.zero, radius * 0.46, patchPaint);

    // Gajos laterales simplificados
    canvas.drawCircle(
      Offset(-radius * 0.6, -radius * 0.4),
      radius * 0.24,
      patchPaint,
    );
    canvas.drawCircle(
      Offset(radius * 0.6, -radius * 0.4),
      radius * 0.24,
      patchPaint,
    );
    canvas.drawCircle(
      Offset(-radius * 0.6, radius * 0.4),
      radius * 0.24,
      patchPaint,
    );
    canvas.drawCircle(
      Offset(radius * 0.6, radius * 0.4),
      radius * 0.24,
      patchPaint,
    );
    canvas.drawCircle(Offset(0, -radius * 0.7), radius * 0.22, patchPaint);
    canvas.drawCircle(Offset(0, radius * 0.7), radius * 0.22, patchPaint);

    canvas.restore();
  }
}
