import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadGoldenFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final roboto = FontLoader('Roboto');
  for (final font in ['roboto-regular.ttf', 'roboto-bold.ttf']) {
    roboto.addFont(
      File('test/goldens/fonts/$font')
          .readAsBytes()
          .then((bytes) => ByteData.sublistView(bytes)),
    );
  }
  await roboto.load();
  // Los estilos sin familia explícita usan Ahem en flutter_test.
  // Cargar Roboto también con ese nombre evita bloques artificiales.
  await (FontLoader('Ahem')..addFont(
        File('test/goldens/fonts/roboto-regular.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      ))
      .load();
  await (FontLoader('MaterialIcons')..addFont(
        File('test/goldens/fonts/materialicons-regular.otf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      ))
      .load();
}
