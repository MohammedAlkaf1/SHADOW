// Mobile implementation using Deepgram WebSocket + record package.
// Only compiled when targeting Android/iOS (dart.library.io is available).

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';

import '/services/app_prefs.dart';
import '/services/deepgram_parser.dart';

const String _apiKey = String.fromEnvironment('DEEPGRAM_API_KEY');

AudioRecorder? _recorder;
IOWebSocketChannel? _channel;
bool _shouldRestart = false;
void Function(String)? _onTranscript;
final TranscriptAccumulator _accumulator = TranscriptAccumulator();
int _sentChunkCount = 0;

/// Forwards a captured audio chunk to Deepgram and logs the first chunk (and
/// every 50th) so we can confirm audio capture actually started ("Sent bytes").
void _forwardAudio(Uint8List data) {
  if (!_shouldRestart) return;
  _channel?.sink.add(data);
  _sentChunkCount++;
  if (_sentChunkCount == 1 || _sentChunkCount % 50 == 0) {
    debugPrint('🎙️ Sent bytes: chunk #$_sentChunkCount (${data.length} bytes)');
  }
}

Future<void> startPlatformTranscription(
    void Function(String text) onTranscript) async {
  _onTranscript = onTranscript;
  _shouldRestart = true;
  _accumulator.clear();
  _sentChunkCount = 0;

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

  // Sourced from the student's app-language choice (Settings screen) —
  // 'ar' or 'en-US' — not hardcoded. See AppPrefs.deepgramLanguageCode.
  final deepgramLanguage = AppPrefs.deepgramLanguageCode;
  debugPrint('🌐 Deepgram language=$deepgramLanguage '
      '(app language=${AppPrefs.currentAppLanguage})');

  final uri = Uri.parse(
    'wss://api.deepgram.com/v1/listen'
    '?encoding=linear16&sample_rate=16000&channels=1'
    // model=nova-3: nova-2 rejected language=ar with HTTP 400 (Bad Request).
    // nova-3 is Deepgram's current multilingual model. If "ar" is still
    // rejected, the onError/onDone logs below print Deepgram's exact reason —
    // then try language=multi (also suits Arabic+English code-switching).
    '&language=$deepgramLanguage&model=nova-3&smart_format=true&interim_results=true',
  );

  debugPrint('🔌 WebSocket connecting to: ${uri.host}');
  // Auth via the Authorization header (Deepgram's supported method). The
  // previous ?token= query parameter is NOT honoured by /v1/listen and caused
  // a 401 at the handshake.
  _channel = IOWebSocketChannel.connect(
    uri,
    headers: {'Authorization': 'Token $_apiKey'},
  );
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
      // Full trace of the extracted value (separate from the raw frame) so we
      // can tell empty transcripts apart from a wiring break.
      debugPrint('📝 extracted="${result.transcript}" '
          'final=${result.isFinal} hasText=${result.hasText}');
      if (result.hasText) {
        final display = _accumulator.add(result.transcript, result.isFinal);
        debugPrint('➡️ display="$display" onTranscriptWired=${_onTranscript != null}');
        _onTranscript?.call(display);
      } else {
        debugPrint('⚪ empty transcript (final=${result.isFinal}) — nothing sent to UI');
      }
    },
    onDone: () {
      // On a bad request Deepgram closes with a code + reason (e.g. 1008 and a
      // message naming the rejected param) — log it so failures are diagnosable.
      debugPrint('🔌 WebSocket closed. code=${_channel?.closeCode} '
          'reason="${_channel?.closeReason}" shouldRestart=$_shouldRestart');
      if (_shouldRestart) {
        Future.delayed(
            const Duration(milliseconds: 500), _startDeepgramStream);
      }
    },
    onError: (error) {
      // A handshake rejection (e.g. HTTP 400) surfaces here with the status/
      // reason, showing exactly which query param Deepgram rejected.
      debugPrint('❌ Deepgram WS error: $error');
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
        _forwardAudio(data);
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
          _forwardAudio(data);
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
