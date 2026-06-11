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
      color: BdaColors.sipyBackground,
      child: SafeArea(
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: BdaColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: const Border(
                        top: BorderSide(
                          color: BdaColors.sipyOptionGreen,
                          width: 6,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: BdaColors.sipyShadowBlue.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 40,
                          spreadRadius: -10,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            color: BdaColors.sipyBlue,
                            strokeWidth: 5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'GUARDANDO RESULTADO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: BdaFonts.gotham,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: BdaColors.sipyBlue,
                            letterSpacing: -0.6,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _gameLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: BdaFonts.gotham,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: BdaColors.sipyDarkText,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Estamos registrando tu puntaje...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: BdaFonts.gotham,
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: BdaColors.sipyBodyText.withValues(
                              alpha: 0.8,
                            ),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
