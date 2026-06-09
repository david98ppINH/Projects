import 'package:flutter/material.dart';
import 'package:flutter_version/theme/bda_theme.dart';

class SavingScoreScreen extends StatelessWidget {
  final String gameType;

  const SavingScoreScreen({super.key, required this.gameType});

  String get _gameLabel {
    switch (gameType) {
      case 'trivia':
        return 'TRIVIA MUNDIALISTA';
      case 'penalty':
        return 'PENALES DE ORO';
      default:
        return 'TU JUEGO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [BdaColors.lightBackground, BdaColors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
              decoration: BoxDecoration(
                color: BdaColors.white,
                borderRadius: BorderRadius.circular(20),
                border: const Border(
                  top: BorderSide(color: BdaColors.gold, width: 6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: BdaColors.navy.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: BdaColors.red,
                      strokeWidth: 5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'GUARDANDO RESULTADO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: BdaColors.navy,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _gameLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: BdaColors.red,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estamos registrando tu puntaje...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
