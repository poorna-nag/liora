part of 'home_bloc.dart';

class HomeState extends Equatable {
  final List<FeatureTile> tiles;
  const HomeState({this.tiles = const []});

  @override
  List<Object?> get props => [tiles];
}
