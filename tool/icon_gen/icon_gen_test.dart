// Generates the Shadow launcher-icon PNGs using Flutter's own engine so the
// Arabic "ش" renders correctly with the Tajawal font. Run with:
//   flutter test tool/icon_gen/icon_gen_test.dart
// Outputs:
//   assets/icon/ic_launcher.png            (1024, navy full-bleed + ش)
//   assets/icon/ic_launcher_foreground.png (1024, transparent + ش, adaptive-safe)
// These feed flutter_launcher_icons (see pubspec). One-off tool; not shipped.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _navy = Color(0xFF1E2A3A);
const Color _terracotta = Color(0xFFB5623A);
const Color _onNavy = Color(0xFFF1ECE1);

Future<void> _writePng(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $path (${image.width}x${image.height})');
}

// Paint the "ش" glyph centred at [fontSize] within a [size] canvas.
void _drawGlyph(Canvas canvas, double size, double fontSize, Color color) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
    textAlign: TextAlign.center,
    fontFamily: 'Tajawal',
    fontSize: fontSize,
    fontWeight: FontWeight.w900,
    textDirection: ui.TextDirection.rtl,
  ))
    ..pushStyle(ui.TextStyle(color: color, fontFamily: 'Tajawal'))
    ..addText('ش');
  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: size));
  // Vertically centre using the paragraph's actual height.
  final dy = (size - paragraph.height) / 2;
  canvas.drawParagraph(paragraph, Offset(0, dy));
}

void main() {
  testWidgets('generate launcher icons', (tester) async {
    // Load the real Tajawal font so the glyph renders (not tofu).
    final fontData = File('tool/icon_gen/Tajawal-Bold.ttf').readAsBytesSync();
    final loader = FontLoader('Tajawal')
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(fontData).buffer)));
    await loader.load();

    const double size = 1024;

    // dart:ui image ops (Picture.toImage / Image.toByteData) only resolve on the
    // real async queue, so run the whole generation inside tester.runAsync —
    // otherwise the second toImage never completes and the test hangs.
    await tester.runAsync(() async {
    // 1) Full legacy icon: navy rounded square + subtle border + terracotta ش.
    {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder,
          Rect.fromLTWH(0, 0, size, size));
      // Navy background (full bleed; launcher masks corners itself for legacy).
      canvas.drawRect(
          Rect.fromLTWH(0, 0, size, size), Paint()..color = _navy);
      // A soft rounded inner tile echoing the splash mark.
      final tileRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(size * 0.16, size * 0.16, size * 0.68, size * 0.68),
          const Radius.circular(150));
      canvas.drawRRect(
          tileRect, Paint()..color = _onNavy.withValues(alpha: 0.06));
      canvas.drawRRect(
          tileRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..color = _terracotta);
      _drawGlyph(canvas, size, size * 0.5, _terracotta);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      await _writePng(image, 'assets/icon/ic_launcher.png');
    }

    // 2) Adaptive foreground: transparent, terracotta ش sized for the ~66%
    //    adaptive safe zone (launcher crops ~33% margin).
    {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
      _drawGlyph(canvas, size, size * 0.42, _terracotta);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      await _writePng(image, 'assets/icon/ic_launcher_foreground.png');
    }
    });
  });
}
