part of 'memory_bloc.dart';

enum MemoryStatus { initial, ready }

class MemoryState extends Equatable {
  final MemoryStatus status;
  final List<MemoryEntry> entries;

  const MemoryState({
    this.status = MemoryStatus.initial,
    this.entries = const [],
  });

  MemoryState copyWith({MemoryStatus? status, List<MemoryEntry>? entries}) =>
      MemoryState(
        status: status ?? this.status,
        entries: entries ?? this.entries,
      );

  @override
  List<Object?> get props => [status, entries];
}
