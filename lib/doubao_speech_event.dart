import 'package:flutter/services.dart';

class SpeechEvent {
  final String type;
  final String? text;
  final Uint8List? audio;

  SpeechEvent._(this.type, {this.text, this.audio});

  /// Engine started
  factory SpeechEvent.engineStart(String? data) =>
      SpeechEvent._('engine_start', text: data);

  /// Engine stopped
  factory SpeechEvent.engineStop(String? data) =>
      SpeechEvent._('engine_stop', text: data);

  /// Engine error
  factory SpeechEvent.engineError(String? data) =>
      SpeechEvent._('engine_error', text: data);

  /// User started speaking
  factory SpeechEvent.asrStart() => SpeechEvent._('asr_start');

  /// ASR recognition result
  factory SpeechEvent.asrResult(String? text) =>
      SpeechEvent._('asr_result', text: text);

  /// User stopped speaking
  factory SpeechEvent.asrEnd() => SpeechEvent._('asr_end');

  /// AI text response
  factory SpeechEvent.chatResult(String? text) =>
      SpeechEvent._('chat_result', text: text);

  /// AI response ended
  factory SpeechEvent.chatEnd() => SpeechEvent._('chat_end');

  /// Player audio callback (follows playback progress)
  factory SpeechEvent.playerAudio(Uint8List audio) =>
      SpeechEvent._('player_audio', audio: audio);

  /// Decoder audio callback (immediate after decoding)
  factory SpeechEvent.decoderAudio(Uint8List audio) =>
      SpeechEvent._('decoder_audio', audio: audio);

  /// Recorder audio callback
  factory SpeechEvent.recorderAudio(Uint8List audio) =>
      SpeechEvent._('recorder_audio', audio: audio);

  /// Player starts playing audio (对应 SEPlayerStartPlayAudio = 3019)
  factory SpeechEvent.playerStartPlayAudio() =>
      SpeechEvent._('player_start_play_audio');

  /// Player finishes playing audio (对应 SEPlayerFinishPlayAudio = 3020)
  factory SpeechEvent.playerFinishPlayAudio() =>
      SpeechEvent._('player_finish_play_audio');

  /// TTS engine starts playing (对应 SETtsStartPlaying = 1401)
  factory SpeechEvent.ttsStartPlaying() => SpeechEvent._('tts_start_playing');

  /// TTS engine finishes playing (对应 SETtsFinishPlaying = 1402)
  factory SpeechEvent.ttsFinishPlaying() => SpeechEvent._('tts_finish_playing');

  /// TTS audio data end (对应 SETtsAudioDataEnd = 1409)
  factory SpeechEvent.ttsAudioDataEnd() => SpeechEvent._('tts_audio_data_end');

  /// TTS 播放结束 (对应 SEEventTTSEnded = 3011)
  factory SpeechEvent.ttsEnded() => SpeechEvent._('tts_ended');

  /// TTS 句子开始播放 (对应 SEEventTTSSentenceStart = 3008)
  factory SpeechEvent.ttsSentenceStart(String? data) =>
      SpeechEvent._('tts_sentence_start', text: data);

  /// TTS 句子播放结束 (对应 SEEventTTSSentenceEnd = 3009)
  factory SpeechEvent.ttsSentenceEnd(String? data) =>
      SpeechEvent._('tts_sentence_end', text: data);

  /// 会话开始 (对应 SEEventSessionStarted = 3003)
  factory SpeechEvent.sessionStarted(String? data) =>
      SpeechEvent._('session_started', text: data);
}
