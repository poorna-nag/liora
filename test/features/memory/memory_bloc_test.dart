import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora/features/memory/data/models/memory_entry.dart';
import 'package:liora/features/memory/data/repositories/memory_repository.dart';
import 'package:liora/features/memory/presentation/bloc/memory_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockMemoryRepository extends Mock implements MemoryRepository {}

void main() {
  late MockMemoryRepository repository;

  final entry = MemoryEntry(
    id: 'm1',
    content: 'My name is Aditya',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repository = MockMemoryRepository();
  });

  group('MemoryBloc', () {
    blocTest<MemoryBloc, MemoryState>(
      'loads entries on MemoryStarted',
      build: () {
        when(() => repository.getAll()).thenReturn([entry]);
        return MemoryBloc(repository);
      },
      act: (bloc) => bloc.add(const MemoryStarted()),
      expect: () => [
        isA<MemoryState>()
            .having((s) => s.status, 'status', MemoryStatus.ready)
            .having((s) => s.entries.length, 'entries', 1),
      ],
    );

    blocTest<MemoryBloc, MemoryState>(
      'adds an entry and reloads',
      build: () {
        when(() => repository.add(any(), pinned: any(named: 'pinned')))
            .thenAnswer((_) async {});
        when(() => repository.getAll()).thenReturn([entry]);
        return MemoryBloc(repository);
      },
      act: (bloc) => bloc.add(const MemoryAdded('My name is Aditya')),
      expect: () => [
        isA<MemoryState>()
            .having((s) => s.entries.length, 'entries', 1),
      ],
      verify: (_) => verify(() => repository.add('My name is Aditya',
          pinned: false)).called(1),
    );

    blocTest<MemoryBloc, MemoryState>(
      'ignores empty content',
      build: () => MemoryBloc(repository),
      act: (bloc) => bloc.add(const MemoryAdded('   ')),
      expect: () => [],
    );
  });
}
