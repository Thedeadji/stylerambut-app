import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import 'settings_store.dart';

class ScanFeedbackService {
  ScanFeedbackService._();

  static final ScanFeedbackService instance = ScanFeedbackService._();

  static const _beepAsset = 'sound/pixabay_ring1.mp3';

  final AudioPlayer _player = AudioPlayer();

  Future<void> playScanCompleteFeedback() async {
    final settings = SettingsStore.instance;
    final futures = <Future<void>>[];

    if (settings.vibrationEnabled) {
      futures.add(_vibrate());
    }
    if (settings.beepEnabled) {
      futures.add(_playBeep());
    }

    await Future.wait(futures);
  }

  Future<void> _vibrate() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) return;

    final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
    if (hasAmplitudeControl) {
      await Vibration.vibrate(duration: 400, amplitude: 128);
    } else {
      await Vibration.vibrate(duration: 400);
    }
  }

  Future<void> _playBeep() async {
    await _player.stop();
    await _player.play(AssetSource(_beepAsset));
  }

  void dispose() {
    _player.dispose();
  }
}
