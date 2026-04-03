import Flutter
import Foundation
import UIKit
import SpeechEngineToB

public class DoubaoSpeechPlugin: NSObject, FlutterPlugin {
    private var engine: SpeechEngine?
    private var methodChannel: FlutterMethodChannel?
    private var eventSink: FlutterEventSink?
    private var isInitialized = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "doubao_speech/methods",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "doubao_speech/events",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = DoubaoSpeechPlugin()
        instance.methodChannel = methodChannel
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        
        eventChannel.setStreamHandler(instance)
        
        // 初始化环境（App生命周期内仅需执行一次）
        _ = SpeechEngine.prepareEnvironment()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "prepare":
            prepare(result: result)
        case "init":
            initEngine(call: call, result: result)
        case "start":
            startEngine(result: result)
        case "stop":
            stopEngine(result: result)
        case "sayHello":
            sayHello(call: call, result: result)
        case "sendTextQuery":
            sendTextQuery(call: call, result: result)
        case "sendCommand":
            sendCommand(call: call, result: result)
        case "destroy":
            destroyEngine(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Private Methods
    
    private func prepare(result: @escaping FlutterResult) {
        if engine == nil {
            engine = SpeechEngine()
            engine?.createEngine(with: self)
        }
        result(true)
    }
    
    private func initEngine(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let engine = engine else {
            result(FlutterError(code: "INVALID_ARGS", 
                               message: "Invalid arguments or engine not prepared", 
                               details: nil))
            return
        }
        
        // 必需配置
        engine.setStringParam(args["engineName"] as? String ?? "dialog", 
                             forKey: SE_PARAMS_KEY_ENGINE_NAME_STRING)
        engine.setStringParam(args["appId"] as? String ?? "", 
                             forKey: SE_PARAMS_KEY_APP_ID_STRING)
        engine.setStringParam(args["appKey"] as? String ?? "", 
                             forKey: SE_PARAMS_KEY_APP_KEY_STRING)
        engine.setStringParam(args["token"] as? String ?? "", 
                             forKey: SE_PARAMS_KEY_APP_TOKEN_STRING)
        engine.setStringParam(args["resourceId"] as? String ?? "volc.speech.dialog", 
                             forKey: SE_PARAMS_KEY_RESOURCE_ID_STRING)
        engine.setStringParam(args["uid"] as? String ?? "flutter_user", 
                             forKey: SE_PARAMS_KEY_UID_STRING)
        engine.setStringParam("wss://openspeech.bytedance.com", 
                             forKey: SE_PARAMS_KEY_DIALOG_ADDRESS_STRING)
        engine.setStringParam("/api/v3/realtime/dialogue", 
                             forKey: SE_PARAMS_KEY_DIALOG_URI_STRING)
        
        // 日志配置
        if let logPath = args["logPath"] as? String, !logPath.isEmpty {
            engine.setStringParam(logPath, forKey: SE_PARAMS_KEY_DEBUG_PATH_STRING)
        }
        if let logLevel = args["logLevel"] as? String {
            engine.setStringParam(logLevel, forKey: SE_PARAMS_KEY_LOG_LEVEL_STRING)
        }
        
        // AEC 配置（回声消除）
        if let enableAEC = args["enableAEC"] as? Bool, enableAEC {
            engine.setBoolParam(true, forKey: SE_PARAMS_KEY_ENABLE_AEC_BOOL)
            if let aecModelPath = args["aecModelPath"] as? String, !aecModelPath.isEmpty {
                engine.setStringParam(aecModelPath, forKey: SE_PARAMS_KEY_AEC_MODEL_PATH_STRING)
            }
        }
        
        // 录音机配置
        if let recorderType = args["recorderType"] as? String {
            engine.setStringParam(recorderType, forKey: SE_PARAMS_KEY_RECORDER_TYPE_STRING)
        }
        if let recorderPath = args["recorderPath"] as? String, !recorderPath.isEmpty {
            engine.setStringParam(recorderPath, forKey: SE_PARAMS_KEY_DIALOG_RECORDER_PATH_STRING)
        }
        if let enableRecorderCallback = args["enableRecorderCallback"] as? Bool {
            engine.setBoolParam(enableRecorderCallback, 
                               forKey: SE_PARAMS_KEY_DIALOG_ENABLE_RECORDER_AUDIO_CALLBACK_BOOL)
        }
        
        // 播放器配置
        if let enablePlayer = args["enablePlayer"] as? Bool {
            engine.setBoolParam(enablePlayer, forKey: SE_PARAMS_KEY_DIALOG_ENABLE_PLAYER_BOOL)
        }
        if let enablePlayerCallback = args["enablePlayerCallback"] as? Bool {
            engine.setBoolParam(enablePlayerCallback, 
                               forKey: SE_PARAMS_KEY_DIALOG_ENABLE_PLAYER_AUDIO_CALLBACK_BOOL)
        }
        if let enableDecoderCallback = args["enableDecoderCallback"] as? Bool {
            engine.setBoolParam(enableDecoderCallback, 
                               forKey: SE_PARAMS_KEY_DIALOG_ENABLE_DECODER_AUDIO_CALLBACK_BOOL)
        }
        if let playerPath = args["playerPath"] as? String, !playerPath.isEmpty {
            engine.setStringParam(playerPath, forKey: SE_PARAMS_KEY_DIALOG_PLAYER_PATH_STRING)
        }
        
        // 工作模式配置（用于自定义 TTS）
        if let workMode = args["workMode"] as? Int {
            engine.setIntParam(workMode, forKey: SE_PARAMS_KEY_DIALOG_WORK_MODE_INT)
        }
        
        // 重采样配置（自定义音频输入时使用）
        if let enableResampler = args["enableResampler"] as? Bool {
            engine.setBoolParam(enableResampler, forKey: SE_PARAMS_KEY_ENABLE_RESAMPLER_BOOL)
        }
        if let customSampleRate = args["customSampleRate"] as? Int {
            engine.setIntParam(customSampleRate, forKey: SE_PARAMS_KEY_CUSTOM_SAMPLE_RATE_INT)
        }
        if let customChannel = args["customChannel"] as? Int {
            engine.setIntParam(customChannel, forKey: SE_PARAMS_KEY_CUSTOM_CHANNEL_INT)
        }
        
        // 初始化引擎
        let ret = engine.initEngine()
        if ret == SENoError {
            isInitialized = true
            result(true)
        } else {
            result(FlutterError(code: "INIT_FAILED", 
                               message: "Init engine failed: \(ret)", 
                               details: nil))
        }
    }
    
    private func startEngine(result: @escaping FlutterResult) {
        guard let engine = engine, isInitialized else {
            result(FlutterError(code: "ENGINE_NOT_INIT", 
                               message: "Engine not initialized", 
                               details: nil))
            return
        }
        
        // 先同步停止，避免异步问题
        engine.send(SEDirectiveSyncStopEngine)
        
        // 启动引擎，使用保存的音色配置
        // let ttsConfig = "{\"dialog\":{\"bot_name\":\"豆包\"},\"tts\":{\"speaker\":\"\(speaker)\"}}"
        let dict = [
                    "dialog": ["bot_name": "豆包"],
                    "tts": ["speaker": speaker]
                   ]
        let jsonData = try? JSONSerialization.data(withJSONObject: dict)
        let ttsConfig = jsonData.flatMap { String(data: $0, encoding: .utf8) }
        
        let ret = engine.send(SEDirectiveStartEngine, data: ttsConfig)

        if ret == SENoError {
            result(true)
        } else {
            result(FlutterError(code: "START_FAILED", 
                               message: "Start engine failed: \(ret)", 
                               details: nil))
        }
    }
    
    private func stopEngine(result: @escaping FlutterResult) {
        guard let engine = engine else {
            result(false)
            return
        }
        
        let ret = engine.send(SEDirectiveSyncStopEngine)
        result(ret == SENoError)
    }
    
    private func sayHello(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let engine = engine, isInitialized else {
            result(FlutterError(code: "ENGINE_NOT_INIT", 
                               message: "Engine not initialized", 
                               details: nil))
            return
        }
        
        let content = call.arguments as? String ?? "我是你的AI助手，请问有什么可以帮你。"
        let data = buildContentPayload(content)
        let ret = engine.send(SEDirectiveEventSayHello, data: data)
        
        if ret == SENoError {
            result(true)
        } else {
            result(FlutterError(code: "SAY_HELLO_FAILED", 
                               message: "Say hello failed: \(ret)", 
                               details: nil))
        }
    }
    
    private func sendTextQuery(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let engine = engine, isInitialized else {
            result(FlutterError(code: "ENGINE_NOT_INIT", 
                               message: "Engine not initialized", 
                               details: nil))
            return
        }
        
        let content = call.arguments as? String ?? ""
        let data = buildContentPayload(content)
        let ret = engine.send(SEDirectiveEventChatTextQuery, data: data)
        
        if ret == SENoError {
            result(true)
        } else {
            result(FlutterError(code: "TEXT_QUERY_FAILED", 
                               message: "Text query failed: \(ret)", 
                               details: nil))
        }
    }
    
    private func sendCommand(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // 自然语言指令通过文本查询发送
        sendTextQuery(call: call, result: result)
    }

    private func buildContentPayload(_ content: String) -> String {
        let json: [String: String] = ["content": content]
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{\"content\":\"\"}"
        }
        return jsonString
    }
    
    private func destroyEngine(result: @escaping FlutterResult) {
        engine?.destroy()
        engine = nil
        isInitialized = false
        result(true)
    }
    
    // MARK: - Helper Methods
    
    private func sendEvent(type: String, data: Any?) {
        guard let eventSink = eventSink else { return }
        var event: [String: Any] = ["type": type]
        if let data = data {
            event["data"] = data
        }
        eventSink(event)
    }
    
    private func sendAudioEvent(type: String, audioData: Data) {
        guard let eventSink = eventSink else { return }
        let event: [String: Any] = [
            "type": type,
            "audio": audioData.base64EncodedString()
        ]
        eventSink(event)
    }
}

// MARK: - SpeechEngineDelegate

extension DoubaoSpeechPlugin: SpeechEngineDelegate {
    public func onMessage(with type: SEMessageType, andData data: Data?) {
        switch type {
        case SEEngineStart:
            sendEvent(type: "engine_start", data: data.flatMap { String(data: $0, encoding: .utf8) })
            
        case SEEngineStop:
            sendEvent(type: "engine_stop", data: data.flatMap { String(data: $0, encoding: .utf8) })
            
        case SEEngineError:
            let errorMsg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
            sendEvent(type: "engine_error", data: errorMsg)
            
        case SEDialogASRInfo:
            sendEvent(type: "asr_start", data: nil)
            
        case SEDialogASRResponse:
            let text = data.flatMap { String(data: $0, encoding: .utf8) }
            sendEvent(type: "asr_result", data: text)
            
        case SEDialogASREnded:
            sendEvent(type: "asr_end", data: nil)
            
        case SEDialogChatResponse:
            let text = data.flatMap { String(data: $0, encoding: .utf8) }
            sendEvent(type: "chat_result", data: text)
            
        case SEDialogChatEnded:
            sendEvent(type: "chat_end", data: nil)
            
        case SEDialogPlayerAudio:
            if let audioData = data {
                sendAudioEvent(type: "player_audio", audioData: audioData)
            }
            
        case SEDecoderAudioData:
            if let audioData = data {
                sendAudioEvent(type: "decoder_audio", audioData: audioData)
            }
            
        case SEDialogRecorderAudio:
            if let audioData = data {
                sendAudioEvent(type: "recorder_audio", audioData: audioData)
            }
            
        default:
            break
        }
    }
}

// MARK: - FlutterStreamHandler
extension DoubaoSpeechPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
