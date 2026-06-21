import 'dart:typed_data';

/// The result of running a raw camera frame through [FrameProcessor] on a
/// background isolate. Carries the compressed bytes ready for upload plus the
/// cheap signals the [FrameScheduler] uses to decide whether the frame is worth
/// analyzing at all (dedupe + blur).
class FrameAnalysis {
  /// Downscaled, re-encoded JPEG bytes (what actually gets sent to Gemini).
  final Uint8List compressed;

  /// 64-bit average hash (aHash) used for near-duplicate detection between
  /// consecutive frames via Hamming distance.
  final int averageHash;

  /// Variance of the Laplacian — a sharpness proxy. Higher = sharper; low
  /// values indicate blur or poor lighting.
  final double blurScore;

  final int width;
  final int height;

  const FrameAnalysis({
    required this.compressed,
    required this.averageHash,
    required this.blurScore,
    required this.width,
    required this.height,
  });

  /// Hamming distance between two 64-bit average hashes (number of differing
  /// bits, 0..64). Small distance ⇒ visually similar frames.
  static int hammingDistance(int a, int b) {
    var x = a ^ b;
    var count = 0;
    while (x != 0) {
      count += x & 1;
      x = x >>> 1;
    }
    return count;
  }
}
