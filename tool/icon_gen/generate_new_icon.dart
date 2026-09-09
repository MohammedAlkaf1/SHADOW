// Regenerates assets/icon/app_icon.png (the flutter_launcher_icons source)
// and assets/icon/shadow_wordmark_icon.png's navy-square composite, using
// the *new* approved brand mark (the orange-gradient fingerprint/soundwave
// icon pulled from the Figma home-screen header, node 37:56) instead of the
// older squiggle+bars mark. Run with:
//   flutter test tool/icon_gen/generate_new_icon.dart
// Then regenerate the actual launcher mipmaps with:
//   dart run flutter_launcher_icons

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _navyTop = Color(0xFF25384C);
const Color _navyBottom = Color(0xFF16202C);

Future<void> _writePng(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $path (${image.width}x${image.height})');
}

Future<ui.Image> _loadImage(String path) async {
  final bytes = File(path).readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

void main() {
  testWidgets('generate new launcher icon', (tester) async {
    await tester.runAsync(() async {
      const double size = 1024;
      final mark = await _loadImage('assets/icon/shadow_wordmark_icon.png');

      // 1) Full launcher icon: navy rounded-square field + centered mark
      //    (mark drawn at ~62% of canvas, matching the old master icon's
      //    proportions), used for both image_path and adaptive foreground.
      {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
        final rrect = RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, size, size), const Radius.circular(size * 0.225));
        final gradient = ui.Gradient.linear(
          const Offset(size / 2, 0),
          Offset(size / 2, size),
          [_navyTop, _navyBottom],
        );
        canvas.drawRRect(rrect, Paint()..shader = gradient);

        final markSize = size * 0.62;
        final markRect = Rect.fromLTWH(
            (size - markSize) / 2, (size - markSize) / 2, markSize, markSize);
        final srcRect =
            Rect.fromLTWH(0, 0, mark.width.toDouble(), mark.height.toDouble());
        canvas.drawImageRect(mark, srcRect, markRect, Paint()..filterQuality = FilterQuality.high);

        final picture = recorder.endRecording();
        final image = await picture.toImage(size.toInt(), size.toInt());
        await _writePng(image, 'assets/icon/app_icon.png');
      }
    });
  });
}
