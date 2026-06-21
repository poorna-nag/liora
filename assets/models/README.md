# 3D models for AR

The AR feature (Phase 7) places a 3D model on a detected surface.

## How model loading works
- On entering the AR screen, `ArModelLoader` looks for **`companion.glb`** in this
  folder (`assets/models/companion.glb`).
- If present, it copies the file into the app's documents folder and loads it via
  the plugin's `fileSystemAppFolderGLB` node type (the plugin can't load a `.glb`
  straight from the Flutter asset bundle).
- If **absent**, it falls back to a public sample model over the network
  (`ArConstants.fallbackModelUrl`) so AR still works out of the box.

## Add your own model
1. Export or download a **single-file binary glTF** (`.glb`), Y-up, real-world
   metres scale, ideally < 5 MB.
2. Save it here as **`companion.glb`** (exact name).
3. Run `flutter pub get` (assets are already declared in `pubspec.yaml` under
   `assets/models/`) and rebuild.
4. If it looks too big/small in AR, tweak `ArConstants.initialScale` in
   `lib/features/ar/utils/ar_constants.dart`.

Free GLB sources: Khronos glTF Sample Models, Google Poly archives, Sketchfab
(downloadable-licensed models).
