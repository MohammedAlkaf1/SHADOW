// Shadow — ASR spike harness (standalone; NOT part of the app build).
//
// Purpose: answer the one question the product rests on — can Deepgram
// transcribe a REAL Saudi lecture (MSA + Hijazi/Saudi dialect + English
// technical terms, real room noise)? It streams a recorded audio file to
// Deepgram using the EXACT SAME transcription config the app uses
// (lib/custom_code/actions/transcription_mobile.dart), then measures word
// error rate against a human reference.
//
// This file lives under tool/ and is never compiled into the app.
//
// ─────────────────────────────────────────────────────────────────────────
// AUDIO FORMAT REQUIRED (must match the app's Deepgram config exactly):
//   Container   : WAV (RIFF)
//   Codec       : PCM signed 16-bit little-endian  (linear16)
//   Sample rate : 16000 Hz
//   Channels    : 1 (mono)
//
// Record however you like, then convert with ffmpeg:
//   ffmpeg -i lecture.m4a -ac 1 -ar 16000 -sample_fmt s16 -c:a pcm_s16le lecture16k.wav
// (The script also accepts headerless raw linear16 .pcm/.raw files.)
//
// ─────────────────────────────────────────────────────────────────────────
// USAGE
//
//   1) Set the Deepgram key (same key the app uses):
//        PowerShell:  $env:DEEPGRAM_API_KEY = "your_key"
//        Bash:        export DEEPGRAM_API_KEY=your_key
//
//   2) Transcribe (streams in real time; prints + writes <audio>.transcript.txt):
//        dart run tool/asr_spike/asr_spike.dart transcribe path/to/lecture16k.wav
//        dart run tool/asr_spike/asr_spike.dart transcribe lecture16k.wav --out out.txt --fast
//
//   3) Word error rate (after you write a reference transcript by hand):
//        dart run tool/asr_spike/asr_spike.dart wer reference.txt lecture16k.transcript.txt
//        dart run tool/asr_spike/asr_spike.dart wer reference.txt hyp.txt --raw
//
//   --fast  : stream at ~4x real time (quicker; slightly less representative)
//   --raw   : WER without Arabic normalization (diacritics/alef/ya left as-is)
//   --out F : where transcribe writes the transcript (default <audio>.transcript.txt)
// ─────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:web_socket_channel/io.dart';

// EXACT app config. Keep in sync with transcription_mobile.dart.
const String _dgHost = 'api.deepgram.com';
const String _dgPath = '/v1/listen';
const Map<String, String> _dgParams = {
  'encoding': 'linear16',
  'sample_rate': '16000',
  'channels': '1',
  'language': 'ar',
  'model': 'nova-3',
  'smart_format': 'true',
  'interim_results': 'true',
};

Future<int> main(List<String> argv) async {
  final args = <String>[];
  final flags = <String>{};
  String? outFlag;
  for (var i = 0; i < argv.length; i++) {
    final a = argv[i];
    if (a == '--fast' || a == '--raw') {
      flags.add(a);
    } else if (a == '--out') {
      outFlag = (i + 1 < argv.length) ? argv[++i] : null;
    } else if (a.startsWith('--out=')) {
      outFlag = a.substring('--out='.length);
    } else {
      args.add(a);
    }
  }

  if (args.isEmpty) {
    _printUsage();
    return 64;
  }

  switch (args.first) {
    case 'transcribe':
      if (args.length < 2) {
        stderr.writeln('Error: transcribe needs an audio file path.');
        _printUsage();
        return 64;
      }
      return _transcribe(args[1], outFlag, fast: flags.contains('--fast'));
    case 'wer':
      if (args.length < 3) {
        stderr.writeln('Error: wer needs <reference.txt> <hypothesis.txt>.');
        _printUsage();
        return 64;
      }
      return _wer(args[1], args[2], raw: flags.contains('--raw'));
    default:
      stderr.writeln('Unknown command: ${args.first}');
      _printUsage();
      return 64;
  }
}

void _printUsage() {
  stderr.writeln('''
Shadow ASR spike harness

  dart run tool/asr_spike/asr_spike.dart transcribe <audio.wav> [--out F] [--fast]
  dart run tool/asr_spike/asr_spike.dart wer <reference.txt> <hypothesis.txt> [--raw]

Audio must be WAV PCM s16le, 16000 Hz, mono (or headerless raw linear16).
Set DEEPGRAM_API_KEY in the environment before running transcribe.
''');
}

// ── Mode 1: transcribe ───────────────────────────────────────────────────

Future<int> _transcribe(String audioPath, String? outPath, {required bool fast}) async {
  final key = Platform.environment['DEEPGRAM_API_KEY'];
  if (key == null || key.trim().isEmpty) {
    stderr.writeln('Error: DEEPGRAM_API_KEY is not set in the environment.');
    return 78;
  }

  final file = File(audioPath);
  if (!file.existsSync()) {
    stderr.writeln('Error: audio file not found: $audioPath');
    return 66;
  }

  final bytes = await file.readAsBytes();
  final wav = _parseWav(bytes);
  final Uint8List pcm;
  int sampleRate;
  if (wav != null) {
    pcm = wav.pcm;
    sampleRate = wav.sampleRate;
    stdout.writeln('WAV: format=${wav.format} channels=${wav.channels} '
        'sampleRate=${wav.sampleRate} bits=${wav.bits} '
        'pcmBytes=${wav.pcm.length}');
    final problems = <String>[];
    if (wav.format != 1) problems.add('not PCM (format=${wav.format})');
    if (wav.channels != 1) problems.add('not mono (channels=${wav.channels})');
    if (wav.sampleRate != 16000) problems.add('not 16 kHz (${wav.sampleRate})');
    if (wav.bits != 16) problems.add('not 16-bit (${wav.bits})');
    if (problems.isNotEmpty) {
      stderr.writeln('⚠️  Audio does NOT match the app config: '
          '${problems.join(', ')}.');
      stderr.writeln('   Convert first:  ffmpeg -i in -ac 1 -ar 16000 '
          '-sample_fmt s16 -c:a pcm_s16le out.wav');
      stderr.writeln('   Results will not reflect real app behaviour. Aborting.');
      return 65;
    }
  } else {
    // Assume headerless raw linear16 @ 16 kHz mono.
    pcm = bytes;
    sampleRate = 16000;
    stdout.writeln('No WAV header found — assuming raw linear16 16 kHz mono '
        '(${pcm.length} bytes).');
  }

  final durationSec = pcm.length / (sampleRate * 2); // mono, 16-bit
  stdout.writeln('Audio duration: ${durationSec.toStringAsFixed(1)} s');

  final uri = Uri(
    scheme: 'wss',
    host: _dgHost,
    path: _dgPath,
    queryParameters: _dgParams,
  );
  stdout.writeln('Connecting: wss://$_dgHost$_dgPath?${_dgParams.entries.map((e) => '${e.key}=${e.value}').join('&')}');
  stdout.writeln('(Auth via Authorization header — the only deviation from the '
      'app, which puts the token in the URL. Does not affect transcription.)');

  // Authorization header instead of the app's URL token — keeps the key out
  // of any URL logging. Transcription params are identical.
  final channel = IOWebSocketChannel.connect(
    uri,
    headers: {'Authorization': 'Token $key'},
  );

  final finals = <String>[];
  String lastInterim = '';
  final done = Completer<void>();

  channel.stream.listen(
    (message) {
      try {
        final data = jsonDecode(message as String) as Map<String, dynamic>;
        if (data.containsKey('message') || data['type'] == 'Error') {
          stderr.writeln('Deepgram server message: $data');
          return;
        }
        final alts = data['channel']?['alternatives'] as List?;
        final transcript = alts?.isNotEmpty == true
            ? alts!.first['transcript'] as String?
            : null;
        final isFinal = data['is_final'] as bool? ?? false;
        if (transcript == null || transcript.isEmpty) return;
        if (isFinal) {
          finals.add(transcript);
          lastInterim = '';
          stdout.write('\r${' ' * 80}\r'); // clear interim line
          stdout.writeln('· $transcript');
        } else {
          lastInterim = transcript;
          stdout.write('\r… $transcript');
        }
      } catch (e) {
        stderr.writeln('Parse error: $e');
      }
    },
    onDone: () {
      if (!done.isCompleted) done.complete();
    },
    onError: (Object e) {
      stderr.writeln('WebSocket error: $e');
      if (!done.isCompleted) done.complete();
    },
  );

  // Stream the PCM in ~100 ms chunks, paced to real time (or 4x with --fast).
  const chunkMs = 100;
  final chunkBytes = (sampleRate * 2 * chunkMs) ~/ 1000; // mono, 16-bit
  final perChunkDelay = Duration(milliseconds: fast ? chunkMs ~/ 4 : chunkMs);
  stdout.writeln('Streaming ${fast ? '~4x real time' : 'in real time'} '
      '(${(durationSec / (fast ? 4 : 1)).toStringAsFixed(0)} s to send)…\n');

  for (var offset = 0; offset < pcm.length; offset += chunkBytes) {
    final end = (offset + chunkBytes < pcm.length) ? offset + chunkBytes : pcm.length;
    channel.sink.add(Uint8List.sublistView(pcm, offset, end));
    await Future<void>.delayed(perChunkDelay);
  }

  // Tell Deepgram we're done so it flushes remaining finals, then wait.
  channel.sink.add(jsonEncode({'type': 'CloseStream'}));
  await done.future.timeout(const Duration(seconds: 20), onTimeout: () {
    stderr.writeln('\n(Timed out waiting for final flush — using what arrived.)');
  });
  await channel.sink.close();

  if (lastInterim.isNotEmpty) finals.add(lastInterim); // trailing partial
  final full = finals.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  final outFile = outPath ?? '$audioPath.transcript.txt';
  await File(outFile).writeAsString('$full\n');

  stdout.writeln('\n${'=' * 72}');
  stdout.writeln('TRANSCRIPT (${full.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words):\n');
  stdout.writeln(full.isEmpty ? '(empty — check the key, audio, and network)' : full);
  stdout.writeln('\nWritten to: $outFile');
  stdout.writeln('Next: write a human reference transcript, then run:');
  stdout.writeln('  dart run tool/asr_spike/asr_spike.dart wer reference.txt $outFile');
  return full.isEmpty ? 1 : 0;
}

// ── Mode 2: word error rate ──────────────────────────────────────────────

Future<int> _wer(String refPath, String hypPath, {required bool raw}) async {
  final refFile = File(refPath), hypFile = File(hypPath);
  if (!refFile.existsSync()) {
    stderr.writeln('Error: reference not found: $refPath');
    return 66;
  }
  if (!hypFile.existsSync()) {
    stderr.writeln('Error: hypothesis not found: $hypPath');
    return 66;
  }

  final ref = _tokenize(await refFile.readAsString(), normalize: !raw);
  final hyp = _tokenize(await hypFile.readAsString(), normalize: !raw);

  if (ref.isEmpty) {
    stderr.writeln('Error: reference has no words.');
    return 65;
  }

  final result = _align(ref, hyp);
  final wer = (result.subs + result.dels + result.ins) / ref.length;

  stdout.writeln('=' * 72);
  stdout.writeln('WORD ERROR RATE');
  stdout.writeln('  Normalization : ${raw ? 'OFF (--raw)' : 'ON (diacritics/tatweel removed, alef+ya unified, lowercased)'}');
  stdout.writeln('  Reference words (N) : ${ref.length}');
  stdout.writeln('  Hypothesis words    : ${hyp.length}');
  stdout.writeln('  Substitutions (S)   : ${result.subs}');
  stdout.writeln('  Deletions/missed (D): ${result.dels}');
  stdout.writeln('  Insertions (I)      : ${result.ins}');
  stdout.writeln('  Correct             : ${result.hits}');
  stdout.writeln('');
  stdout.writeln('  WER = (S+D+I)/N = ${(wer * 100).toStringAsFixed(1)} %'
      '   Accuracy ≈ ${((1 - wer) * 100).clamp(0, 100).toStringAsFixed(1)} %');
  stdout.writeln('=' * 72);

  final missed = result.ops.where((o) => o.type == _Op.del).map((o) => o.ref!).toList();
  final subd = result.ops.where((o) => o.type == _Op.sub).toList();
  final inserted = result.ops.where((o) => o.type == _Op.ins).map((o) => o.hyp!).toList();

  if (missed.isNotEmpty) {
    stdout.writeln('\nMISSED (in reference, not recognised) — ${missed.length}:');
    stdout.writeln('  ${missed.join('  ')}');
  }
  if (subd.isNotEmpty) {
    stdout.writeln('\nSUBSTITUTED (reference → heard) — ${subd.length}:');
    for (final o in subd) {
      stdout.writeln('  ${o.ref}  →  ${o.hyp}');
    }
  }
  if (inserted.isNotEmpty) {
    stdout.writeln('\nINSERTED (heard, not in reference) — ${inserted.length}:');
    stdout.writeln('  ${inserted.join('  ')}');
  }

  stdout.writeln('\nALIGNED VIEW  (✓ correct, ✗ wrong, - missing/extra):');
  final sb = StringBuffer();
  for (final o in result.ops) {
    switch (o.type) {
      case _Op.hit:
        sb.write('${o.ref} ');
      case _Op.sub:
        sb.write('[✗ ${o.ref}→${o.hyp}] ');
      case _Op.del:
        sb.write('[- ${o.ref}] ');
      case _Op.ins:
        sb.write('[+ ${o.hyp}] ');
    }
  }
  stdout.writeln(sb.toString().trim());
  return 0;
}

// ── Text handling ────────────────────────────────────────────────────────

final _punct = RegExp(r'''[.,;:!?()\[\]{}"«»…\-—_/\\%،؛؟“”‘’'`]''');

List<String> _tokenize(String text, {required bool normalize}) {
  var t = text.replaceAll(_punct, ' ');
  final words = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final out = <String>[];
  for (var w in words) {
    if (normalize) w = _normalizeArabic(w);
    if (w.isNotEmpty) out.add(w);
  }
  return out;
}

String _normalizeArabic(String s) {
  // Remove Arabic diacritics (tashkeel) and superscript alef.
  s = s.replaceAll(RegExp('[ؐ-ًؚ-ٰٟ]'), '');
  // Remove tatweel (kashida).
  s = s.replaceAll('ـ', '');
  // Unify alef variants (أ إ آ ٱ) → ا.
  s = s.replaceAll(RegExp('[آأإٱ]'), 'ا');
  // Alef maqsura ى → ya ي.
  s = s.replaceAll('ى', 'ي');
  // Ta marbuta ة → ha ه (common WER normalization; document as a choice).
  s = s.replaceAll('ة', 'ه');
  // Lowercase Latin (English technical terms).
  return s.toLowerCase();
}

// ── Word-level alignment (Levenshtein with backtrace) ────────────────────

enum _Op { hit, sub, del, ins }

class _Edit {
  final _Op type;
  final String? ref;
  final String? hyp;
  _Edit(this.type, this.ref, this.hyp);
}

class _AlignResult {
  final int subs, dels, ins, hits;
  final List<_Edit> ops;
  _AlignResult(this.subs, this.dels, this.ins, this.hits, this.ops);
}

_AlignResult _align(List<String> ref, List<String> hyp) {
  final n = ref.length, m = hyp.length;
  // d[i][j] = min edits to turn ref[0..i) into hyp[0..j).
  final d = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = 0; i <= n; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= m; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      final cost = ref[i - 1] == hyp[j - 1] ? 0 : 1;
      final sub = d[i - 1][j - 1] + cost;
      final del = d[i - 1][j] + 1;
      final insv = d[i][j - 1] + 1;
      d[i][j] = sub < del ? (sub < insv ? sub : insv) : (del < insv ? del : insv);
    }
  }

  // Backtrace.
  var i = n, j = m;
  var subs = 0, dels = 0, ins = 0, hits = 0;
  final ops = <_Edit>[];
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0) {
      final cost = ref[i - 1] == hyp[j - 1] ? 0 : 1;
      if (d[i][j] == d[i - 1][j - 1] + cost) {
        if (cost == 0) {
          ops.add(_Edit(_Op.hit, ref[i - 1], hyp[j - 1]));
          hits++;
        } else {
          ops.add(_Edit(_Op.sub, ref[i - 1], hyp[j - 1]));
          subs++;
        }
        i--;
        j--;
        continue;
      }
    }
    if (i > 0 && d[i][j] == d[i - 1][j] + 1) {
      ops.add(_Edit(_Op.del, ref[i - 1], null)); // in ref, missing from hyp
      dels++;
      i--;
    } else {
      ops.add(_Edit(_Op.ins, null, hyp[j - 1])); // extra in hyp
      ins++;
      j--;
    }
  }
  return _AlignResult(subs, dels, ins, hits, ops.reversed.toList());
}

// ── Minimal WAV parser ───────────────────────────────────────────────────

class _WavInfo {
  final int format, channels, sampleRate, bits;
  final Uint8List pcm;
  _WavInfo(this.format, this.channels, this.sampleRate, this.bits, this.pcm);
}

_WavInfo? _parseWav(Uint8List b) {
  if (b.length < 44) return null;
  bool tag(int o, String s) {
    for (var k = 0; k < s.length; k++) {
      if (b[o + k] != s.codeUnitAt(k)) return false;
    }
    return true;
  }

  if (!tag(0, 'RIFF') || !tag(8, 'WAVE')) return null;
  final bd = ByteData.sublistView(b);
  var off = 12;
  int format = 0, channels = 0, sampleRate = 0, bits = 0;
  Uint8List? data;
  while (off + 8 <= b.length) {
    final id = String.fromCharCodes(b.sublist(off, off + 4));
    final size = bd.getUint32(off + 4, Endian.little);
    final body = off + 8;
    if (id == 'fmt ' && body + 16 <= b.length) {
      format = bd.getUint16(body, Endian.little);
      channels = bd.getUint16(body + 2, Endian.little);
      sampleRate = bd.getUint32(body + 4, Endian.little);
      bits = bd.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      final endPos = (body + size <= b.length) ? body + size : b.length;
      data = Uint8List.sublistView(b, body, endPos);
    }
    off = body + size + (size.isOdd ? 1 : 0);
  }
  if (data == null) return null;
  return _WavInfo(format, channels, sampleRate, bits, data);
}
