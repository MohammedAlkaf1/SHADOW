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

const String _cmdApiKey = String.fromEnvironment('DEEPGRAM_API_KEY');

Future<String> listenForVoiceCommand() async {
  final recorder = AudioRecorder();
  final hasPermission = await recorder.hasPermission();
  if (!hasPermission) return '';

  final completer = Completer<String>();
  String lastResult = '';

  final uri = Uri.parse(
    'wss://api.deepgram.com/v1/listen'
    '?encoding=linear16&sample_rate=16000&channels=1'
    '&language=ar&model=nova-2&smart_format=true&interim_results=true',
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

  // Timeout: stop after 10 seconds regardless
  Future.delayed(const Duration(seconds: 10), () async {
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
