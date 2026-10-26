import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:panamericana_flutter/data/repositories/auth_repository.dart';
import 'package:panamericana_flutter/data/storage/session_storage.dart';
import 'package:panamericana_flutter/ui/features/auth/view_models/auth_view_model.dart';
import 'package:panamericana_flutter/ui/features/cart/view_models/cart_view_model.dart';
import 'package:panamericana_flutter/ui/features/shell/shell_scaffold.dart';
import 'package:panamericana_flutter/ui/features/shell/tab_index_notifier.dart';
import 'package:panamericana_flutter/ui/theme/app_theme.dart';

import 'fonts.dart';

void main() {
  setUpAll(loadGoldenFonts);
  for (final width in [390.0, 800.0]) {
    testWidgets('estructura de navegación a ${width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  AuthViewModel(AuthRepository(Dio()), SessionStorage.instance),
            ),
            ChangeNotifierProvider(create: (_) => CartViewModel()),
            ChangeNotifierProvider(create: (_) => TabIndexNotifier()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              platform: TargetPlatform.android,
            ),
            home: const RepaintBoundary(
              key: Key('golden'),
              child: ShellScaffold(
                body: Center(child: Text('Catálogo de productos')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const Key('golden')),
        matchesGoldenFile('baselines/shell_${width.toInt()}.png'),
      );
    });
  }
}
