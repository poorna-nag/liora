import '../../../../core/init/init_step.dart';

/// Exposes the app initialization flow to the splash bloc.
abstract class SplashRepository {
  /// Streams progress as the app initializes (Firebase, storage, session, …).
  Stream<InitProgress> initialize();
}
