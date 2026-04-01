import 'dart:io';

import 'package:flutter/material.dart';
import 'package:doubao_speech/doubao_speech.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isReady = false;
  bool _isTalking = false;
  final List<String> _messages = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDoubao();
  }

  Future<void> _initDoubao() async {
    // Initialize plugin
    await DoubaoSpeech.init();

    // Listen to events
    DoubaoSpeech.events.listen((event) {
      setState(() {
        switch (event.type) {
          case 'asr_result':
            _messages.add('👤 我说: ${event.text}');
            break;
          case 'chat_result':
            _messages.add('🤖 豆包: ${event.text}');
            break;
          case 'engine_error':
            _messages.add('❌ 错误: ${event.text}');
            break;
          case 'asr_start':
            _messages.add('🎤 开始说话...');
            break;
          case 'asr_end':
            _messages.add('⏹️ 停止说话');
            break;
          case 'chat_end':
            _messages.add('✅ 回复结束');
            break;
        }
      });
    });

    // Prepare engine
    await DoubaoSpeech.prepare();

    // Get AEC model path
    final aecPath = await _getAecModelPath();

    // Initialize engine
    final success = await DoubaoSpeech.initializeEngine(
      appId: 'YOUR_APP_ID', // 替换为你的 App ID
      appKey: 'YOUR_APP_KEY', // 替换为你的 App Key
      token: 'YOUR_TOKEN', // 替换为你的 Token
      uid: 'flutter_user',
      enableAEC: true, // 开启回声消除
      aecModelPath: aecPath, // AEC 模型路径
      recorderType: 'RECORDER', // 使用设备麦克风
      enablePlayer: true, // 使用内置播放器
      enableDecoderCallback: true, // 启用解码器回调（用于保存音频）
    );

    if (success) {
      setState(() {
        _isReady = true;
      });
      _messages.add('✅ 引擎初始化成功');
    } else {
      _messages.add('❌ 引擎初始化失败');
    }
  }

  Future<void> _startConversation() async {
    // Start engine
    final started = await DoubaoSpeech.start();
    if (!started) {
      _messages.add('❌ 启动失败');
      return;
    }

    // Play greeting
    await DoubaoSpeech.sayHello('你好，我是豆包助手，有什么可以帮你的吗？');

    setState(() {
      _isTalking = true;
    });
  }

  Future<void> _stopConversation() async {
    await DoubaoSpeech.stop();
    setState(() {
      _isTalking = false;
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _messages.add('👤 我(文字): $text');
    _textController.clear();

    await DoubaoSpeech.sendTextQuery(text);
  }

  Future<void> _sendCommand(String command) async {
    _messages.add('🎯 指令: $command');
    await DoubaoSpeech.sendCommand(command);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('豆包语音助手'),
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            if (_isReady)
              IconButton(
                icon: Icon(_isTalking ? Icons.stop : Icons.mic),
                onPressed: _isTalking ? _stopConversation : _startConversation,
              ),
          ],
        ),
        body: Column(
          children: [
            // 消息列表
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _messages[_messages.length - 1 - index],
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                },
              ),
            ),

            // 指令按钮
            if (_isReady)
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCommandButton('开心', '用开心的语气说话'),
                    _buildCommandButton('温柔', '用温柔的语气说话'),
                    _buildCommandButton('粤语', '说粤语'),
                    _buildCommandButton('快一点', '语速快一点'),
                    _buildCommandButton('慢一点', '语速慢一点'),
                  ],
                ),
              ),

            // 文字输入
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: '输入文字提问...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandButton(String label, String command) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        onPressed: () => _sendCommand(command),
        child: Text(label),
      ),
    );
  }

  @override
  void dispose() {
    DoubaoSpeech.destroy();
    DoubaoSpeech.dispose();
    _textController.dispose();
    super.dispose();
  }

  // 获取 AEC 模型路径的函数
  Future<String> _getAecModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final aecFile = File('${appDir.path}/aec.model');

    // 如果文件不存在，从 assets 复制
    if (!await aecFile.exists()) {
      final byteData = await rootBundle.load('assets/aec.model');
      final buffer = byteData.buffer;
      await aecFile.writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }

    return aecFile.path;
  }
}
