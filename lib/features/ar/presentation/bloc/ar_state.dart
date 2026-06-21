part of 'ar_bloc.dart';

enum ArStatus { initializing, ready, unsupported, error }

class ArState extends Equatable {
  final ArStatus status;

  /// How many models are currently placed (drives the "clear" affordance).
  final int placedCount;

  /// User-facing message for the unsupported/error states.
  final String? message;

  const ArState({
    this.status = ArStatus.initializing,
    this.placedCount = 0,
    this.message,
  });

  bool get hasPlacedObjects => placedCount > 0;

  ArState copyWith({
    ArStatus? status,
    int? placedCount,
    String? message,
  }) =>
      ArState(
        status: status ?? this.status,
        placedCount: placedCount ?? this.placedCount,
        message: message ?? this.message,
      );

  @override
  List<Object?> get props => [status, placedCount, message];
}
