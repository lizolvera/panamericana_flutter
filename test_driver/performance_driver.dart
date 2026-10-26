import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null || data['catalog_timeline'] == null) {
      throw StateError('No hay medición de rendimiento; ejecución inconclusa.');
    }
    final timeline = Timeline.fromJson(
      data['catalog_timeline'] as Map<String, dynamic>,
    );
    final summary = TimelineSummary.summarize(timeline);
    await summary.writeTimelineToFile(
      'catalog',
      destinationDirectory: 'reports/performance',
      pretty: true,
    );
    final report = jsonDecode(
      await File('reports/performance/catalog.timeline_summary.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    final build = report['90th_percentile_frame_build_time_millis'] as num?;
    final raster =
        report['90th_percentile_frame_rasterizer_time_millis'] as num?;
    if (build == null || raster == null || build > 16.67 || raster > 16.67) {
      throw StateError(
        'Rendimiento insuficiente o incompleto: p90 build/raster debe ser <=16.67 ms.',
      );
    }
  },
);
