import 'package:flutter_test/flutter_test.dart';
import 'package:doubao_speech/doubao_speech.dart';
import 'package:doubao_speech/doubao_speech_platform_interface.dart';
import 'package:doubao_speech/doubao_speech_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDoubaoSpeechPlatform
    with MockPlatformInterfaceMixin
    implements DoubaoSpeechPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DoubaoSpeechPlatform initialPlatform = DoubaoSpeechPlatform.instance;

  test('$MethodChannelDoubaoSpeech is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDoubaoSpeech>());
  });

  test('getPlatformVersion', () async {
    DoubaoSpeech doubaoSpeechPlugin = DoubaoSpeech();
    MockDoubaoSpeechPlatform fakePlatform = MockDoubaoSpeechPlatform();
    DoubaoSpeechPlatform.instance = fakePlatform;

    expect(await doubaoSpeechPlugin.getPlatformVersion(), '42');
  });
}
