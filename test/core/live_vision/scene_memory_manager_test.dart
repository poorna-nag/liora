import 'package:flutter_test/flutter_test.dart';
import 'package:liora/core/live_vision/models/scene_observation.dart';
import 'package:liora/core/live_vision/scene_memory_manager.dart';

SceneObservation _obs({
  SceneType scene = SceneType.kitchen,
  String speech = '',
  List<String> newObjects = const [],
  String suggestion = '',
}) =>
    SceneObservation(
      scene: scene,
      speech: speech,
      newObjects: newObjects,
      suggestion: suggestion,
      confidence: 0.9,
    );

void main() {
  group('SceneMemoryManager', () {
    test('summary is empty before any observation', () {
      final m = SceneMemoryManager();
      expect(m.buildSummary(), isEmpty);
    });

    test('ingest accumulates objects, scene and spoken points', () {
      final m = SceneMemoryManager();
      m.ingest(_obs(
        scene: SceneType.kitchen,
        speech: 'I see a kettle.',
        newObjects: ['kettle', 'Toaster'],
        suggestion: 'Wipe the counter.',
      ));

      final summary = m.buildSummary();
      expect(summary, contains('Room: kitchen'));
      expect(summary, contains('kettle'));
      expect(summary, contains('toaster')); // normalized lowercase
      expect(summary, contains('Already said'));
      expect(summary, contains('Wipe the counter.'));
    });

    test('isRepeat flags near-identical lines and lets new ones through', () {
      final m = SceneMemoryManager();
      m.ingest(_obs(speech: 'There is a wooden chair near the table.'));

      // Exact and trivially-different lines are caught (>= 0.8 token overlap).
      expect(m.isRepeat('There is a wooden chair near the table.'), isTrue);
      expect(m.isRepeat('There is a wooden chair near the table now.'), isTrue);
      // A genuinely different remark is allowed through.
      expect(m.isRepeat('The window has lovely morning light.'), isFalse);
    });

    test('summary respects the character cap', () {
      final m = SceneMemoryManager();
      for (var i = 0; i < 60; i++) {
        m.ingest(_obs(
          speech: 'Observation number $i with some descriptive words here.',
          newObjects: ['object_$i'],
        ));
      }
      expect(m.buildSummary().length, lessThanOrEqualTo(601));
    });

    test('clear forgets everything', () {
      final m = SceneMemoryManager();
      m.ingest(_obs(speech: 'hi', newObjects: ['lamp']));
      m.clear();
      expect(m.buildSummary(), isEmpty);
      expect(m.isRepeat('hi'), isFalse);
    });
  });
}
