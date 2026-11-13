import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:allflag/data/country_flag_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog points only at bundled lossless WebP flags', () async {
    final items = await const CountryFlagCatalog().loadFlags();
    expect(items, hasLength(195));
    for (final item in items) {
      expect(item.asset, matches(RegExp(r'^assets/flags/[a-z]{2}\.webp$')));
      expect(File(item.asset).existsSync(), isTrue, reason: item.asset);
    }
    expect(
      Directory('assets/flags')
          .listSync()
          .where((f) => f.path.endsWith('.png')),
      isEmpty,
    );
  });

  test('every WebP decodes at its documented source size', () async {
    final provenance = jsonDecode(
      File('docs/flag-assets.json').readAsStringSync(),
    );
    for (final asset in provenance['assets'] as List) {
      final code = (asset['code'] as String).toLowerCase();
      final bytes = File('assets/flags/$code.webp').readAsBytesSync();
      // RIFF....WEBPVP8L: lossless bitstream, so detail stays crisp.
      expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF');
      expect(ascii.decode(bytes.sublist(8, 16)), 'WEBPVP8L', reason: code);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, asset['width'], reason: code);
      expect(frame.image.height, asset['height'], reason: code);
      frame.image.dispose();
    }
  });
}
