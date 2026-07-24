// Mobile implementation using Deepgram WebSocket + record package.
// Only compiled when targeting Android/iOS (dart.library.io is available).

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';

import '/services/deepgram_parser.dart';

const String _apiKey = String.fromEnvironment('DEEPGRAM_API_KEY');

AudioRecorder? _recorder;
IOWebSocketChannel? _channel;
bool _shouldRestart = false;
void Function(String)? _onTranscript;
final TranscriptAccumulator _accumulator = TranscriptAccumulator();

Future<void> startPlatformTranscription(
    void Function(String text) onTranscript) async {
  _onTranscript = onTranscript;
  _shouldRestart = true;
  _accumulator.clear();

  debugPrint('🔑 Key exists: ${_apiKey.isNotEmpty}');
  if (_apiKey.isNotEmpty) {
    debugPrint('🔑 Key suffix: ...${_apiKey.substring(_apiKey.length.clamp(4, _apiKey.length) - 4)}');
  }

  if (_apiKey.isEmpty) {
    debugPrint('❌ Error: DEEPGRAM_API_KEY is empty — pass --dart-define=DEEPGRAM_API_KEY=...');
    onTranscript('⚠️ مفتاح Deepgram غير موجود');
    return;
  }

  await _startDeepgramStream();
}

Future<void> _startDeepgramStream() async {
  if (!_shouldRestart) return;

  // Clean up previous session
  await _recorder?.stop();
  _recorder?.dispose();
  _recorder = null;
  try { _channel?.sink.close(); } catch (_) {}
  _channel = null;

  _recorder = AudioRecorder();
  final hasPermission = await _recorder!.hasPermission();
  debugPrint('🎤 Mic permission: $hasPermission');
  if (!hasPermission) {
    _onTranscript?.call('يرجى منح إذن الميكروفون');
    return;
  }

  final uri = Uri.parse(
    'wss://api.deepgram.com/v1/listen'
    '?encoding=linear16&sample_rate=16000&channels=1'
    '&language=ar&model=nova-2&smart_format=true&interim_results=true'
    '&token=$_apiKey',
  );

  debugPrint('🔌 WebSocket connecting to: ${uri.host}');
  _channel = IOWebSocketChannel.connect(uri);
  debugPrint('✅ WebSocket connected (channel created)');

  _channel!.stream.listen(
    (message) {
      debugPrint('📨 Message: $message');
      final result = parseDeepgramMessage(message as String);
      if (result == null) {
        debugPrint('❌ Unparseable frame');
        return;
      }
      if (result.serverMessage != null) {
        debugPrint('⚠️ Deepgram server msg: ${result.serverMessage}');
        return;
      }
      debugPrint(
          '📝 Transcript: "${result.transcript}" | final=${result.isFinal}');
      if (result.hasText) {
        final display = _accumulator.add(result.transcript, result.isFinal);
        debugPrint('💾 State updated: $display');
        _onTranscript?.call(display);
      }
    },
    onDone: () {
      debugPrint('🔌 WebSocket closed. shouldRestart=$_shouldRestart');
      if (_shouldRestart) {
        Future.delayed(
            const Duration(milliseconds: 500), _startDeepgramStream);
      }
    },
    onError: (error) {
      debugPrint('❌ Error: $error');
      if (_shouldRestart) {
        Future.delayed(
            const Duration(milliseconds: 500), _startDeepgramStream);
      }
    },
  );

  debugPrint('🎤 Recording started');
  try {
    final stream = await _recorder!.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    debugPrint('🎤 Audio streaming active — sending to Deepgram');

    stream.listen(
      (data) {
        if (_shouldRestart) _channel?.sink.add(data);
      },
      onError: (e) => debugPrint('❌ Audio stream error: $e'),
    );
  } catch (e, stack) {
    debugPrint('❌ startStream CRASH: $e');
    debugPrint('❌ Stack: $stack');
    // Retry with AAC fallback encoder
    debugPrint('🔄 Retrying with aacLc encoder...');
    try {
      final stream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 64000,
        ),
      );
      debugPrint('🎤 AAC fallback streaming active');
      stream.listen(
        (data) {
          if (_shouldRestart) _channel?.sink.add(data);
        },
        onError: (e) => debugPrint('❌ AAC stream error: $e'),
      );
    } catch (e2) {
      debugPrint('❌ AAC fallback also failed: $e2');
      _onTranscript?.call('خطأ في بدء التسجيل: $e2');
    }
  }
}

void stopPlatformTranscription() {
  debugPrint('⏹️ Stopping transcription');
  _shouldRestart = false;
  _recorder?.stop();
  _recorder?.dispose();
  _recorder = null;
  try { _channel?.sink.close(); } catch (_) {}
  _channel = null;
  _onTranscript = null;
  _accumulator.clear();
}

bool get isPlatformSupported => true;
