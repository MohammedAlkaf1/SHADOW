// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';

import '/services/deepgram_parser.dart';
import '/student/student_profile.dart';

const String _cmdApiKey = String.fromEnvironment('DEEPGRAM_API_KEY');

// Listening window before giving up and using whatever was captured so far —
// longer for higher support levels so students who need more time to speak
// (or who repeat themselves) aren't cut off early. Sourced from the
// platform's adaptation directives when a real session is loaded (see
// StudentProfile.physicalModeListeningDurationSeconds), else the same local
// enum-based values as before.
Duration _listeningTimeoutFor(StudentProfile profile) =>
    Duration(seconds: profile.physicalModeListeningDurationSeconds);

Future<String> listenForVoiceCommand() async {
  final recorder = AudioRecorder();
  final hasPermission = await recorder.hasPermission();
  if (!hasPermission) return '';

  final completer = Completer<String>();
  String lastResult = '';

  final uri = Uri.parse(
    'wss://api.deepgram.com/v1/listen'
    '?encoding=linear16&sample_rate=16000&channels=1'
    '&language=ar&model=nova-3&smart_format=true&interim_results=true',
  );

  // Auth via the Authorization header (Deepgram's supported method); the
  // ?token= query parameter is not honoured and returns 401.
  final channel = IOWebSocketChannel.connect(
    uri,
    headers: {'Authorization': 'Token $_cmdApiKey'},
  );

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
      sampleRate: 16000,
      numChannels: 1,
    ),
  );

  stream.listen((data) => channel.sink.add(data));

  // Timeout: stop after the level-appropriate listening window regardless.
  Future.delayed(_listeningTimeoutFor(StudentProfile.current), () async {
    if (!completer.isCompleted) {
      await recorder.stop();
      channel.sink.close();
      completer.complete(lastResult);
    }
  });

  final result = await completer.future;
  await recorder.stop();
  recorder.dispose();
  try {
    channel.sink.close();
  } catch (_) {}
  return result;
}
