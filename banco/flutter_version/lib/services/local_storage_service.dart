import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_lead.dart';

class LocalStorageService {
  static const String _leadsKey = 'austro_offline_leads';
  static const String _leaderboardKey = 'austro_leaderboard';

  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    await _initDefaultLeaderboard();
  }

  // Pre-cargar la tabla con datos ficticios iniciales si no existen
  Future<void> _initDefaultLeaderboard() async {
    if (!_prefs.containsKey(_leaderboardKey)) {
      final defaultLeaderboard = {
        'penalty': [
          {'firstName': 'Marcelo', 'lastName': 'E.', 'score': 5},
          {'firstName': 'Andrés', 'lastName': 'C.', 'score': 4},
          {'firstName': 'Esteban', 'lastName': 'M.', 'score': 4},
          {'firstName': 'Santiago', 'lastName': 'V.', 'score': 3},
          {'firstName': 'Xavier', 'lastName': 'A.', 'score': 3},
          {'firstName': 'Cristian', 'lastName': 'P.', 'score': 2}
        ],
        'keepie': [
          {'firstName': 'Gabriela', 'lastName': 'T.', 'score': 18},
          {'firstName': 'Carlos', 'lastName': 'Z.', 'score': 15},
          {'firstName': 'Esteban', 'lastName': 'M.', 'score': 12},
          {'firstName': 'Andrés', 'lastName': 'C.', 'score': 11},
          {'firstName': 'Luis', 'lastName': 'G.', 'score': 8},
          {'firstName': 'Paola', 'lastName': 'R.', 'score': 5}
        ],
        'reflex': [
          {'firstName': 'Diego', 'lastName': 'S.', 'score': 25},
          {'firstName': 'Andrés', 'lastName': 'C.', 'score': 22},
          {'firstName': 'Esteban', 'lastName': 'M.', 'score': 20},
          {'firstName': 'Daniela', 'lastName': 'V.', 'score': 18},
          {'firstName': 'Juan', 'lastName': 'P.', 'score': 15},
          {'firstName': 'Maria', 'lastName': 'L.', 'score': 12}
        ]
      };
      await _prefs.setString(_leaderboardKey, jsonEncode(defaultLeaderboard));
    }
  }

  // Obtener leads locales guardados (offline)
  List<PlayerLead> getOfflineLeads() {
    final rawLeads = _prefs.getString(_leadsKey);
    if (rawLeads == null) return [];
    try {
      final decoded = jsonDecode(rawLeads) as List;
      return decoded.map((e) => PlayerLead.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Guardar un lead localmente
  Future<void> saveLead(PlayerLead lead) async {
    final leads = getOfflineLeads();
    leads.add(lead);
    final serialized = jsonEncode(leads.map((e) => e.toJson()).toList());
    await _prefs.setString(_leadsKey, serialized);
  }

  // Obtener leaderboard por tipo de juego
  List<Map<String, dynamic>> getLeaderboard(String gameType) {
    final rawLeaderboard = _prefs.getString(_leaderboardKey);
    if (rawLeaderboard == null) return [];
    try {
      final decoded = jsonDecode(rawLeaderboard) as Map<String, dynamic>;
      final gameLeaderboard = decoded[gameType] as List;
      return gameLeaderboard.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  // Registrar un puntaje
  Future<void> registerScore({
    required String firstName,
    required String lastName,
    required int score,
    required String gameType,
  }) async {
    final rawLeaderboard = _prefs.getString(_leaderboardKey);
    if (rawLeaderboard == null) return;
    try {
      final decoded = jsonDecode(rawLeaderboard) as Map<String, dynamic>;
      final gameLeaderboard = decoded[gameType] as List;
      
      // Agregar el nuevo record
      gameLeaderboard.add({
        'firstName': firstName,
        'lastName': lastName.isNotEmpty ? '${lastName[0]}.' : '',
        'score': score
      });

      // Ordenar descendente por puntuación
      gameLeaderboard.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      // Guardar de vuelta
      decoded[gameType] = gameLeaderboard;
      await _prefs.setString(_leaderboardKey, jsonEncode(decoded));
    } catch (e) {
      // Ignorar o registrar error
    }
  }
}
