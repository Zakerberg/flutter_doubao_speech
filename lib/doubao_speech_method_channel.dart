import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'doubao_speech_platform_interface.dart';

/// An implementation of [DoubaoSpeechPlatform] that uses method channels.
class MethodChannelDoubaoSpeech extends DoubaoSpeechPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('doubao_speech');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
