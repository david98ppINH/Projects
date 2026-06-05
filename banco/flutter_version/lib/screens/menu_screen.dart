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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [BdaColors.lightBackground, BdaColors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),

              // Información del jugador registrado
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: BdaColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BdaColors.lightGrey),
                  boxShadow: [
                    BoxShadow(
                      color: BdaColors.navy.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: BdaColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: BdaColors.gold,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'JUGADOR ACTIVO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${player?.firstName ?? "Invitado"} ${player?.lastName ?? ""}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BdaColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              const Text(
                'SELECCIONA TU DESAFÍO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: BdaColors.navy,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Demuestra tus habilidades frente a toda la hinchada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // Lista de juegos
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Juego 1: Penales de Oro (ACTIVO)
                    _buildGameCard(
                      context,
                      title: 'PENALES DE ORO',
                      description:
                          'Arrastra el dedo para patear el balón, esquiva la estirada del arquero y anota todos los goles que puedas.',
                      icon: Icons.sports_soccer,
                      color: BdaColors.red,
                      isActive: true,
                      onTap: () => onSelectGame('penalty'),
                    ),
                    const SizedBox(height: 20),

                    // Juego 2: Dominadas Tricolor (BLOQUEADO/DEMO)
                    /*  _buildGameCard(
                      context,
                      title: 'DOMINADAS TRICOLOR',
                      description: 'Toca repetidamente el balón antes de que toque el césped para mantenerlo en el aire y sumar puntos.',
                      icon: Icons.sports_soccer,
                      color: BdaColors.gold,
                      isActive: false,
                      tagText: 'PRÓXIMAMENTE',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20), */

                    // Juego 3: Reflejos de Arco (ACTIVO)
                    _buildGameCard(
                      context,
                      title: 'REFLEJOS DE ARCO',
                      description:
                          'Toca rápidamente los logos del Austro que se iluminan antes de que se agote el tiempo.',
                      icon: Icons.bolt,
                      color: BdaColors.navy,
                      isActive: true,
                      onTap: () => onSelectGame('reflex'),
                    ),
                  ],
                ),
              ),

              // Botón inferior para registrar a otro jugador
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
                child: TextButton.icon(
                  onPressed: onRestartSession,
                  icon: const Icon(Icons.arrow_back, color: BdaColors.red),
                  label: const Text(
                    'REGISTRAR OTRO JUGADOR',
                    style: TextStyle(
                      color: BdaColors.red,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isActive,
    String? tagText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BdaColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? color.withOpacity(0.5) : BdaColors.lightGrey,
              width: isActive ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isActive ? 0.08 : 0.02),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono con fondo circular
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              // Contenido de texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: BdaColors.navy,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (tagText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: BdaColors.lightGrey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tagText,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
