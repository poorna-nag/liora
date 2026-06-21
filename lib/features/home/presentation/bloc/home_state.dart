part of 'home_bloc.dart';

class HomeState extends Equatable {
  final List<FeatureTile> tiles;

  /// Phase 6: a friendly proactive line about what's due now, or null.
  final String? reminder;

  const HomeState({this.tiles = const [], this.reminder});

  @override
  List<Object?> get props => [tiles, reminder];
}
