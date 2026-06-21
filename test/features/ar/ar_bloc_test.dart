import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora/features/ar/data/services/ar_support_service.dart';
import 'package:liora/features/ar/presentation/bloc/ar_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockArSupportService extends Mock implements ArSupportService {}

void main() {
  late MockArSupportService support;

  setUp(() {
    support = MockArSupportService();
    when(() => support.unsupportedMessage).thenReturn('No AR here.');
  });

  group('ArBloc', () {
    blocTest<ArBloc, ArState>(
      'goes straight to unsupported when the platform cannot host AR',
      build: () {
        when(() => support.isPlatformCapable).thenReturn(false);
        return ArBloc(support);
      },
      act: (bloc) => bloc.add(const ArStarted()),
      expect: () => [
        isA<ArState>()
            .having((s) => s.status, 'status', ArStatus.unsupported)
            .having((s) => s.message, 'message', 'No AR here.'),
      ],
    );

    blocTest<ArBloc, ArState>(
      'initializes then becomes ready when the view comes up',
      build: () {
        when(() => support.isPlatformCapable).thenReturn(true);
        return ArBloc(support);
      },
      act: (bloc) => bloc
        ..add(const ArStarted())
        ..add(const ArViewReady()),
      expect: () => [
        isA<ArState>().having((s) => s.status, 'status', ArStatus.initializing),
        isA<ArState>().having((s) => s.status, 'status', ArStatus.ready),
      ],
    );

    blocTest<ArBloc, ArState>(
      'counts placed objects and clears them',
      build: () {
        when(() => support.isPlatformCapable).thenReturn(true);
        return ArBloc(support);
      },
      seed: () => const ArState(status: ArStatus.ready),
      act: (bloc) => bloc
        ..add(const ArObjectPlaced())
        ..add(const ArObjectPlaced())
        ..add(const ArCleared()),
      expect: () => [
        isA<ArState>().having((s) => s.placedCount, 'placedCount', 1),
        isA<ArState>().having((s) => s.placedCount, 'placedCount', 2),
        isA<ArState>().having((s) => s.placedCount, 'placedCount', 0),
      ],
    );
  });
}
