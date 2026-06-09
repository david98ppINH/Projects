import 'package:flutter/material.dart';
import '../models/player_lead.dart';
import '../services/local_storage_service.dart';
import '../theme/bda_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  final String gameType;
  final PlayerLead? currentPlayer;
  final VoidCallback onRestartSession;
  final VoidCallback onChangeGame;

  const LeaderboardScreen({
    super.key,
    required this.gameType,
    required this.currentPlayer,
    required this.onRestartSession,
    required this.onChangeGame,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });

    // Pequeño retardo simulado para dar efecto premium de carga
    await Future.delayed(const Duration(milliseconds: 500));

    final records = LocalStorageService().getLeaderboard(widget.gameType);

    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
  }

  String _formatTime(dynamic timeMs) {
    if (timeMs == null) return '-';
    final ms = timeMs as int;
    final sec = ms ~/ 1000;
    final fractions = (ms % 1000) ~/ 10;
    return '$sec.${fractions.toString().padLeft(2, '0')}s';
  }

  String _getGameTitle() {
    switch (widget.gameType) {
      case 'penalty':
        return 'LÍDERES DE PENALES';
      case 'keepie':
        return 'LÍDERES DE DOMINADAS';
      case 'trivia':
        return 'LÍDERES DE TRIVIA';
      default:
        return 'TABLA DE POSICIONES';
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Copa Icono Animado
              const Center(
                child: Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: BdaColors.gold,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                _getGameTitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: BdaColors.navy,
                  letterSpacing: 1.5,
                ),
              ),
              const Text(
                'Los mejores goleadores del Fan Fest',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              // Tabla de Posiciones
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: BdaColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: BdaColors.lightGrey),
                    boxShadow: [
                      BoxShadow(
                        color: BdaColors.navy.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: BdaColors.red,
                            ),
                          )
                        : _records.isEmpty
                        ? const Center(
                            child: Text(
                              'Sin récords aún. ¡Sé el primero!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              // Encabezados de tabla
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                color: BdaColors.lightBackground,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        'POS',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: BdaColors.navy,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'JUGADOR',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: BdaColors.navy,
                                        ),
                                      ),
                                    ),
                                    if (widget.gameType == 'trivia')
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          'TIEMPO',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: BdaColors.navy,
                                          ),
                                        ),
                                      ),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        'RECORD',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: BdaColors.navy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Filas del Leaderboard
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _records.length > 8
                                      ? 8
                                      : _records.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                        height: 1,
                                        color: BdaColors.lightGrey,
                                      ),
                                  itemBuilder: (context, index) {
                                    final record = _records[index];
                                    final isTop3 = index < 3;
                                    final isCurrentPlayer =
                                        widget.currentPlayer != null &&
                                        record['firstName'] ==
                                            widget.currentPlayer!.firstName &&
                                        record['score'] ==
                                            widget.currentPlayer!.score;

                                    // Icono de medalla
                                    String medal = '';
                                    if (index == 0) medal = '🏆';
                                    if (index == 1) medal = '🥈';
                                    if (index == 2) medal = '🥉';

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      color: isCurrentPlayer
                                          ? BdaColors.gold.withValues(alpha: 0.15)
                                          : (isTop3
                                                ? BdaColors.navy.withValues(
                                                    alpha: 0.02,
                                                  )
                                                : null),
                                      child: Row(
                                        children: [
                                          // Posición
                                          SizedBox(
                                            width: 50,
                                            child: Text(
                                              medal.isNotEmpty
                                                  ? medal
                                                  : '${index + 1}',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: isTop3
                                                    ? BdaColors.red
                                                    : BdaColors.navy,
                                              ),
                                            ),
                                          ),

                                          // Jugador
                                          Expanded(
                                            child: Text(
                                              '${record['firstName']} ${record['lastName']}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    isCurrentPlayer || isTop3
                                                    ? FontWeight.w800
                                                    : FontWeight.bold,
                                                color: BdaColors.navy,
                                              ),
                                            ),
                                          ),

                                          if (widget.gameType == 'trivia')
                                            SizedBox(
                                              width: 70,
                                              child: Text(
                                                _formatTime(record['timeElapsed']),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: BdaColors.navy,
                                                ),
                                              ),
                                            ),

                                          // Record
                                          SizedBox(
                                            width: 70,
                                            child: Text(
                                              '${record['score']}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: BdaColors.navy,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botones Inferiores Ergonómicos en el tercio inferior
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: BdaColors.navyGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: BdaColors.navy.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: widget.onChangeGame,
                        icon: const Icon(
                          Icons.gamepad,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'CAMBIAR JUEGO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: BdaColors.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: BdaColors.gold.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: widget.onRestartSession,
                        icon: const Icon(
                          Icons.refresh,
                          color: BdaColors.navy,
                          size: 20,
                        ),
                        label: const Text(
                          'SIGUIENTE TURNO',
                          style: TextStyle(
                            color: BdaColors.navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
