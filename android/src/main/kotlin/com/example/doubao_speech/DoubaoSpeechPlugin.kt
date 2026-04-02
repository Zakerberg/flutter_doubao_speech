package com.example.doubao_speech

import android.content.Context
import android.util.Base64
import com.bytedance.speechengine.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.EventChannel.EventSink
import org.json.JSONObject

class DoubaoSpeechPlugin : FlutterPlugin, MethodCallHandler, StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventSink? = null
    private var engine: SpeechEngine? = null
    private var context: Context? = null
    private var isInitialized = false
    private var speaker: String = "zh_female_vv_jupiter_bigtts" // 存储音色配置

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "doubao_speech/methods")
        eventChannel = EventChannel(binding.binaryMessenger, "doubao_speech/events")
        
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        
        // 初始化环境
        SpeechEngine.prepareEnvironment(binding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "prepare" -> prepare(result)
            "init" -> initEngine(call, result)
            "start" -> startEngine(result)
            "stop" -> stopEngine(result)
            "sayHello" -> sayHello(call, result)
            "sendTextQuery" -> sendTextQuery(call, result)
            "sendCommand" -> sendCommand(call, result)
            "destroy" -> destroyEngine(result)
            else -> result.notImplemented()
        }
    }

    private fun prepare(result: Result) {
        if (engine == null) {
            engine = SpeechEngine()
            engine?.createEngine(object : SpeechEngineDelegate {
                override fun onMessage(type: SEMessageType, data: ByteArray?) {
                    handleMessage(type, data)
                }
            })
        }
        result.success(true)
    }

    private fun initEngine(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val engine = engine ?: run {
            result.error("ENGINE_NOT_PREPARED", "Engine not prepared", null)
            return
        }

        // 保存音色配置
        (args?.get("speaker") as? String)?.let {
            if (it.isNotEmpty()) {
                speaker = it
            }
        }

        // 必需配置
        engine.setStringParam(args?.get("engineName") as? String ?: "dialog",
            SE_PARAMS_KEY_ENGINE_NAME_STRING)
        engine.setStringParam(args?.get("appId") as? String ?: "",
            SE_PARAMS_KEY_APP_ID_STRING)
        engine.setStringParam(args?.get("appKey") as? String ?: "",
            SE_PARAMS_KEY_APP_KEY_STRING)
        engine.setStringParam(args?.get("token") as? String ?: "",
            SE_PARAMS_KEY_APP_TOKEN_STRING)
        engine.setStringParam(args?.get("resourceId") as? String ?: "volc.speech.dialog",
            SE_PARAMS_KEY_RESOURCE_ID_STRING)
        engine.setStringParam(args?.get("uid") as? String ?: "flutter_user",
            SE_PARAMS_KEY_UID_STRING)
        engine.setStringParam("wss://openspeech.bytedance.com",
            SE_PARAMS_KEY_DIALOG_ADDRESS_STRING)
        engine.setStringParam("/api/v3/realtime/dialogue",
            SE_PARAMS_KEY_DIALOG_URI_STRING)

        // 日志配置
        args?.get("logPath")?.let {
            engine.setStringParam(it as String, SE_PARAMS_KEY_DEBUG_PATH_STRING)
        }
        args?.get("logLevel")?.let {
            engine.setStringParam(it as String, SE_PARAMS_KEY_LOG_LEVEL_STRING)
        }

        // AEC 配置（回声消除）
        val enableAEC = args?.get("enableAEC") as? Boolean ?: false
        if (enableAEC) {
            engine.setBoolParam(true, SE_PARAMS_KEY_ENABLE_AEC_BOOL)
            args?.get("aecModelPath")?.let {
                engine.setStringParam(it as String, SE_PARAMS_KEY_AEC_MODEL_PATH_STRING)
            }
        }

        // 录音机配置
        args?.get("recorderType")?.let {
            engine.setStringParam(it as String, SE_PARAMS_KEY_RECORDER_TYPE_STRING)
        }
        args?.get("recorderPath")?.let {
            engine.setStringParam(it as String, SE_PARAMS_KEY_DIALOG_RECORDER_PATH_STRING)
        }
        args?.get("enableRecorderCallback")?.let {
            engine.setBoolParam(it as Boolean, SE_PARAMS_KEY_DIALOG_ENABLE_RECORDER_AUDIO_CALLBACK_BOOL)
        }

        // 播放器配置
        args?.get("enablePlayer")?.let {
            engine.setBoolParam(it as Boolean, SE_PARAMS_KEY_DIALOG_ENABLE_PLAYER_BOOL)
        }
        args?.get("enablePlayerCallback")?.let {
            engine.setBoolParam(it as Boolean, SE_PARAMS_KEY_DIALOG_ENABLE_PLAYER_AUDIO_CALLBACK_BOOL)
        }
        args?.get("enableDecoderCallback")?.let {
            engine.setBoolParam(it as Boolean, SE_PARAMS_KEY_DIALOG_ENABLE_DECODER_AUDIO_CALLBACK_BOOL)
        }
        args?.get("playerPath")?.let {
            engine.setStringParam(it as String, SE_PARAMS_KEY_DIALOG_PLAYER_PATH_STRING)
        }

        // 工作模式配置（用于自定义 TTS）
        args?.get("workMode")?.let {
            engine.setIntParam((it as Int).toLong(), SE_PARAMS_KEY_DIALOG_WORK_MODE_INT)
        }

        // 重采样配置（自定义音频输入时使用）
        args?.get("enableResampler")?.let {
            engine.setBoolParam(it as Boolean, SE_PARAMS_KEY_ENABLE_RESAMPLER_BOOL)
        }
        args?.get("customSampleRate")?.let {
            engine.setIntParam((it as Int).toLong(), SE_PARAMS_KEY_CUSTOM_SAMPLE_RATE_INT)
        }
        args?.get("customChannel")?.let {
            engine.setIntParam((it as Int).toLong(), SE_PARAMS_KEY_CUSTOM_CHANNEL_INT)
        }

        // 初始化引擎
        val ret = engine.initEngine()
        if (ret == SENoError) {
            isInitialized = true
            result.success(true)
        } else {
            result.error("INIT_FAILED", "Init engine failed: $ret", null)
        }
    }

    private fun startEngine(result: Result) {
        val engine = engine ?: run {
            result.error("ENGINE_NOT_INIT", "Engine not initialized", null)
            return
        }

        if (!isInitialized) {
            result.error("ENGINE_NOT_INIT", "Engine not initialized", null)
            return
        }

        // 先同步停止
        engine.sendDirective(SEDirectiveSyncStopEngine)

        // 启动引擎，使用保存的音色配置
        val ttsConfig = """
            {
                "dialog": {
                    "bot_name": "豆包"
                },
                "tts": {
                    "speaker": "$speaker"
                }
            }
        """.trimIndent()
        
        val ret = engine.sendDirective(SEDirectiveStartEngine, ttsConfig)

        if (ret == SENoError) {
            result.success(true)
        } else {
            result.error("START_FAILED", "Start engine failed: $ret", null)
        }
    }

    private fun stopEngine(result: Result) {
        val engine = engine ?: run {
            result.success(false)
            return
        }

        val ret = engine.sendDirective(SEDirectiveSyncStopEngine)
        result.success(ret == SENoError)
    }

    private fun sayHello(call: MethodCall, result: Result) {
        val engine = engine ?: run {
            result.error("ENGINE_NOT_INIT", "Engine not initialized", null)
            return
        }

        val content = call.arguments as? String ?: "我是你的AI助手，请问有什么可以帮你。"
        val data = buildContentPayload(content)
        val ret = engine.sendDirective(SEDirectiveEventSayHello, data)

        if (ret == SENoError) {
            result.success(true)
        } else {
            result.error("SAY_HELLO_FAILED", "Say hello failed: $ret", null)
        }
    }

    private fun sendTextQuery(call: MethodCall, result: Result) {
        val engine = engine ?: run {
            result.error("ENGINE_NOT_INIT", "Engine not initialized", null)
            return
        }

        val content = call.arguments as? String ?: ""
        val data = buildContentPayload(content)
        val ret = engine.sendDirective(SEDirectiveEventChatTextQuery, data)

        if (ret == SENoError) {
            result.success(true)
        } else {
            result.error("TEXT_QUERY_FAILED", "Text query failed: $ret", null)
        }
    }

    private fun sendCommand(call: MethodCall, result: Result) {
        // 自然语言指令通过文本查询发送
        sendTextQuery(call, result)
    }

    private fun buildContentPayload(content: String): String {
        return JSONObject().put("content", content).toString()
    }

    private fun destroyEngine(result: Result) {
        engine?.destroyEngine()
        engine = null
        isInitialized = false
        result.success(true)
    }

    private fun handleMessage(type: SEMessageType, data: ByteArray?) {
        when (type) {
            SEEngineStart -> sendEvent("engine_start", data?.let { String(it) })
            SEEngineStop -> sendEvent("engine_stop", data?.let { String(it) })
            SEEngineError -> sendEvent("engine_error", data?.let { String(it) } ?: "Unknown error")
            SEDialogASRInfo -> sendEvent("asr_start", null)
            SEDialogASRResponse -> sendEvent("asr_result", data?.let { String(it) })
            SEDialogASREnded -> sendEvent("asr_end", null)
            SEDialogChatResponse -> sendEvent("chat_result", data?.let { String(it) })
            SEDialogChatEnded -> sendEvent("chat_end", null)
            SEDialogPlayerAudio -> data?.let { sendAudioEvent("player_audio", it) }
            SEDecoderAudioData -> data?.let { sendAudioEvent("decoder_audio", it) }
            SEDialogRecorderAudio -> data?.let { sendAudioEvent("recorder_audio", it) }
            else -> {}
        }
    }

    private fun sendEvent(type: String, data: String?) {
        eventSink?.let { sink ->
            val event = mutableMapOf<String, Any>("type" to type)
            data?.let { event["data"] = it }
            sink.success(event)
        }
    }

    private fun sendAudioEvent(type: String, data: ByteArray) {
        eventSink?.let { sink ->
            val event = mapOf(
                "type" to type,
                "audio" to Base64.encodeToString(data, Base64.NO_WRAP)
            )
            sink.success(event)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        engine?.destroyEngine()
        engine = null
        context = null
        isInitialized = false
    }

    override fun onListen(arguments: Any?, events: EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
