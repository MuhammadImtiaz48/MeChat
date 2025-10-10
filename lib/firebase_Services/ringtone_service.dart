import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class RingtoneService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> playRingtone() async {
    if (_isPlaying) {
      if (kDebugMode) {
        debugPrint('🔔 RingtoneService: Ringtone already playing, skipping');
      }
      return;
    }
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/ringtone.mp3'));
      _isPlaying = true;
      if (kDebugMode) {
        debugPrint('✅ RingtoneService: Playing ringtone');
      }
      Future.delayed(const Duration(seconds: 30), () {
        if (_isPlaying) {
          stopRingtone();
        }
      });
    } catch (e) {
      _isPlaying = false;
      if (kDebugMode) {
        debugPrint('⚠️ RingtoneService: Error playing ringtone: $e');
      }
    }
  }

  static Future<void> stopRingtone() async {
    if (!_isPlaying) {
      if (kDebugMode) {
        debugPrint('🔔 RingtoneService: Ringtone not playing, skipping stop');
      }
      return;
    }
    try {
      await _player.stop();
      _isPlaying = false;
      if (kDebugMode) {
        debugPrint('✅ RingtoneService: Stopped ringtone');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ RingtoneService: Error stopping ringtone: $e');
      }
    }
  }
}