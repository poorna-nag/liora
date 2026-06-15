import '../models/feature_tile.dart';

/// Provides the set of feature tiles displayed on the home hub.
abstract class HomeRepository {
  List<FeatureTile> tiles();
}
