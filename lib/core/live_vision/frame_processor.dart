import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'models/frame_analysis.dart';

/// Tunable parameters for frame processing. Kept here so tests and the
/// scheduler share one source of truth.
class FrameProcessorConfig {
  /// Longest edge of the image actually uploaded to the model.
  static const int downscaleMaxEdge = 1024;

  /// JPEG quality for the re-encoded upload frame.
  static const int jpegQuality = 70;

  /// Edge length used for the cheap blur estimate (smaller = faster).
  static const int blurSampleEdge = 256;
}

/// Decodes, downscales, compresses and fingerprints a raw camera frame. All
/// the heavy pixel work runs on a background isolate via [compute] so the
/// camera preview stays smooth (requirement: smooth camera performance).
///
/// Registered as a lazy singleton; stateless so it is safe to share.
class FrameProcessor {
  const FrameProcessor();

  /// Processes [rawJpeg] off the main isolate. Returns null if the bytes can't
  /// be decoded (treated by the scheduler as a frame to skip).
  Future<FrameAnalysis?> process(Uint8List rawJpeg) =>
      compute(_processFrame, rawJpeg);
}

/// Top-level isolate entry point (required by [compute]).
FrameAnalysis? _processFrame(Uint8List rawJpeg) {
  final decoded = img.decodeImage(rawJpeg);
  if (decoded == null) return null;

  // 1. Downscale for upload, preserving aspect ratio.
  final longestEdge =
      decoded.width >= decoded.height ? decoded.width : decoded.height;
  final img.Image resized;
  if (longestEdge > FrameProcessorConfig.downscaleMaxEdge) {
    if (decoded.width >= decoded.height) {
      resized = img.copyResize(decoded,
          width: FrameProcessorConfig.downscaleMaxEdge);
    } else {
      resized = img.copyResize(decoded,
          height: FrameProcessorConfig.downscaleMaxEdge);
    }
  } else {
    resized = decoded;
  }

  // 2. Compress to JPEG for upload.
  final compressed = Uint8List.fromList(
    img.encodeJpg(resized, quality: FrameProcessorConfig.jpegQuality),
  );

  // 3. Average hash (aHash) for near-duplicate detection.
  final averageHash = _averageHash(decoded);

  // 4. Blur score via variance of the Laplacian.
  final blurScore = _laplacianVariance(decoded);

  return FrameAnalysis(
    compressed: compressed,
    averageHash: averageHash,
    blurScore: blurScore,
    width: resized.width,
    height: resized.height,
  );
}

/// 64-bit average hash: shrink to 8x8 grayscale, set each bit where the pixel
/// luma is >= the mean luma.
int _averageHash(img.Image source) {
  final small = img.copyResize(source, width: 8, height: 8);
  final luma = List<int>.filled(64, 0);
  var sum = 0;
  var i = 0;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final p = small.getPixel(x, y);
      final l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
      luma[i++] = l;
      sum += l;
    }
  }
  final mean = sum / 64.0;
  var hash = 0;
  for (var b = 0; b < 64; b++) {
    if (luma[b] >= mean) {
      hash |= 1 << b;
    }
  }
  return hash;
}

/// Variance of the Laplacian on a downscaled grayscale copy. A standard,
/// cheap focus measure: blurry frames have little high-frequency content so the
/// Laplacian response has low variance.
double _laplacianVariance(img.Image source) {
  final scale = source.width >= source.height
      ? FrameProcessorConfig.blurSampleEdge / source.width
      : FrameProcessorConfig.blurSampleEdge / source.height;
  final sample = scale < 1.0
      ? img.copyResize(
          source,
          width: (source.width * scale).round().clamp(1, source.width),
        )
      : source;
  final w = sample.width;
  final h = sample.height;
  if (w < 3 || h < 3) return 0.0;

  // Precompute grayscale luma into a flat buffer.
  final gray = List<double>.filled(w * h, 0);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = sample.getPixel(x, y);
      gray[y * w + x] = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
    }
  }

  // 4-neighbour Laplacian, interior pixels only.
  var sum = 0.0;
  var sumSq = 0.0;
  var count = 0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final c = gray[y * w + x];
      final lap = gray[y * w + (x - 1)] +
          gray[y * w + (x + 1)] +
          gray[(y - 1) * w + x] +
          gray[(y + 1) * w + x] -
          4 * c;
      sum += lap;
      sumSq += lap * lap;
      count++;
    }
  }
  if (count == 0) return 0.0;
  final mean = sum / count;
  return (sumSq / count) - (mean * mean);
}
