import 'package:flutter_test/flutter_test.dart';
import 'package:liora/core/live_vision/models/scene_observation.dart';
import 'package:liora/features/emotion/data/models/emotion.dart';
import 'package:liora/features/live_vision/data/models/observation_parser.dart';

void main() {
  group('ObservationParser.parse', () {
    test('parses a bare JSON object', () {
      const raw = '{"scene":"kitchen","speech":"Nice kettle there.",'
          '"new_objects":["kettle","toaster"],"changes":[],'
          '"guidance":{"direction":"left","reason":"to see the window"},'
          '"suggestion":"Wipe the counter.","highlight":null,"confidence":0.9}';

      final o = ObservationParser.parse(raw, emotion: Emotion.happy);

      expect(o.scene, SceneType.kitchen);
      expect(o.speech, 'Nice kettle there.');
      expect(o.newObjects, ['kettle', 'toaster']);
      expect(o.guidance.direction, GuidanceDirection.left);
      expect(o.guidance.reason, 'to see the window');
      expect(o.suggestion, 'Wipe the counter.');
      expect(o.highlight, isNull);
      expect(o.confidence, closeTo(0.9, 1e-9));
      expect(o.emotion, Emotion.happy);
    });

    test('tolerates ```json fences and surrounding prose', () {
      const raw = 'Sure! Here you go:\n```json\n'
          '{"scene":"office","speech":"Tidy desk.","confidence":0.7}\n```';

      final o = ObservationParser.parse(raw, emotion: Emotion.calm);

      expect(o.scene, SceneType.office);
      expect(o.speech, 'Tidy desk.');
      expect(o.confidence, closeTo(0.7, 1e-9));
    });

    test('parses a highlight rect and clamps to 0..1', () {
      const raw = '{"speech":"there","highlight":'
          '{"x":1.2,"y":-0.1,"w":0.5,"h":0.4,"label":"chair"},"confidence":0.8}';

      final o = ObservationParser.parse(raw, emotion: Emotion.neutral);

      expect(o.highlight, isNotNull);
      expect(o.highlight!.x, 1.0);
      expect(o.highlight!.y, 0.0);
      expect(o.highlight!.label, 'chair');
    });

    test('drops a zero-area highlight', () {
      const raw = '{"speech":"hi","highlight":'
          '{"x":0.1,"y":0.1,"w":0.0,"h":0.4},"confidence":0.8}';

      final o = ObservationParser.parse(raw, emotion: Emotion.neutral);
      expect(o.highlight, isNull);
    });

    test('falls back to prose as speech when no JSON object is present', () {
      final o = ObservationParser.parse('I can see a cozy living room.',
          emotion: Emotion.calm);

      expect(o.speech, 'I can see a cozy living room.');
      expect(o.scene, SceneType.unknown);
      expect(o.emotion, Emotion.calm);
    });

    test('returns empty observation for empty/malformed input', () {
      final o = ObservationParser.parse('   ', emotion: Emotion.neutral);
      expect(o, SceneObservation.empty);
      expect(o.hasSpeech, isFalse);
    });

    test('unknown scene and direction keys degrade gracefully', () {
      const raw = '{"scene":"spaceship","speech":"hmm",'
          '"guidance":{"direction":"sideways"},"confidence":0.5}';

      final o = ObservationParser.parse(raw, emotion: Emotion.neutral);
      expect(o.scene, SceneType.unknown);
      expect(o.guidance.direction, GuidanceDirection.none);
    });
  });

  group('ObservationParser.buildInstruction', () {
    test('includes the scene summary and a pending user question', () {
      final instruction = ObservationParser.buildInstruction(
        sceneSummary: 'PRIOR SCENE CONTEXT: Room: kitchen.',
        userQuestion: 'What should I cook?',
      );

      expect(instruction, contains('PRIOR SCENE CONTEXT: Room: kitchen.'));
      expect(instruction, contains('The user just asked: "What should I cook?"'));
      expect(instruction, contains('"scene"'));
    });

    test('omits the question when absent and still carries the contract', () {
      final instruction = ObservationParser.buildInstruction(sceneSummary: '');
      expect(instruction, isNot(contains('The user just asked')));
      expect(instruction, contains('"scene"'));
    });
  });
}
