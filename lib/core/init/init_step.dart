/// Ordered startup steps, surfaced on the splash screen.
enum InitStep {
  firebase('Connecting services'),
  storage('Preparing local storage'),
  preferences('Loading preferences'),
  session('Starting guest session'),
  configuration('Loading AI configuration'),
  ai('Warming up the assistant');

  final String label;
  const InitStep(this.label);
}

/// Progress snapshot emitted during initialization.
class InitProgress {
  final InitStep step;
  final int index; // 1-based
  final int total;

  const InitProgress(this.step, this.index, this.total);

  double get fraction => index / total;
}
