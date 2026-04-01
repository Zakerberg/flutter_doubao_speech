import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'doubao_speech_method_channel.dart';

abstract class DoubaoSpeechPlatform extends PlatformInterface {
  /// Constructs a DoubaoSpeechPlatform.
  DoubaoSpeechPlatform() : super(token: _token);

  static final Object _token = Object();

  static DoubaoSpeechPlatform _instance = MethodChannelDoubaoSpeech();

  /// The default instance of [DoubaoSpeechPlatform] to use.
  ///
  /// Defaults to [MethodChannelDoubaoSpeech].
  static DoubaoSpeechPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DoubaoSpeechPlatform] when
  /// they register themselves.
  static set instance(DoubaoSpeechPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
