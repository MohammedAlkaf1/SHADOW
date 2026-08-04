// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_tts/flutter_tts.dart';

import '/services/app_prefs.dart';

FlutterTts? _tts;
bool _ttsConfigured = false;

/// Speaks [text] and does not return until the utterance finishes, is
/// interrupted by [stopArabicSpeaking], or errors.
///
/// Without `awaitSpeakCompletion(true)`, flutter_tts' speak() future
/// resolves as soon as the platform *starts* the utterance (fire-and-
/// forget), not when it finishes. Callers that do
/// `isSpeaking = true; await speakArabicText(...); isSpeaking = false;`
/// would then flip back to the "not speaking" state within milliseconds
/// of playback starting — long before the audio actually stops — so a
/// second tap on the same button re-enters the "start speaking" branch
/// instead of the "stop" branch and just restarts the utterance,
/// making it appear impossible to stop from the UI.
Future<void> speakArabicText(String text) async {
  _tts ??= FlutterTts();
  if (!_ttsConfigured) {
    await _tts!.awaitSpeakCompletion(true);
    _ttsConfigured = true;
  }
  await _tts!.stop();
  await _tts!.setLanguage(
      AppPrefs.currentAppLanguage == 'en' ? 'en-US' : 'ar-SA');
  await _tts!.setSpeechRate(0.5);
  await _tts!.setPitch(1.0);
  await _tts!.speak(text);
}

Future<void> stopArabicSpeaking() async {
  await _tts?.stop();
}
