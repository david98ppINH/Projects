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

  bool get _isTrivia => widget.gameType == 'trivia';

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });

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

  String _getSubtitle() {
    return _isTrivia
        ? 'Los mejores goleadores del Fan Fest'
        : 'Los mejores goleadores del Fan Fest';
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecords = _records.take(7).toList();

    return Container(
      color: BdaColors.sipyOptionsBackground,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: BdaColors.sipyOptionGreen,
                      size: 66,
                    ),
                    const SizedBox(height: 48),
                    Text(
                      _getGameTitle(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: BdaFonts.gotham,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: BdaColors.sipyDarkText,
                        letterSpacing: -0.8,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _getSubtitle(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: BdaFonts.gotham,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: BdaColors.sipyBodyText,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Expanded(child: _buildLeaderboardCard(visibleRecords)),
                    const SizedBox(height: 44),
                    _buildBottomActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard(List<Map<String, dynamic>> records) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BdaColors.sipyInputBorder.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 50,
            spreadRadius: -12,
            offset: const Offset(0, 25),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: BdaColors.sipyBlue),
              )
            : records.isEmpty
            ? const Center(
                child: Text(
                  'Sin récords aún. ¡Sé el primero!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: BdaFonts.gotham,
                    color: BdaColors.sipyBodyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Column(
                children: [
                  _buildTableHeader(),
                  Expanded(
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        return _buildLeaderboardRow(records[index], index);
                      },
                    ),
                  ),
                  Container(height: 32, color: const Color(0xFFF0EDF0)),
                ],
              ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: BdaColors.sipyBlue,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildHeaderCell('POS', width: 48, textAlign: TextAlign.center),
          _buildHeaderCell('JUGADOR', flex: 1),
          if (_isTrivia)
            _buildHeaderCell('TIEMPO', width: 96, textAlign: TextAlign.right),
          _buildHeaderCell('RECORD', width: 82, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String text, {
    double? width,
    int? flex,
    TextAlign textAlign = TextAlign.left,
  }) {
    final child = Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: BdaFonts.gotham,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.7),
        letterSpacing: 1.2,
        height: 1.2,
      ),
    );

    if (flex != null) return Expanded(flex: flex, child: child);
    return SizedBox(width: width, child: child);
  }

  Widget _buildLeaderboardRow(Map<String, dynamic> record, int index) {
    final isCurrentPlayer = _isCurrentPlayer(record);
    final fullName = '${record['firstName']} ${record['lastName'] ?? ''}'
        .trim();
    final rowColor = isCurrentPlayer
        ? BdaColors.sipyOptionGreen.withValues(alpha: 0.1)
        : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          bottom: BorderSide(
            color: BdaColors.sipyInputBorder.withValues(alpha: 0.1),
          ),
          left: isCurrentPlayer
              ? const BorderSide(color: BdaColors.sipyOptionGreen, width: 5)
              : BorderSide.none,
        ),
      ),
      padding: EdgeInsets.fromLTRB(isCurrentPlayer ? 23 : 24, 16, 24, 17),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Center(child: _buildPosition(index, isCurrentPlayer)),
          ),
          Expanded(
            child: Text(
              fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: BdaFonts.gotham,
                fontSize: 23,
                fontStyle: isCurrentPlayer
                    ? FontStyle.italic
                    : FontStyle.normal,
                fontWeight: FontWeight.w900,
                color: BdaColors.sipyBlue,
                height: 1.25,
              ),
            ),
          ),
          if (_isTrivia)
            SizedBox(
              width: 96,
              child: Text(
                _formatTime(record['timeElapsed']),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: BdaFonts.gotham,
                  fontSize: 18,
                  fontWeight: isCurrentPlayer
                      ? FontWeight.w800
                      : FontWeight.w400,
                  color: isCurrentPlayer
                      ? BdaColors.sipyBlue
                      : BdaColors.sipyBodyText,
                  height: 1.2,
                ),
              ),
            ),
          SizedBox(
            width: 82,
            child: Text(
              '${record['score']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: BdaFonts.gotham,
                fontSize: 25,
                fontWeight: isCurrentPlayer ? FontWeight.w900 : FontWeight.w800,
                color: BdaColors.sipyDarkText,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosition(int index, bool isCurrentPlayer) {
    if (index == 0) {
      return const Icon(
        Icons.emoji_events,
        color: BdaColors.sipyOptionGreen,
        size: 22,
      );
    }
    if (index == 1) {
      return const Icon(
        Icons.workspace_premium,
        color: Color(0xFFB9B9C4),
        size: 24,
      );
    }
    if (index == 2) {
      return const Icon(
        Icons.workspace_premium,
        color: Color(0xFFFFB260),
        size: 24,
      );
    }

    return Text(
      '${index + 1}',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: BdaFonts.gotham,
        fontSize: 23,
        fontWeight: FontWeight.w800,
        color: isCurrentPlayer
            ? BdaColors.sipyOptionGreen
            : BdaColors.sipyBodyText.withValues(alpha: 0.5),
        height: 1.1,
      ),
    );
  }

  bool _isCurrentPlayer(Map<String, dynamic> record) {
    final player = widget.currentPlayer;
    if (player == null) return false;
    return record['firstName'] == player.firstName &&
        record['score'] == player.score;
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'CAMBIAR JUEGO',
            icon: Icons.videogame_asset_outlined,
            backgroundColor: BdaColors.sipyOptionGreen,
            foregroundColor: Colors.black,
            onPressed: widget.onChangeGame,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            label: 'SIGUIENTE TURNO',
            icon: Icons.refresh,
            backgroundColor: BdaColors.sipyBlue,
            foregroundColor: Colors.white,
            onPressed: widget.onRestartSession,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 64,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: foregroundColor, size: 18),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: BdaFonts.gotham,
            color: foregroundColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
