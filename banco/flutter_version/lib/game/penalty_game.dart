import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class PenaltyGame extends FlameGame {
  // Dimensiones lógicas fijas del canvas de quiosco
  static const double logicalWidth = 540.0;
  static const double logicalHeight = 960.0;

  static const double _pitchFieldTop = 0.43;
  static const double _pitchGoalLineY = 45.0 / 1254.0;
  static const double _pitchAreaLeftX = 87.0 / 1254.0;
  static const double _pitchAreaRightX = 1167.0 / 1254.0;

  static const double _goalSpriteSourceLeft = 48.0;
  static const double _goalSpriteSourceTop = 106.0;
  static const double _goalSpriteSourceRight = 1868.0;
  static const double _goalSpriteSourceBottom = 984.0;

  static const double _goalSpriteSourceWidth =
      _goalSpriteSourceRight - _goalSpriteSourceLeft;
  static const double _goalSpriteSourceHeight =
      _goalSpriteSourceBottom - _goalSpriteSourceTop;

  // El arco se pinta recortando el margen transparente del WebP. Estos insets
  // alinean los postes blancos, no la sombra exterior, con las líneas del área.
  static const double _goalSpriteWhiteLeftInset =
      (81.0 - _goalSpriteSourceLeft) / _goalSpriteSourceWidth;
  static const double _goalSpriteWhiteRightInset =
      (_goalSpriteSourceRight - 1832.0) / _goalSpriteSourceWidth;
  static const double _goalSpriteWhiteBottomInset =
      (_goalSpriteSourceBottom - 953.0) / _goalSpriteSourceHeight;
  static const double _goalHeightScale = 1.06;

  static const double goalAspectRatio =
      _goalSpriteSourceWidth / _goalSpriteSourceHeight;

  // Dimensiones lógicas del arco, alineadas a las líneas paralelas del área.
  double get goalLeft => logicalWidth * _pitchAreaLeftX;
  double get goalRight => logicalWidth * _pitchAreaRightX;
  double get goalBottom =>
      logicalHeight * (_pitchFieldTop + _pitchGoalLineY * (1 - _pitchFieldTop));
  double get goalTop =>
      goalBottom -
      ((goalRight - goalLeft) / goalAspectRatio) * _goalHeightScale;

  Rect get billboardRect {
    return const Rect.fromLTWH(
      logicalWidth * 0.05,
      logicalHeight * 0.355,
      logicalWidth * 0.90,
      logicalHeight * 0.07,
    );
  }

  Rect get _goalSpriteRect {
    final double drawWidth =
        (goalRight - goalLeft) /
        (1 - _goalSpriteWhiteLeftInset - _goalSpriteWhiteRightInset);
    final double drawHeight = (drawWidth / goalAspectRatio) * _goalHeightScale;
    final double drawLeft = goalLeft - drawWidth * _goalSpriteWhiteLeftInset;
    final double drawRight = goalRight + drawWidth * _goalSpriteWhiteRightInset;
    final double drawBottom =
        goalBottom + drawHeight * _goalSpriteWhiteBottomInset;

    return Rect.fromLTRB(
      drawLeft,
      drawBottom - drawHeight,
      drawRight,
      drawBottom,
    );
  }

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

  // ==========================================
  // CONFIGURACIÓN DE DIFICULTAD (Ajustable)
  // ==========================================
  // Agilidad del arquero: menor = más lento (más fácil), mayor = más rápido. Original era 0.075.
  static const double configGoalieAgility = 0.07;

  // Multiplicador de radio de atajada: menor = requiere más precisión del arquero para atajar. Original era 1.15.
  static const double configGoalieSaveRadiusMultiplier = 0.90;

  // Error de predicción en píxeles: a mayor error, el arquero se tira más desviado de la trayectoria real.
  static const double configGoaliePredictionErrorX = 75.0;
  static const double configGoaliePredictionErrorY = 45.0;
  static const double _physicsReferenceFps = 60.0;
  static const double _minShotSpeedFactor = 0.6;
  static const double _maxShotSpeedFactor = 1.8;
  static const double _baseBallDepthVelocity = 0.030 * _physicsReferenceFps;
  static const double _ballGravity =
      0.30 * _physicsReferenceFps * _physicsReferenceFps;

  @override
  Color backgroundColor() => Colors.transparent;

  // HUD y Sesión
  int score = 0;
  int attempts = 0;
  static const int maxAttempts = 5;
  String crowdState = 'idle';
  double crowdCelebrationTimer = 0.0;

  // Feedback
  String displayMessage = '';
  int displayMessageDuration = 0; // en ciclos

  // Arrastre/Tiro
  Offset? swipeStart;
  Offset? swipeCurrent;
  DateTime? swipeStartTime;
  bool isDragging = false;

  // Sprites cargados asíncronamente
  ui.Image? ballSprite;
  ui.Image? goalSprite;
  ui.Image? pitchSprite;
  ui.Image? goalieSprite;
  ui.Image? sippyLogoSprite;
  ui.Picture? _staticStadiumPicture;
  List<ui.Picture>? _celebrationPictures;
  static const int _numCelebrationFrames = 8;

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

    // Configurar Flame para cargar desde la raíz de assets
    images.prefix = 'assets/';
    try {
      ballSprite = await images.load('Pelota.webp');
      goalSprite = await images.load('arco.webp');
      pitchSprite = await images.load('chancha.webp');
      goalieSprite = await images.load('Jugador.webp');
      sippyLogoSprite = await images.load('sippy.png');
    } catch (e) {
      debugPrint('Error cargando sprites: $e');
    }

    resetBall();
    resetGoalie();

    // Play start whistle
    AudioService().playSilbato();
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
    // La altura del portero es logicalHeight * 0.12. Queremos que el centro de su sombra (y + altura*0.55) esté alineado con la línea de gol (goalBottom).
    goalieY = goalBottom - (logicalHeight * 0.12 * 0.55);
    goalieTargetX = logicalWidth / 2;
    goalieTargetY = goalieY;
  }

  void handleSwipeStart(Offset localPosition) {
    if (isKicked || attempts >= maxAttempts) return;
    swipeStart = localPosition;
    swipeCurrent = localPosition;
    swipeStartTime = DateTime.now(); // Registrar marca de tiempo de inicio
    isDragging = true;
  }

  void handleSwipeUpdate(Offset localPosition) {
    if (!isDragging) return;
    swipeCurrent = localPosition;
  }

  void handleSwipeEnd() {
    if (!isDragging ||
        swipeStart == null ||
        swipeCurrent == null ||
        swipeStartTime == null) {
      return;
    }
    isDragging = false;

    final start = swipeStart!;
    final end = swipeCurrent!;
    final vector = end - start;

    // Validar arrastre: distancia mínima y dirección ascendente
    if (vector.distance > 20 && end.dy < start.dy) {
      // Calcular la velocidad real del deslizamiento en píxeles por segundo
      final double elapsedSeconds = max(
        0.05,
        DateTime.now().difference(swipeStartTime!).inMilliseconds / 1000.0,
      );
      final double swipeSpeed = vector.distance / elapsedSeconds;

      // Escalar factor de velocidad (velocidad base de referencia: ~1200 px/seg)
      final double speedFactor = (swipeSpeed / 1200.0).clamp(
        _minShotSpeedFactor,
        _maxShotSpeedFactor,
      );

      // Calcular físicas 2.5D en segundos para que el tiro no dependa del FPS.
      ballVz = _baseBallDepthVelocity * speedFactor;
      final double flightDuration = 1.0 / ballVz;
      final double gravityCompensation =
          0.5 * _ballGravity * flightDuration * flightDuration;

      // Mapear el tiro para que la bola llegue exactamente al punto de liberación (end.dx, end.dy)
      ballVx = vector.dx / flightDuration;
      ballVy = (vector.dy - gravityCompensation) / flightDuration;
      isKicked = true;

      // Simulación de predicción imperfecta del portero con error configurable
      final random = Random();
      final double goalieErrorX =
          (random.nextDouble() * 2 - 1) * configGoaliePredictionErrorX;
      final double goalieErrorY =
          (random.nextDouble() * 2 - 1) * configGoaliePredictionErrorY;

      final double estimatedTargetX = (ballX + vector.dx) + goalieErrorX;
      final double estimatedTargetY = (ballY + vector.dy) + goalieErrorY;

      // Estirada del arquero dirigida a la zona estimada con error
      goalieTargetX = estimatedTargetX.clamp(goalLeft + 15.0, goalRight - 15.0);
      goalieTargetY = estimatedTargetY.clamp(goalTop + 10.0, goalBottom - 10.0);
    }

    swipeStart = null;
    swipeCurrent = null;
    swipeStartTime = null;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Actualizar temporizador de celebración de la hinchada
    if (crowdState == 'celebrating') {
      crowdCelebrationTimer -= dt;
      if (crowdCelebrationTimer <= 0) {
        crowdState = 'idle';
      }
    }

    if (isKicked) {
      final double stepDt = dt.clamp(0.0, 0.3).toDouble();
      final double previousBallX = ballX;
      final double previousBallY = ballY;
      final double previousBallZ = ballZ;

      // Actualizar física del balón (2.5D)
      ballX += ballVx * stepDt;
      ballY += ballVy * stepDt + 0.5 * _ballGravity * stepDt * stepDt;
      ballZ += ballVz * stepDt;
      ballVy += _ballGravity * stepDt;

      // Movimiento del arquero utilizando la agilidad configurada
      final double goalieStep =
          (1 - pow(1 - configGoalieAgility, stepDt * _physicsReferenceFps))
              .toDouble();
      goalieX = goalieX + (goalieTargetX - goalieX) * goalieStep;
      goalieY = goalieY + (goalieTargetY - goalieY) * goalieStep;

      // Evaluar gol o atajada cuando el balón pasa la meta en Z = 1.0
      if (ballZ >= 1.0) {
        final double zDelta = ballZ - previousBallZ;
        if (zDelta > 0) {
          final double hitProgress = ((1.0 - previousBallZ) / zDelta).clamp(
            0.0,
            1.0,
          );
          ballX = previousBallX + (ballX - previousBallX) * hitProgress;
          ballY = previousBallY + (ballY - previousBallY) * hitProgress;
          ballZ = 1.0;
        }

        isKicked = false;
        evaluateShot();
      }
    }
  }

  void evaluateShot() {
    final double gLeft = goalLeft;
    final double gRight = goalRight;
    final double gTop = goalTop;
    final double gBottom = goalBottom;
    final bool isShotInsideGoal =
        ballX > gLeft && ballX < gRight && ballY > gTop && ballY < gBottom;

    // Calcular distancia al arquero
    final goalieWidth = logicalWidth * 0.09;

    final distToGoalie = sqrt(
      pow(ballX - goalieX, 2) + pow(ballY - goalieY, 2),
    );

    // Radio de colisión configurable del portero
    final collisionRadius = goalieWidth * configGoalieSaveRadiusMultiplier;

    if (!isShotInsideGoal) {
      // FUERA
      onMessageTrigger('¡FUERA!');
      AudioService().playFalla();
    } else if (distToGoalie < collisionRadius) {
      // ATAJADA
      onMessageTrigger('¡ATAJADA!');
      AudioService().playFalla();
    } else {
      // GOL
      score++;
      onMessageTrigger('¡GOLAZO!');
      crowdState = 'celebrating';
      crowdCelebrationTimer = 1.4; // 1.4 segundos de saltos y confetti
      AudioService().playAplausos();
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

    // 6. Confetti festivo cayendo por la pantalla en celebración
    if (crowdState == 'celebrating') {
      final confettiRandom = Random(42);
      final double tick = DateTime.now().millisecondsSinceEpoch / 1000.0;
      for (int i = 0; i < 45; i++) {
        final double cx = confettiRandom.nextDouble() * logicalWidth;
        final double cy =
            ((confettiRandom.nextDouble() * logicalHeight) + (tick * 160)) %
            (logicalHeight * 0.7);

        final confettiPaint = Paint()
          ..color = Color.fromARGB(
            255,
            confettiRandom.nextInt(156) + 100,
            confettiRandom.nextInt(156) + 100,
            confettiRandom.nextInt(156) + 100,
          )
          ..style = PaintingStyle.fill;

        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(tick * 3.0 + i);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 6, height: 6),
          confettiPaint,
        );
        canvas.restore();
      }
    }
  }

  void drawStadium(Canvas canvas) {
    if (crowdState != 'celebrating') {
      _staticStadiumPicture ??= _buildStaticStadiumPicture();
      canvas.drawPicture(_staticStadiumPicture!);
      return;
    }

    _buildCelebrationPictures();
    final double tick = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final int frameIndex = ((tick * 12.0) % _numCelebrationFrames).toInt();
    canvas.drawPicture(_celebrationPictures![frameIndex]);
  }

  ui.Picture _buildStaticStadiumPicture() {
    final recorder = ui.PictureRecorder();
    final pictureCanvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, logicalWidth, logicalHeight),
    );
    _drawStadium(pictureCanvas, animateCrowd: false);
    return recorder.endRecording();
  }

  void _buildCelebrationPictures() {
    if (_celebrationPictures != null) return;
    _celebrationPictures = [];
    for (int i = 0; i < _numCelebrationFrames; i++) {
      final recorder = ui.PictureRecorder();
      final pictureCanvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, logicalWidth, logicalHeight),
      );
      final double simulatedTick = i * (2 * pi / _numCelebrationFrames) / 15.0;
      _drawStadium(
        pictureCanvas,
        animateCrowd: true,
        simulatedTick: simulatedTick,
      );
      _celebrationPictures!.add(recorder.endRecording());
    }
  }

  void _drawStadium(
    Canvas canvas, {
    required bool animateCrowd,
    double? simulatedTick,
  }) {
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

    // Dibujar filas de asientos en las gradas y espectadores (público)
    final seatLinePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2;

    final double tick =
        simulatedTick ??
        (animateCrowd ? DateTime.now().millisecondsSinceEpoch / 1000.0 : 0.0);
    final bool isCelebrating = animateCrowd && (crowdState == 'celebrating');

    for (double y = 40.0; y < logicalHeight * 0.4; y += 30.0) {
      canvas.drawLine(Offset(0, y), Offset(logicalWidth, y), seatLinePaint);

      final random = Random(
        y.toInt(),
      ); // Semilla constante para que no parpadee
      for (double x = 15.0; x < logicalWidth; x += 22.0) {
        if (random.nextDouble() > 0.25) {
          // Fase individual basada en la posición
          final double phase = (x * 0.05) + (y * 0.1);

          // Calcular el rebote/salto
          double bounceY = 0.0;
          double swayX = 0.0;
          bool raiseArms = false;

          if (isCelebrating) {
            // Salto vigoroso e individualizado durante la celebración
            bounceY = -12.0 * (sin(tick * 15.0 + phase).abs());
            raiseArms = true;
          } else {
            // Balanceo/respiración pasiva muy sutil
            bounceY = -2.0 * (sin(tick * 2.5 + phase).abs());
            swayX = sin(tick * 1.5 + phase) * 2.0;
          }

          // Posición alineada del espectador (evita distorsión de partes desfasadas)
          final double specX = x + swayX;
          final double specY = y + bounceY;

          // Color de camiseta (Amarillo, Azul, Rojo)
          final double randColor = random.nextDouble();
          Color shirtColor;
          if (randColor < 0.4) {
            shirtColor = const Color(0xFFFFB81C); // Amarillo
          } else if (randColor < 0.7) {
            shirtColor = const Color(0xFF00205B); // Azul
          } else {
            shirtColor = const Color(0xFFE4002B); // Rojo
          }

          final bodyPaint = Paint()..color = shirtColor;
          final headPaint = Paint()
            ..color = const Color(0xFFFFCC80); // Color piel
          final linePaint = Paint()
            ..color = Colors.black.withValues(alpha: 0.1)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;

          // 1. Dibujar brazos si celebra
          if (raiseArms) {
            final armPaint = Paint()
              ..color = const Color(0xFFFFCC80)
              ..strokeWidth = 3.0
              ..strokeCap = StrokeCap.round;
            canvas.drawLine(
              Offset(specX - 4, specY - 6),
              Offset(specX - 8, specY - 14),
              armPaint,
            );
            canvas.drawLine(
              Offset(specX + 4, specY - 6),
              Offset(specX + 8, specY - 14),
              armPaint,
            );
          }

          // 2. Dibujar cuerpo hombros (rectángulo redondeado y firme)
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(specX, specY - 2),
                width: 14,
                height: 10,
              ),
              const Radius.circular(3),
            ),
            bodyPaint,
          );

          // 3. Dibujar cabeza (círculo)
          canvas.drawCircle(Offset(specX, specY - 10), 4.5, headPaint);
          canvas.drawCircle(Offset(specX, specY - 10), 4.5, linePaint);

          // 4. Dibujar gorra/pelo simplificado
          final detailPaint = Paint();
          if (random.nextDouble() > 0.5) {
            detailPaint.color = const Color(0xFF1E293B); // Pelo oscuro
            canvas.drawArc(
              Rect.fromCenter(
                center: Offset(specX, specY - 11.5),
                width: 9,
                height: 6,
              ),
              pi,
              pi,
              true,
              detailPaint,
            );
          } else {
            detailPaint.color = const Color(0xFFE4002B); // Gorra roja
            canvas.drawArc(
              Rect.fromCenter(
                center: Offset(specX, specY - 11.5),
                width: 9,
                height: 6,
              ),
              pi,
              pi,
              true,
              detailPaint,
            );
            final capPaint = Paint()
              ..color = const Color(0xFFE4002B)
              ..strokeWidth = 1.5;
            canvas.drawLine(
              Offset(specX - 4, specY - 11),
              Offset(specX + 2, specY - 11),
              capPaint,
            );
          }

          // 5. Pequeñas banderas que se agitan en celebración
          if (isCelebrating && random.nextDouble() > 0.85) {
            final flagPolePaint = Paint()
              ..color = Colors.brown[300]!
              ..strokeWidth = 1.5;
            final flagY = specY - 16;
            final flagX = specX + 10;
            canvas.drawLine(
              Offset(specX + 2, specY - 4),
              Offset(flagX, flagY),
              flagPolePaint,
            );

            final yellowPaint = Paint()..color = const Color(0xFFFFB81C);
            final bluePaint = Paint()..color = const Color(0xFF00205B);
            final redPaint = Paint()..color = const Color(0xFFE4002B);

            canvas.drawRect(Rect.fromLTWH(flagX, flagY, 8, 2), yellowPaint);
            canvas.drawRect(Rect.fromLTWH(flagX, flagY + 2, 8, 2), bluePaint);
            canvas.drawRect(Rect.fromLTWH(flagX, flagY + 4, 8, 2), redPaint);
          }
        }
      }
    }

    final standsBndPaint = Paint()..color = const Color(0xFFCBD5E1);
    final pathStands = Path()
      ..moveTo(0, logicalHeight * 0.4)
      ..lineTo(logicalWidth, logicalHeight * 0.4)
      ..lineTo(logicalWidth, logicalHeight * 0.42)
      ..lineTo(0, logicalHeight * 0.42)
      ..close();
    canvas.drawPath(pathStands, standsBndPaint);

    // Definición de la valla publicitaria centrada DETRÁS del arco
    // (dentro del ancho de los postes, visible a través de la malla de la red).
    final Rect billboardRect = this.billboardRect;

    // Dibujar billboard publicitario directamente en el Canvas
    _drawCanvasBillboard(canvas, billboardRect);

    // Césped (Cancha)
    if (pitchSprite != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTRB(
          0,
          logicalHeight * _pitchFieldTop,
          logicalWidth,
          logicalHeight,
        ),
        image: pitchSprite!,
        fit: BoxFit.fill,
      );
    } else {
      final fieldPaint = Paint()..color = const Color(0xFF4CAF50);
      final pathField = Path()
        ..moveTo(0, logicalHeight * _pitchFieldTop)
        ..lineTo(logicalWidth, logicalHeight * _pitchFieldTop)
        ..lineTo(logicalWidth, logicalHeight)
        ..lineTo(0, logicalHeight)
        ..close();
      canvas.drawPath(pathField, fieldPaint);

      // Líneas blancas del área (Solo si no hay sprite de cancha)
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final pathArea = Path()
        ..moveTo(logicalWidth * 0.05, logicalHeight)
        ..lineTo(logicalWidth * 0.2, logicalHeight * _pitchFieldTop)
        ..lineTo(logicalWidth * 0.8, logicalHeight * _pitchFieldTop)
        ..lineTo(logicalWidth * 0.95, logicalHeight);
      canvas.drawPath(pathArea, linePaint);

      // Punto Penal (Solo si no hay sprite de cancha)
      final penaltyPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(logicalWidth / 2, logicalHeight * 0.82),
          width: 15,
          height: 7,
        ),
        penaltyPaint,
      );
    }
  }

  void drawGoalPost(Canvas canvas) {
    final double gLeft = goalLeft;
    final double gRight = goalRight;
    final double gTop = goalTop;
    final double gBottom = goalBottom;

    if (goalSprite != null) {
      final double widthRatio = goalSprite!.width / 1920.0;
      final double heightRatio = goalSprite!.height / 1080.0;
      final Rect sourceRect = Rect.fromLTRB(
        _goalSpriteSourceLeft * widthRatio,
        _goalSpriteSourceTop * heightRatio,
        _goalSpriteSourceRight * widthRatio,
        _goalSpriteSourceBottom * heightRatio,
      );
      canvas.drawImageRect(
        goalSprite!,
        sourceRect,
        _goalSpriteRect,
        Paint()..filterQuality = FilterQuality.medium,
      );
    } else {
      // Red de portería
      final netPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 1.5;

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
  }

  void drawGoalieWidget(Canvas canvas) {
    final double goalieWidth = logicalWidth * 0.09;
    final double goalieHeight = logicalHeight * 0.12;

    canvas.save();
    canvas.translate(goalieX, goalieY);

    // Sombra del portero
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, goalieHeight * 0.55),
        width: goalieWidth * 1.5,
        height: goalieHeight * 0.25,
      ),
      shadowPaint,
    );

    if (goalieSprite != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromCenter(
          center: Offset.zero,
          width: goalieWidth * 3.0,
          height: goalieHeight * 1.1,
        ),
        image: goalieSprite!,
        fit: BoxFit.contain,
      );
    } else {
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
    }

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
      ..color = Colors.black.withValues(alpha: shadowOpacity);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, radius + shadowOffset),
        width: radius * 1.8,
        height: radius * 0.4,
      ),
      shadowPaint,
    );

    if (ballSprite != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromCenter(
          center: Offset.zero,
          width:
              radius *
              2.8, // Escalar ligeramente mayor para cubrir el area de colisión visual
          height: radius * 2.8,
        ),
        image: ballSprite!,
        fit: BoxFit.contain,
      );
    } else {
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
    }

    canvas.restore();
  }

  void _drawCanvasBillboard(Canvas canvas, Rect rect) {
    // 1. Fondo de valla con gradiente Navy elegante de Banco del Austro
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [const Color(0xFF00205B), const Color(0xFF001030)],
      );
    canvas.drawRect(rect, bgPaint);

    // 2. Dibujar franjas decorativas sutiles en los extremos
    final stripePaint = Paint()..color = const Color(0xFFE4002B); // Rojo BDA
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, 8, rect.height),
      stripePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 8, rect.top, 8, rect.height),
      stripePaint,
    );

    // Guardar capa para recortar brillo y logo dentro de la valla
    canvas.save();
    canvas.clipRect(rect);

    // 3. Dibujar el logo de Sippy en el centro si está cargado
    if (sippyLogoSprite != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromCenter(
          center: rect.center,
          width: rect.width * 0.35,
          height: rect.height * 0.75,
        ),
        image: sippyLogoSprite!,
        fit: BoxFit.contain,
      );
    } else {
      // Fallback a texto si por alguna razón no se carga el logo
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'BANCO DEL AUSTRO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textOffset = Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, textOffset);
    }

    // 4. Brillo metálico animado (Sheen Effect) sobre el fondo y el logo
    final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final double sheenPosition = (time * 150.0) % (rect.width * 2) - rect.width;

    final sheenPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect.left + sheenPosition, rect.top),
        Offset(rect.left + sheenPosition + 120, rect.top),
        [
          Colors.transparent,
          const Color(0xFFFFB81C).withValues(alpha: 0.15), // Oro suave
          const Color(0xFFFFFFFF).withValues(alpha: 0.35), // Blanco de brillo
          const Color(0xFFFFB81C).withValues(alpha: 0.15),
          Colors.transparent,
        ],
        [0.0, 0.35, 0.5, 0.65, 1.0],
      );
    canvas.drawRect(rect, sheenPaint);
    canvas.restore();

    // 5. Borde Dorado
    final borderPaint = Paint()
      ..color = const Color(0xFFFFB81C) // Oro
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);
  }
}
