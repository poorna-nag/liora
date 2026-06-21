part of 'planner_bloc.dart';

sealed class PlannerEvent extends Equatable {
  const PlannerEvent();

  @override
  List<Object?> get props => [];
}

class PlannerStarted extends PlannerEvent {
  const PlannerStarted();
}

class PlannerItemAdded extends PlannerEvent {
  final String title;
  final String notes;
  final DateTime? dueAt;
  const PlannerItemAdded({required this.title, this.notes = '', this.dueAt});

  @override
  List<Object?> get props => [title, notes, dueAt];
}

class PlannerItemToggled extends PlannerEvent {
  final String id;
  const PlannerItemToggled(this.id);

  @override
  List<Object?> get props => [id];
}

class PlannerItemDeleted extends PlannerEvent {
  final String id;
  const PlannerItemDeleted(this.id);

  @override
  List<Object?> get props => [id];
}
