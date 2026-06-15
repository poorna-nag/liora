import '../../../../core/init/app_initializer.dart';
import '../../../../core/init/init_step.dart';
import 'splash_repository.dart';

class SplashRepositoryImpl implements SplashRepository {
  final AppInitializer _initializer;

  SplashRepositoryImpl(this._initializer);

  @override
  Stream<InitProgress> initialize() => _initializer.initialize();
}
