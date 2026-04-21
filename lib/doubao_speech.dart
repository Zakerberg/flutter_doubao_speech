import 'dart:async';
import 'dart:convert';
import 'package:doubao_speech/doubao_speech_event.dart';
import 'package:flutter/services.dart';

/// Doubao Speech Plugin
class DoubaoSpeech {
  static const MethodChannel _methodChannel =
      MethodChannel('doubao_speech/methods');
  static const EventChannel _eventChannel =
      EventChannel('doubao_speech/events');

  static StreamController<SpeechEvent>? _eventController;
  static StreamSubscription<dynamic>? _eventSubscription;
  static bool _initialized = false;

  /// Initialize the plugin and set up event stream
  static Future<void> init() async {
    if (_initialized) return;

    _eventController = StreamController<SpeechEvent>.broadcast();

    _eventSubscription =
        _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      final map = Map<String, dynamic>.from(event);
      final type = map['type'] as String;

      switch (type) {
        case 'engine_start':
          _eventController?.add(SpeechEvent.engineStart(map['data']));
          break;
        case 'engine_stop':
          _eventController?.add(SpeechEvent.engineStop(map['data']));
          break;
        case 'engine_error':
          _eventController?.add(SpeechEvent.engineError(map['data']));
          break;
        case 'asr_start':
          _eventController?.add(SpeechEvent.asrStart());
          break;
        case 'asr_result':
          _eventController?.add(SpeechEvent.asrResult(map['data']));
          break;
        case 'asr_end':
          _eventController?.add(SpeechEvent.asrEnd());
          break;
        case 'chat_result':
          _eventController?.add(SpeechEvent.chatResult(map['data']));
          break;
        case 'chat_end':
          _eventController?.add(SpeechEvent.chatEnd());
          break;
        case 'player_audio':
          final audioBase64 = map['audio'] as String;
          final audioBytes = base64Decode(audioBase64);
          _eventController?.add(SpeechEvent.playerAudio(audioBytes));
          break;
        case 'decoder_audio':
          final audioBase64 = map['audio'] as String;
          final audioBytes = base64Decode(audioBase64);
          _eventController?.add(SpeechEvent.decoderAudio(audioBytes));
          break;
        case 'recorder_audio':
          final audioBase64 = map['audio'] as String;
          final audioBytes = base64Decode(audioBase64);
          _eventController?.add(SpeechEvent.recorderAudio(audioBytes));
          break;
        case 'player_start_play_audio':
          _eventController?.add(SpeechEvent.playerStartPlayAudio());
          break;
        case 'player_finish_play_audio':
          _eventController?.add(SpeechEvent.playerFinishPlayAudio());
          break;
        case 'tts_start_playing':
          _eventController?.add(SpeechEvent.ttsStartPlaying());
          break;
        case 'tts_finish_playing':
          _eventController?.add(SpeechEvent.ttsFinishPlaying());
          break;
        case 'tts_audio_data_end':
          _eventController?.add(SpeechEvent.ttsAudioDataEnd());
          break;
        case 'tts_ended':
          _eventController?.add(SpeechEvent.ttsEnded());
          break;
        case 'tts_sentence_start':
          _eventController?.add(SpeechEvent.ttsSentenceStart(map['data']));
          break;
        case 'tts_sentence_end':
          _eventController?.add(SpeechEvent.ttsSentenceEnd(map['data']));
          break;
        case 'session_started':
          _eventController?.add(SpeechEvent.sessionStarted(map['data']));
          break;
      }
    });

    _initialized = true;
  }

  /// Get the event stream
  static Stream<SpeechEvent> get events {
    if (!_initialized) {
      throw StateError('Plugin not initialized. Call init() first.');
    }
    return _eventController!.stream;
  }

  /// Prepare the speech engine
  static Future<bool> prepare() async {
    return await _methodChannel.invokeMethod('prepare');
  }

  /// Initialize the speech engine with configuration
  static Future<bool> initializeEngine({
    required String appId,
    required String appKey,
    required String token,
    String engineName = 'dialog',
    String resourceId = 'volc.speech.dialog',
    String uid = 'flutter_user',
    String? logPath,
    String? logLevel,
    bool enableAEC = false,
    String? aecModelPath,
    String? recorderType,
    String? recorderPath,
    bool enableRecorderCallback = false,
    bool enablePlayer = true,
    bool enablePlayerCallback = false,
    bool enableDecoderCallback = false,
    String? playerPath,
    int? workMode,
    bool enableResampler = false,
    int? customSampleRate,
    int? customChannel,
    String speaker = 'zh_female_vv_jupiter_bigtts', // 新增音色参数
    String botName = 'Angela', // 新增botName参数
    String systemRole = '', // 新增systemRole参数
  }) async {
    return await _methodChannel.invokeMethod('init', {
      'engineName': engineName,
      'appId': appId,
      'appKey': appKey,
      'token': token,
      'resourceId': resourceId,
      'uid': uid,
      'logPath': logPath,
      'logLevel': logLevel,
      'enableAEC': enableAEC,
      'aecModelPath': aecModelPath,
      'recorderType': recorderType,
      'recorderPath': recorderPath,
      'enableRecorderCallback': enableRecorderCallback,
      'enablePlayer': enablePlayer,
      'enablePlayerCallback': enablePlayerCallback,
      'enableDecoderCallback': enableDecoderCallback,
      'playerPath': playerPath,
      'workMode': workMode,
      'enableResampler': enableResampler,
      'customSampleRate': customSampleRate,
      'customChannel': customChannel,
      'speaker': speaker,
      'botName': botName,
      'systemRole': systemRole,
    });
  }

  /// Start the conversation
  static Future<bool> start() async {
    return await _methodChannel.invokeMethod('start');
  }

  /// Stop the conversation
  static Future<bool> stop() async {
    return await _methodChannel.invokeMethod('stop');
  }

  /// Play greeting message
  static Future<bool> sayHello(String content) async {
    return await _methodChannel.invokeMethod('sayHello', content);
  }

  /// Send text query
  static Future<bool> sendTextQuery(String content) async {
    return await _methodChannel.invokeMethod('sendTextQuery', content);
  }

  /// Send natural language command (emotion, dialect, speed, etc.)
  static Future<bool> sendCommand(String command) async {
    return await _methodChannel.invokeMethod('sendCommand', command);
  }

  /// Destroy the engine and release resources
  static Future<bool> destroy() async {
    return await _methodChannel.invokeMethod('destroy');
  }

  /// Check if plugin is initialized
  static bool get isInitialized => _initialized;

  /// Dispose the plugin
  static void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    if (_eventController != null) {
      _eventController?.close();
      _eventController = null;
    }
    _initialized = false;
  }
}
