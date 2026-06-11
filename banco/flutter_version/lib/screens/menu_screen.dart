import 'package:flutter/material.dart';

import '../models/player_lead.dart';
import '../theme/bda_theme.dart';

class MenuScreen extends StatelessWidget {
  final PlayerLead? player;
  final Function(String) onSelectGame;
  final VoidCallback onRestartSession;

  const MenuScreen({
    super.key,
    required this.player,
    required this.onSelectGame,
    required this.onRestartSession,
  });

  @override
  Widget build(BuildContext context) {
    final playerName =
        '${player?.firstName ?? "Invitado"} ${player?.lastName ?? ""}'.trim();

    return Container(
      color: BdaColors.sipyOptionsBackground,
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: BdaColors.sipyOptionGreen.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: BdaColors.sipyBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  height: 72,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: BdaColors.sipyBackground,
                    border: Border(
                      bottom: BorderSide(
                        color: BdaColors.sipyInputBorder.withValues(alpha: 0.3),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
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
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPlayerCard(playerName),
                        const SizedBox(height: 56),
                        const Text(
                          'SELECCIONA TU DESAFÍO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: BdaFonts.gotham,
                            fontSize: 33,
                            fontWeight: FontWeight.w800,
                            color: BdaColors.sipyBlue,
                            letterSpacing: 0.2,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Demuestra tus habilidades frente a\ntoda la hinchada',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: BdaFonts.gotham,
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: BdaColors.sipyBodyText,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 50),
                        _buildGameCard(
                          title: 'PENALES DE ORO',
                          description:
                              'Arrastra el dedo para patear el balón, esquiva la estirada del arquero y anota todos los goles que puedas.',
                          icon: Icons.sports_soccer,
                          onTap: () => onSelectGame('penalty'),
                        ),
                        const SizedBox(height: 32),
                        _buildGameCard(
                          title: 'TRIVIA MUNDIALISTA',
                          description:
                              'Demuestra tus conocimientos sobre la Selección respondiendo 10 preguntas lo más rápido posible.',
                          icon: Icons.quiz_outlined,
                          onTap: () => onSelectGame('trivia'),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 42),
                          child: TextButton.icon(
                            onPressed: onRestartSession,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: BdaColors.sipyBlue,
                              size: 24,
                            ),
                            label: const Text(
                              'REGISTRAR OTRO JUGADOR',
                              style: TextStyle(
                                fontFamily: BdaFonts.gotham,
                                color: BdaColors.sipyBlue,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String playerName) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BdaColors.sipyInputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: BdaColors.sipyBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JUGADOR ACTIVO',
                  style: TextStyle(
                    fontFamily: BdaFonts.gotham,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: BdaColors.sipyBodyText,
                    letterSpacing: 2.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  playerName.isEmpty ? 'Invitado' : playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: BdaFonts.gotham,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BdaColors.sipyBlue,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BdaColors.sipyBlue, width: 2.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: BdaColors.sipyOptionGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BdaColors.sipyShadowBlue.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: -3,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: BdaColors.sipyShadowBlue.withValues(alpha: 0.2),
                    blurRadius: 6,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: BdaColors.sipyBlue, size: 34),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: BdaFonts.gotham,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: BdaColors.sipyDarkText,
                      letterSpacing: 0.4,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: BdaFonts.gotham,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: BdaColors.sipyDarkText,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
