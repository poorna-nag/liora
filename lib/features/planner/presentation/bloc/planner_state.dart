part of 'planner_bloc.dart';

enum PlannerStatus { initial, ready }

class PlannerState extends Equatable {
  final PlannerStatus status;
  final List<PlanItem> items;

  const PlannerState({
    this.status = PlannerStatus.initial,
    this.items = const [],
  });

  /// Pending items due today or overdue — surfaced at the top of the screen.
  List<PlanItem> get dueNow =>
      items.where((i) => !i.done && (i.isDueToday || i.isOverdue)).toList();

  PlannerState copyWith({PlannerStatus? status, List<PlanItem>? items}) =>
      PlannerState(
        status: status ?? this.status,
        items: items ?? this.items,
      );

  @override
  List<Object?> get props => [status, items];
}
