import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:blurhashx/blurhashx.dart';
import 'package:flutter_test/flutter_test.dart';

/// Draws a two-colour gradient-like image and returns it as PNG bytes plus its raw RGBA pixels.
Future<({Uint8List png, Uint8List rgba})> _makeImage(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF2266AA),
  );
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width / 2, height / 2),
    ui.Paint()..color = const ui.Color(0xFFEE8833),
  );
  final image = await recorder.endRecording().toImage(width, height);
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return (png: png!.buffer.asUint8List(), rgba: rgba!.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BlurHash.encodeImageBytes', () {
    test('matches BlurHash.encode for an image within maxDimension', () async {
      final img = await _makeImage(40, 30);

      final fromBytes = await BlurHash.encodeImageBytes(img.png, componentX: 4, componentY: 3);
      final fromPixels = BlurHash.encode(img.rgba, 40, 30, componentX: 4, componentY: 3);

      expect(BlurHash.isValid(fromBytes), isTrue);
      expect(fromBytes, equals(fromPixels));
    });

    test('encodes a landscape image larger than maxDimension', () async {
      final img = await _makeImage(400, 200);

      final hash = await BlurHash.encodeImageBytes(img.png, componentX: 4, componentY: 3);

      expect(BlurHash.isValid(hash), isTrue);
      expect(BlurHash.components(hash), equals((componentX: 4, componentY: 3)));
    });

    test('encodes a portrait image larger than maxDimension', () async {
      final img = await _makeImage(150, 600);

      final hash = await BlurHash.encodeImageBytes(img.png, componentX: 3, componentY: 4);

      expect(BlurHash.isValid(hash), isTrue);
      expect(BlurHash.components(hash), equals((componentX: 3, componentY: 4)));
    });
  });
}
