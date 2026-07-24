import 'package:flutter_test/flutter_test.dart';
import 'package:shadow/services/deepgram_parser.dart';

void main() {
  group('parseDeepgramMessage', () {
    String frame({String? transcript, bool isFinal = false}) {
      final t = transcript == null ? 'null' : '"$transcript"';
      return '{"is_final":$isFinal,"channel":{"alternatives":[{"transcript":$t}]}}';
    }

    test('parses an interim result', () {
      final r = parseDeepgramMessage(frame(transcript: 'مرحبا', isFinal: false))!;
      expect(r.transcript, 'مرحبا');
      expect(r.isFinal, isFalse);
      expect(r.hasText, isTrue);
      expect(r.serverMessage, isNull);
    });

    test('parses a final result', () {
      final r = parseDeepgramMessage(frame(transcript: 'مرحبا بكم', isFinal: true))!;
      expect(r.transcript, 'مرحبا بكم');
      expect(r.isFinal, isTrue);
    });

    test('empty transcript => hasText false', () {
      final r = parseDeepgramMessage(frame(transcript: '', isFinal: true))!;
      expect(r.hasText, isFalse);
    });

    test('missing is_final defaults to false', () {
      final r = parseDeepgramMessage(
          '{"channel":{"alternatives":[{"transcript":"x"}]}}')!;
      expect(r.isFinal, isFalse);
    });

    test('server/error frame is surfaced, not treated as transcript', () {
      // This is what Deepgram sends on problems (e.g. auth): a top-level message.
      final r = parseDeepgramMessage('{"type":"Error","message":"Unauthorized"}')!;
      expect(r.serverMessage, 'Unauthorized');
      expect(r.hasText, isFalse);
    });

    test('no alternatives (metadata frame) => null transcript', () {
      final r = parseDeepgramMessage('{"is_final":true,"channel":{"alternatives":[]}}')!;
      expect(r.transcript, isNull);
      expect(r.hasText, isFalse);
    });

    test('invalid JSON returns null (ignored by caller)', () {
      expect(parseDeepgramMessage('not json'), isNull);
      expect(parseDeepgramMessage('[1,2,3]'), isNull);
    });
  });

  group('TranscriptAccumulator', () {
    test('interim results are shown but not committed', () {
      final acc = TranscriptAccumulator();
      expect(acc.add('مرحبا', false), 'مرحبا');
      // A different interim replaces the previous one (nothing committed yet).
      expect(acc.add('مرحبا بكم', false), 'مرحبا بكم');
      expect(acc.committed, '');
    });

    test('final results accumulate across segments', () {
      final acc = TranscriptAccumulator();
      expect(acc.add('مرحبا', true), 'مرحبا');
      expect(acc.add('بكم', true), 'مرحبا بكم');
      expect(acc.committed, 'مرحبا بكم');
    });

    test('interim appends to committed text without keeping it', () {
      final acc = TranscriptAccumulator();
      acc.add('السلام', true); // committed = "السلام"
      // interim "عليكم" is shown appended...
      expect(acc.add('عليكم', false), 'السلام عليكم');
      // ...but not committed, so a later final is clean.
      expect(acc.committed, 'السلام');
      expect(acc.add('عليكم', true), 'السلام عليكم');
      expect(acc.committed, 'السلام عليكم');
    });

    test('empty/null transcript leaves display unchanged', () {
      final acc = TranscriptAccumulator();
      acc.add('مرحبا', true);
      expect(acc.add('', false), 'مرحبا');
      expect(acc.add(null, true), 'مرحبا');
    });

    test('clear resets committed text', () {
      final acc = TranscriptAccumulator();
      acc.add('نص', true);
      acc.clear();
      expect(acc.committed, '');
      expect(acc.add('جديد', true), 'جديد');
    });
  });
}
