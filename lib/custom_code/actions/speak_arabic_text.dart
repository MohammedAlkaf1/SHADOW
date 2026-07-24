// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_tts/flutter_tts.dart';

FlutterTts? _tts;

Future<void> speakArabicText(String text) async {
  _tts ??= FlutterTts();
  await _tts!.stop();
  await _tts!.setLanguage('ar-SA');
  await _tts!.setSpeechRate(0.5);
  await _tts!.setPitch(1.0);
  await _tts!.speak(text);
}

Future<void> stopArabicSpeaking() async {
  await _tts?.stop();
}
