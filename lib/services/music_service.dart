import 'package:audioplayers/audioplayers.dart';

class MusicService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> playBackgroundMusic() async {
    if (_isPlaying) return;
    
    try {
      // Set to loop
      await _player.setReleaseMode(ReleaseMode.loop);
      // Play the background music from assets
      await _player.play(AssetSource('music/music_bg.mp3'));
      _isPlaying = true;
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  static Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  static Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }
}
