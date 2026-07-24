// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter/foundation.dart';
import 'transcription_platform.dart';

Future<void> startRealtimeTranscription() async {
  const key = String.fromEnvironment('DEEPGRAM_API_KEY');
  debugPrint('🔑 Key exists: ${key.isNotEmpty}');

  if (FFAppState().isRecording) {
    debugPrint('⏹️ Stop requested');
    stopPlatformTranscription();
    FFAppState().update(() {
      FFAppState().isRecording = false;
    });
  } else {
    debugPrint('▶️ Start requested');
    FFAppState().update(() {
      FFAppState().isRecording = true;
    });

    await startPlatformTranscription((String text) {
      debugPrint('💾 State updated: $text');
      FFAppState().update(() {
        FFAppState().liveText = text;
      });
    });
  }
}
