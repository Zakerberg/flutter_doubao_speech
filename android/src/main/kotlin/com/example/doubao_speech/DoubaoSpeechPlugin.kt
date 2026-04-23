package com.example.doubao_speech

import android.app.Application
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import com.bytedance.speech.speechengine.SpeechEngine
import com.bytedance.speech.speechengine.SpeechEngineDefines
import com.bytedance.speech.speechengine.SpeechEngineGenerator
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject

class DoubaoSpeechPlugin : FlutterPlugin, MethodCallHandler, StreamHandler {
    
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventSink? = null
    private var engine: SpeechEngine? = null
    private var context: Context? = null
    private var isInitialized = false
    private var speaker: String = "zh_female_vv_jupiter_bigtts"
    private var botName: String = "Angela"
    private var systemRole: String = "Act as an digital American girl living is an App called SpeakGuru, SpeakGuru is a platform to help people practice spoken language. This digital girl is created by a Chinese tech company named HuoShan Innovation, SpeakGuru is the product made by HuoShan Innovation company, the girl is created as a language partner and English teacher, and play a dialog with the user to help the user to practice English and improve English skills. The girl's name is Angela, 25 years old, born and raised in California,her father is an engineer from Google, mother is a lawyer, and well educated. The girl is a good listener and talker, interested in whatever the user tell you, always follow user's topic and ask for details, don't change topic by yourself, show interest to know user's opinion and story, show empathy. The girl can speak fluent American English.Remember what user says, be friend with the user. Respond in English using the tone, manner and vocabulary a friendly California girl would use. Do not write any explanations."
    private var dialogId: String = ""

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "doubao_speech/methods")
        eventChannel = EventChannel(binding.binaryMessenger, "doubao_speech/events")

        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)

        val ctx = binding.applicationContext
        SpeechEngineGenerator.PrepareEnvironment(ctx, ctx as? Application)
    }

    // ✅ 必须实现这个方法
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        engine?.destroyEngine()
        engine = null
        context = null
        isInitialized = false
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
            "chatTextQuery" -> chatTextQuery(call, result)
            else -> result.notImplemented()
        }
    }

    private fun prepare(result: Result) {
        if (engine == null) {
            val eng = SpeechEngineGenerator.getInstance()
            val ctx = context
            if (ctx != null) {
                eng.setContext(ctx)
            }
            eng.setListener(object : SpeechEngine.SpeechListener {
                override fun onSpeechMessage(type: Int, data: ByteArray?, length: Int) {
                    val payload = when {
                        data == null || length <= 0 -> null
                        length > data.size -> data
                        else -> data.copyOf(length)
                    }
                    handleMessage(type, payload)
                }
            })
            eng.createEngine()
            engine = eng
        }
        result.success(true)
    }

    private fun initEngine(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val engine = engine ?: run {
            result.error("ENGINE_NOT_PREPARED", "Engine not prepared", null)
            return
        }

        (args?.get("speaker") as? String)?.let {
            if (it.isNotEmpty()) {
                speaker = it
            }
        }

        (args?.get("botName") as? String)?.let {
            if (it.isNotEmpty()) {
                botName = it
            }
        }

        (args?.get("dialogId") as? String)?.let {
            if (it.isNotEmpty()) {
                dialogId = it
            }
        }

        (args?.get("systemRole") as? String)?.let {
            if (it.isNotEmpty()) {
                systemRole = it
            }
        }

        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_ENGINE_NAME_STRING,
            args?.get("engineName") as? String ?: "dialog"
        )
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_APP_ID_STRING,
            args?.get("appId") as? String ?: ""
        )
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_APP_KEY_STRING,
            args?.get("appKey") as? String ?: ""
        )
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_APP_TOKEN_STRING,
            args?.get("token") as? String ?: ""
        )
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_RESOURCE_ID_STRING,
            args?.get("resourceId") as? String ?: "volc.speech.dialog"
        )
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_UID_STRING,
            args?.get("uid") as? String ?: "flutter_user"
        )
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_DIALOG_ADDRESS_STRING,
            "wss://openspeech.bytedance.com"
        )
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_DIALOG_URI_STRING,
            "/api/v3/realtime/dialogue"
        )

        args?.get("logPath")?.let {
            engine.setOptionString(
                SpeechEngineDefines.PARAMS_KEY_DEBUG_PATH_STRING,
                it as String
            )
        }
        args?.get("logLevel")?.let {
            engine.setOptionString(
                SpeechEngineDefines.PARAMS_KEY_LOG_LEVEL_STRING,
                it as String
            )
        }

        val enableAEC = args?.get("enableAEC") as? Boolean ?: false
        if (enableAEC) {
            engine.setOptionBoolean(
                SpeechEngineDefines.PARAMS_KEY_ENABLE_AEC_BOOL,
                true
            )
            args?.get("aecModelPath")?.let {
                engine.setOptionString(
                    SpeechEngineDefines.PARAMS_KEY_AEC_MODEL_PATH_STRING,
                    it as String
                )
            }
        }

        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_RECORDER_TYPE_STRING,
            SpeechEngineDefines.RECORDER_TYPE_RECORDER
        )
        args?.get("recorderPath")?.let {
            engine.setOptionString(
                SpeechEngineDefines.PARAMS_KEY_DIALOG_RECORDER_PATH_STRING,
                it as String
            )
        }
        args?.get("enableRecorderCallback")?.let {
            engine.setOptionBoolean(
                SpeechEngineDefines.PARAMS_KEY_DIALOG_ENABLE_RECORDER_AUDIO_CALLBACK_BOOL,
                it as Boolean
            )
        }

        engine.setOptionBoolean(
            SpeechEngineDefines.PARAMS_KEY_TTS_ENABLE_PLAYER_BOOL, true
        )
        engine.setOptionBoolean(
            SpeechEngineDefines.PARAMS_KEY_ENABLE_PLAYER_AUDIO_CALLBACK_BOOL, true
        )
        args?.get("enablePlayer")?.let {
            engine.setOptionBoolean(
                SpeechEngineDefines.PARAMS_KEY_DIALOG_ENABLE_PLAYER_BOOL,
                it as Boolean
            )
        }
        args?.get("enableDecoderCallback")?.let {
            engine.setOptionBoolean(
                SpeechEngineDefines.PARAMS_KEY_DIALOG_ENABLE_DECODER_AUDIO_CALLBACK_BOOL,
                it as Boolean
            )
        }
        args?.get("playerPath")?.let {
            engine.setOptionString(
                SpeechEngineDefines.PARAMS_KEY_DIALOG_PLAYER_PATH_STRING,
                it as String
            )
        }

        args?.get("workMode")?.let {
            engine.setOptionInt(
                SpeechEngineDefines.PARAMS_KEY_DIALOG_WORK_MODE_INT,
                it as Int
            )
        }

        args?.get("enableResampler")?.let {
            engine.setOptionBoolean(
                SpeechEngineDefines.PARAMS_KEY_ENABLE_RESAMPLER_BOOL,
                it as Boolean
            )
        }
        args?.get("customSampleRate")?.let {
            engine.setOptionInt(
                SpeechEngineDefines.PARAMS_KEY_CUSTOM_SAMPLE_RATE_INT,
                it as Int
            )
        }
        args?.get("customChannel")?.let {
            engine.setOptionInt(
                SpeechEngineDefines.PARAMS_KEY_CUSTOM_CHANNEL_INT,
                it as Int
            )
        }

        val ret = engine.initEngine()
        if (ret == SpeechEngineDefines.ERR_NO_ERROR) {
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

        engine.sendDirective(SpeechEngineDefines.DIRECTIVE_SYNC_STOP_ENGINE, "")

        val ttsConfig = "{\"dialog\":{\"bot_name\":\"$botName\",\"dialog_id\":\"$dialogId\", \"character_manifest\":\"$systemRole\", \"extra\":{\"model\":\"2.2.0.0\", \"input_mod\": \"keep_alive\"}},\"tts\":{\"speaker\":\"$speaker\"}}"
        val ret = engine.sendDirective(SpeechEngineDefines.DIRECTIVE_START_ENGINE, ttsConfig)

        if (ret == SpeechEngineDefines.ERR_NO_ERROR) {
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

        val ret = engine.sendDirective(SpeechEngineDefines.DIRECTIVE_SYNC_STOP_ENGINE, "")
        result.success(ret == SpeechEngineDefines.ERR_NO_ERROR)
    }

    private fun sayHello(call: MethodCall, result: Result) {
        val engine = engine ?: run {
            result.error("ENGINE_NOT_INIT", "Engine not initialized", null)
            return
        }

        val content = call.arguments as? String ?: "我是你的AI助手，请问有什么可以帮你。"
        val data = buildContentPayload(content)
        val ret = engine.sendDirective(SpeechEngineDefines.DIRECTIVE_EVENT_SAY_HELLO, data)

        if (ret == SpeechEngineDefines.ERR_NO_ERROR) {
            result.success(true)
        } else {
            result.error("SAY_HELLO_FAILED", "Say hello failed: $ret", null)
        }
    }

    private fun chatTextQuery(call: MethodCall, result: MethodChannel.Result) {
    if (engine == null || !isInitialized) {
        result.error("ENGINE_NOT_INIT", "Engine not initialized", null)
        return
    }
    
    val content = call.arguments as? String ?: ""
    val json = JSONObject().apply {
        put("content", content)
    }.toString()
    
    val ret = engine?.sendDirective(
        SpeechEngineDefines.DIRECTIVE_EVENT_CHAT_TEXT_QUERY,
        json
    )
     result.success(ret == SpeechEngineDefines.ERR_NO_ERROR)
   }

    private fun sendTextQuery(call: MethodCall, result: Result) {
        val engine = engine ?: run {
            result.error("ENGINE_NOT_INIT", "Engine not initialized", null)
            return
        }

        val content = call.arguments as? String ?: ""
        val data = buildContentPayload(content)
        val ret = engine.sendDirective(SpeechEngineDefines.DIRECTIVE_EVENT_CHAT_TEXT_QUERY, data)

        if (ret == SpeechEngineDefines.ERR_NO_ERROR) {
            result.success(true)
        } else {
            result.error("TEXT_QUERY_FAILED", "Text query failed: $ret", null)
        }
    }

    private fun sendCommand(call: MethodCall, result: Result) {
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

    // ✅ handleMessage 必须在类内部，不能嵌套
    private fun handleMessage(type: Int, data: ByteArray?) {
        when (type) {
            SpeechEngineDefines.MESSAGE_TYPE_ENGINE_START ->
                sendEvent("engine_start", data?.let { String(it) })
                
            SpeechEngineDefines.MESSAGE_TYPE_ENGINE_STOP ->
                sendEvent("engine_stop", data?.let { String(it) })
                
            SpeechEngineDefines.MESSAGE_TYPE_ENGINE_ERROR ->
                sendEvent("engine_error", data?.let { String(it) } ?: "Unknown error")
                
            SpeechEngineDefines.MESSAGE_TYPE_DIALOG_ASR_INFO ->
                sendEvent("asr_start", null)
                
            SpeechEngineDefines.MESSAGE_TYPE_DIALOG_ASR_RESPONSE -> {
                try {
                    val jsonString = data?.let { String(it) }
                    val jsonObject = JSONObject(jsonString ?: "")
                    val results = jsonObject.optJSONArray("results")
                    if (results != null && results.length() > 0) {
                        val firstResult = results.getJSONObject(0)
                        val text = firstResult.optString("text")
                        sendEvent("asr_result", text)
                    }
                } catch (e: Exception) {
                    // 解析失败，忽略
                }
            }
            
            SpeechEngineDefines.MESSAGE_TYPE_DIALOG_ASR_ENDED ->
                sendEvent("asr_end", null)
                
            SpeechEngineDefines.MESSAGE_TYPE_DIALOG_CHAT_RESPONSE -> {
                try {
                    val jsonString = data?.let { String(it) }
                    val jsonObject = JSONObject(jsonString ?: "")
                    val content = jsonObject.optString("content", "")
                    if (content.isNotEmpty()) {
                        sendEvent("chat_result", content)
                    }
                    // 如果 content 为空，什么都不发送（不 fallback）
                } catch (e: Exception) {
                    // 解析失败，忽略
                }
            }
            
            SpeechEngineDefines.MESSAGE_TYPE_DIALOG_CHAT_ENDED ->
                sendEvent("chat_end", null)
                
            SpeechEngineDefines.MESSAGE_TYPE_DIALOG_PLAYER_AUDIO ->
                data?.let { sendAudioEvent("player_audio", it) }
                
            SpeechEngineDefines.MESSAGE_TYPE_DECODER_AUDIO_DATA ->
                data?.let { sendAudioEvent("decoder_audio", it) }
                
            SpeechEngineDefines.MESSAGE_TYPE_DIALOG_RECORDER_AUDIO ->
                data?.let { sendAudioEvent("recorder_audio", it) }
            // SEPlayerStartPlayAudio (3019)
            SpeechEngineDefines.MESSAGE_TYPE_PLAYER_START_PLAY_AUDIO ->
                sendEvent("player_start_play_audio", null)
                
            // SEPlayerFinishPlayAudio (3020)
            SpeechEngineDefines.MESSAGE_TYPE_PLAYER_FINISH_PLAY_AUDIO ->
                sendEvent("player_finish_play_audio", null)
                
            // SETtsStartPlaying (1401)
            SpeechEngineDefines.MESSAGE_TYPE_TTS_START_PLAYING ->
                sendEvent("tts_start_playing", null)
                
            // SETtsFinishPlaying (1402)
            SpeechEngineDefines.MESSAGE_TYPE_TTS_FINISH_PLAYING ->
                sendEvent("tts_finish_playing", null)
                
            // SETtsAudioDataEnd (1409)
            SpeechEngineDefines.MESSAGE_TYPE_TTS_AUDIO_DATA_END ->
                sendEvent("tts_audio_data_end", null)
                
            // SETtsSynthesisBegin (1403)
            SpeechEngineDefines.MESSAGE_TYPE_TTS_SYNTHESIS_BEGIN ->
                sendEvent("tts_synthesis_begin", null)
                
            // SETtsSynthesisEnd (1404)
            SpeechEngineDefines.MESSAGE_TYPE_TTS_SYNTHESIS_END ->
                sendEvent("tts_synthesis_end", null)
                
            // SEEventTTSEnded (3011)
            SpeechEngineDefines.MESSAGE_TYPE_EVENT_TTS_ENDED -> sendEvent("tts_ended", null)
                
            // SEEventTTSSentenceStart (3008)
            SpeechEngineDefines.MESSAGE_TYPE_EVENT_TTS_SENTENCE_START ->
                sendEvent("tts_sentence_start", data?.let { String(it) })
                
            // SEEventTTSSentenceEnd (3009)
            SpeechEngineDefines.MESSAGE_TYPE_EVENT_TTS_SENTENCE_END ->
                sendEvent("tts_sentence_end", data?.let { String(it) })
                
            // SEEventSessionStarted (3003)
            SpeechEngineDefines.MESSAGE_TYPE_EVENT_SESSION_STARTED ->
                sendEvent("session_started", data?.let { String(it) })
                
            else -> {}
        }
    }

    private fun sendEvent(type: String, data: String?) {
        //        eventSink?.let { sink ->
        //            val event = mutableMapOf<String, Any>("type" to type)
        //            data?.let { event["data"] = it }
        //            sink.success(event)
        //        }

        // 确保在主线程发送事件
        Handler(Looper.getMainLooper()).post {
            eventSink?.let { sink ->
                val event = mutableMapOf<String, Any>("type" to type)
                data?.let { event["data"] = it }
                sink.success(event)
            }
        }
    }

    private fun sendAudioEvent(type: String, data: ByteArray) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.let { sink ->
                val event = mapOf(
                    "type" to type,
                    "audio" to Base64.encodeToString(data, Base64.NO_WRAP)
                )
                sink.success(event)
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}