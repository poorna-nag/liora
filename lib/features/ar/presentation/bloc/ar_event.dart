part of 'ar_bloc.dart';

sealed class ArEvent extends Equatable {
  const ArEvent();

  @override
  List<Object?> get props => [];
}

/// Begin: validate platform support and start the init watchdog.
class ArStarted extends ArEvent {
  const ArStarted();
}

/// The plugin's AR view came up (managers created) — we're live.
class ArViewReady extends ArEvent {
  const ArViewReady();
}

/// The AR view didn't come up in time — treat the device as unsupported.
class ArInitTimedOut extends ArEvent {
  const ArInitTimedOut();
}

/// A model was successfully anchored.
class ArObjectPlaced extends ArEvent {
  const ArObjectPlaced();
}

/// All placed models were removed.
class ArCleared extends ArEvent {
  const ArCleared();
}

/// A non-recoverable AR error occurred.
class ArErrorReported extends ArEvent {
  final String message;
  const ArErrorReported(this.message);

  @override
  List<Object?> get props => [message];
}
