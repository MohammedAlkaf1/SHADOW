// Pure, testable logic for Deepgram streaming transcription — extracted from
// the live socket handlers (transcription_mobile.dart, listen_for_voice_command.dart)
// so it can be unit-tested without a mic or network.
//
// Two concerns:
//   1. parseDeepgramMessage — turn a raw Deepgram JSON frame into a result.
//   2. TranscriptAccumulator — combine interim/final results into display text.

import 'dart:convert';
import 'package:collection/collection.dart';

/// One parsed Deepgram frame.
class DeepgramResult {
  const DeepgramResult({
    this.transcript,
    this.isFinal = false,
    this.serverMessage,
  });

  /// The recognised text for this frame (may be null or empty).
  final String? transcript;

  /// Whether Deepgram marked this as a finalised segment.
  final bool isFinal;

  /// A server/status/error frame (e.g. auth or rate-limit messages) that has a
  /// top-level "message" field instead of a transcript. Null for normal frames.
  final String? serverMessage;

  bool get hasText => transcript != null && transcript!.isNotEmpty;
}

/// Parses a raw Deepgram WebSocket text frame. Returns null if the frame is not
/// valid JSON (the live code ignores such frames). Mirrors the field access the
/// socket handlers previously did inline.
DeepgramResult? parseDeepgramMessage(String message) {
  final Object? decoded;
  try {
    decoded = jsonDecode(message);
  } catch (_) {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;

  if (decoded.containsKey('message')) {
    return DeepgramResult(serverMessage: decoded['message']?.toString());
  }

  final alternatives = decoded['channel']?['alternatives'] as List?;
  final transcript =
      alternatives?.firstOrNull?['transcript'] as String?;
  final isFinal = decoded['is_final'] as bool? ?? false;
  return DeepgramResult(transcript: transcript, isFinal: isFinal);
}

/// Accumulates interim and final results into the text shown to the user.
///
/// Behaviour (identical to the previous inline logic):
///   - final results are appended to a committed buffer (with a trailing space);
///   - interim results are shown appended to the committed buffer but NOT kept;
///   - empty/blank results leave the display unchanged.
class TranscriptAccumulator {
  final StringBuffer _committed = StringBuffer();

  /// The finalised text so far, trimmed.
  String get committed => _committed.toString().trim();

  /// Applies [transcript] with its [isFinal] flag and returns the text that
  /// should now be displayed.
  String add(String? transcript, bool isFinal) {
    if (transcript == null || transcript.isEmpty) return committed;
    if (isFinal) {
      _committed.write(transcript);
      _committed.write(' ');
      return _committed.toString().trim();
    }
    return '${_committed.toString()}$transcript'.trim();
  }

  void clear() => _committed.clear();
}
