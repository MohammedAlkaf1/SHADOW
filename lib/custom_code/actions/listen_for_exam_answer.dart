// Voice-driven exam-taking (physical/motor-impairment mode): captures one
// short spoken utterance (an answer choice, or a yes/"إعادة" confirmation),
// transcribing it live via the same Deepgram WebSocket pattern as
// listen_for_voice_command.dart, while ALSO buffering the raw PCM so the
// caller gets back the actual audio clip (as a WAV file) to upload as the
// platform's voiceConfirmationAudio — that field is genuinely optional
// server-side, but the exam-taking spec asks for it, so the audio is worth
// capturing whenever this is used for the confirmation step specifically.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';

import '/services/app_prefs.dart';
import '/services/deepgram_parser.dart';
import '/student/student_profile.dart';

const String _examApiKey = String.fromEnvironment('DEEPGRAM_API_KEY');

class ExamAnswerCapture {
  const ExamAnswerCapture({required this.transcript, required this.audioWav});

  final String transcript;

  /// Raw-PCM-wrapped-in-WAV recording of this capture window — always
  /// non-null (may be a near-empty/silent clip if nothing was said), so
  /// callers can upload it unconditionally.
  final Uint8List audioWav;
}

/// 44-byte RIFF/WAV header for 16-bit mono PCM — same minimal container
/// shape as the platform's own pcmToWav (src/app/api/tts/generate/route.ts),
/// so a clip recorded here and one synthesized there are byte-for-byte
/// compatible if ever compared.
Uint8List _pcmToWav(Uint8List pcm, int sampleRateHz) {
  const numChannels = 1;
  const bitsPerSample = 16;
  final byteRate = sampleRateHz * numChannels * (bitsPerSample ~/ 8);
  const blockAlign = numChannels * (bitsPerSample ~/ 8);
  final header = ByteData(44);

  void writeAscii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRateHz, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  writeAscii(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);

  return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm]);
}

/// Listens for one short utterance (a spoken option name, or a yes/"إعادة"
/// reply), returning both the recognized text and the recorded clip. Stops
/// on the first final Deepgram result, or after the level-appropriate
/// listening window (same duration source as listenForVoiceCommand), or
/// after [maxDuration] if explicitly capped tighter for this step.
Future<ExamAnswerCapture> listenForExamAnswer({Duration? maxDuration}) async {
  const sampleRate = 16000;
  final recorder = AudioRecorder();
  final hasPermission = await recorder.hasPermission();
  if (!hasPermission) {
    return ExamAnswerCapture(transcript: '', audioWav: _pcmToWav(Uint8List(0), sampleRate));
  }

  final completer = Completer<String>();
  String lastResult = '';
  final pcmChunks = <int>[];

  final deepgramLanguage = AppPrefs.deepgramLanguageCode;
  final uri = Uri.parse(
    'wss://api.deepgram.com/v1/listen'
    '?encoding=linear16&sample_rate=$sampleRate&channels=1'
    '&language=$deepgramLanguage&model=nova-3&smart_format=true&interim_results=true',
  );

  debugPrint('⏱️ T6 deepgram_connect_start @ ${DateTime.now().millisecondsSinceEpoch}');
  final channel = IOWebSocketChannel.connect(
    uri,
    headers: {'Authorization': 'Token $_examApiKey'},
  );
  // IOWebSocketChannel.connect() doesn't expose a distinct "handshake done"
  // callback — this is the earliest point after the call returns, so it's
  // an upper bound on "ready", not a guaranteed exact one.
  debugPrint('⏱️ T7 deepgram_connect_returned @ ${DateTime.now().millisecondsSinceEpoch}');

  channel.stream.listen(
    (message) {
      final result = parseDeepgramMessage(message as String);
      if (result == null || !result.hasText) return;
      lastResult = result.transcript!;
      if (result.isFinal && !completer.isCompleted) {
        completer.complete(result.transcript);
      }
    },
    onDone: () {
      if (!completer.isCompleted) completer.complete(lastResult);
    },
    onError: (_) {
      if (!completer.isCompleted) completer.complete(lastResult);
    },
  );

  final stream = await recorder.startStream(
    const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
    ),
  );
  debugPrint('⏱️ T8 mic_stream_started @ ${DateTime.now().millisecondsSinceEpoch}');
  var firstChunkLogged = false;
  stream.listen((data) {
    if (!firstChunkLogged) {
      firstChunkLogged = true;
      debugPrint('⏱️ T8b mic_first_chunk @ ${DateTime.now().millisecondsSinceEpoch}');
    }
    pcmChunks.addAll(data);
    if (!completer.isCompleted) channel.sink.add(data);
  });

  final timeout = maxDuration ?? Duration(seconds: StudentProfile.current.physicalModeListeningDurationSeconds);
  Future.delayed(timeout, () {
    if (!completer.isCompleted) completer.complete(lastResult);
  });

  final transcript = await completer.future;
  debugPrint('🔊 listenForExamAnswer: transcript="$transcript" pcmChunks.length=${pcmChunks.length} bytes '
      '(before recorder.stop())');
  await recorder.stop();
  recorder.dispose();
  try {
    channel.sink.close();
  } catch (_) {}

  final wav = _pcmToWav(Uint8List.fromList(pcmChunks), sampleRate);
  debugPrint('🔊 listenForExamAnswer: returning audioWav.length=${wav.length} bytes '
      '(44-byte header + ${pcmChunks.length} PCM bytes)');
  return ExamAnswerCapture(transcript: transcript, audioWav: wav);
}
