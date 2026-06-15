part of 'memory_bloc.dart';

sealed class MemoryEvent extends Equatable {
  const MemoryEvent();

  @override
  List<Object?> get props => [];
}

class MemoryStarted extends MemoryEvent {
  const MemoryStarted();
}

class MemoryAdded extends MemoryEvent {
  final String content;
  final bool pinned;
  const MemoryAdded(this.content, {this.pinned = false});

  @override
  List<Object?> get props => [content, pinned];
}

class MemoryUpdated extends MemoryEvent {
  final MemoryEntry entry;
  const MemoryUpdated(this.entry);

  @override
  List<Object?> get props => [entry];
}

class MemoryDeleted extends MemoryEvent {
  final String id;
  const MemoryDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

class MemoryCleared extends MemoryEvent {
  const MemoryCleared();
}
