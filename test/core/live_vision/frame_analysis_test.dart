import 'package:flutter_test/flutter_test.dart';
import 'package:liora/core/live_vision/models/frame_analysis.dart';

void main() {
  group('FrameAnalysis.hammingDistance', () {
    test('identical hashes have distance 0', () {
      expect(FrameAnalysis.hammingDistance(0x0, 0x0), 0);
      expect(FrameAnalysis.hammingDistance(0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF), 0);
    });

    test('counts differing bits', () {
      expect(FrameAnalysis.hammingDistance(0x0, 0x1), 1);
      expect(FrameAnalysis.hammingDistance(0x0, 0xF), 4);
      expect(FrameAnalysis.hammingDistance(0xA, 0x5), 4); // 1010 vs 0101
    });

    test('fully opposite 64-bit hashes have distance 64', () {
      expect(
        FrameAnalysis.hammingDistance(0x0, 0xFFFFFFFFFFFFFFFF),
        64,
      );
    });

    test('distance is symmetric', () {
      const a = 0x1234ABCD5678EF90;
      const b = 0x0FEDCBA987654321;
      expect(
        FrameAnalysis.hammingDistance(a, b),
        FrameAnalysis.hammingDistance(b, a),
      );
    });
  });
}
