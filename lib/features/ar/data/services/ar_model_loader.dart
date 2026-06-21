import 'dart:io';

import 'package:ar_flutter_plugin_engine/datatypes/node_types.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/ar_constants.dart';

/// Where a model should be loaded from, resolved to a [NodeType] + uri that the
/// plugin understands.
class ArModelRef {
  final NodeType type;
  final String uri;
  const ArModelRef(this.type, this.uri);
}

/// Resolves the 3D model to place. The plugin cannot load a `.glb` straight from
/// the Flutter asset bundle (asset loading only supports `.gltf` via
/// [NodeType.localGLTF2]), so a bundled GLB is copied once into the app's
/// documents folder and loaded via [NodeType.fileSystemAppFolderGLB]. If no
/// bundled asset is present, we fall back to a remote sample model.
class ArModelLoader {
  const ArModelLoader();

  Future<ArModelRef> resolve() async {
    final bytes = await _tryLoadAsset();
    if (bytes == null) {
      // No bundled model — use the remote sample so AR still works out of box.
      return const ArModelRef(NodeType.webGLB, ArConstants.fallbackModelUrl);
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${ArConstants.localModelFileName}');
    if (!file.existsSync() || file.lengthSync() != bytes.lengthInBytes) {
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    }
    // fileSystemAppFolderGLB resolves the uri relative to the documents folder.
    return const ArModelRef(
      NodeType.fileSystemAppFolderGLB,
      ArConstants.localModelFileName,
    );
  }

  Future<ByteData?> _tryLoadAsset() async {
    try {
      return await rootBundle.load(ArConstants.modelAssetPath);
    } catch (_) {
      // Asset not bundled (placeholder build) — caller falls back to the URL.
      return null;
    }
  }
}
