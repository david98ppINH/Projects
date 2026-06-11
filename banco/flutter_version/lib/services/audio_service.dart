import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playAplausos() async {
    await _play('audio/Aplausos.wav');
  }

  Future<void> playFalla() async {
    await _play('audio/Falla.wav');
  }

  Future<void> playSilbato() async {
    await _play('audio/silbato.wav');
  }

  Future<void> _play(String assetPath) async {
    try {
      // In audioplayers 6.x, we stop and play the AssetSource.
      // Stop is called first to reset the player in case another sound is playing.
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      if (kDebugMode) {
        print('AudioService error playing $assetPath: $e');
      }
    }
  }
}
