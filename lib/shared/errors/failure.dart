import 'package:equatable/equatable.dart';

/// Domain level representation of anything that can go wrong.
///
/// The hierarchy is `sealed` on purpose: adding a new failure turns every
/// non exhaustive `switch` in the presentation layer into a compile error
/// instead of a case that silently falls through at runtime.
///
/// A [Failure] never carries user facing copy. It describes *what* happened;
/// deciding *how* to word it belongs to the UI.
///
/// Failures are thrown rather than returned in a wrapper type. Services throw,
/// blocs catch and emit an error state, which is the shape every Flutter
/// reviewer already reads fluently and costs no extra dependency. Because the
/// hierarchy is sealed, a `switch` over a caught failure is still exhaustive,
/// so the guarantee a result type is usually reached for is preserved.
sealed class Failure extends Equatable implements Exception {
  const Failure({this.debugMessage});

  /// Technical detail intended for logs, never for the screen.
  final String? debugMessage;

  /// Whether repeating the same operation could reasonably succeed.
  ///
  /// Drives whether the UI offers a retry action.
  bool get isRetryable => false;

  @override
  List<Object?> get props => <Object?>[debugMessage];
}

/// The device could not reach the network at all.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.debugMessage});

  @override
  bool get isRetryable => true;
}

/// The request outlived its timeout budget.
final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.debugMessage});

  @override
  bool get isRetryable => true;
}

/// The service answered with a 5xx status.
final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode, super.debugMessage});

  final int? statusCode;

  @override
  bool get isRetryable => true;

  @override
  List<Object?> get props => <Object?>[...super.props, statusCode];
}

/// The API key is missing, invalid, or not authorised for this endpoint.
///
/// Kept separate from other 4xx responses because the key is injected at build
/// time through `--dart-define`. Whoever runs the app without it must be told
/// exactly that, instead of reading a generic network error.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.debugMessage});
}

/// The API rejected the call for exceeding its quota (HTTP 429).
final class RateLimitFailure extends Failure {
  const RateLimitFailure({super.debugMessage});

  @override
  bool get isRetryable => true;
}

/// Any other 4xx: the request itself was malformed or unsupported.
final class RequestFailure extends Failure {
  const RequestFailure({this.statusCode, super.debugMessage});

  final int? statusCode;

  @override
  List<Object?> get props => <Object?>[...super.props, statusCode];
}

/// A response arrived but did not match the expected shape.
final class ParsingFailure extends Failure {
  const ParsingFailure({super.debugMessage});
}

/// The request was cancelled before it completed.
///
/// Expected during search: each keystroke cancels the in flight request, so
/// this must never surface to the user as an error state.
final class CancelledFailure extends Failure {
  const CancelledFailure({super.debugMessage});
}

/// Local storage could not complete the operation.
final class StorageFailure extends Failure {
  const StorageFailure({super.debugMessage});
}

/// Nothing else matched.
final class UnknownFailure extends Failure {
  const UnknownFailure({super.debugMessage});
}
