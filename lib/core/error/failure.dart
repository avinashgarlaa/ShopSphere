sealed class Failure {
  const Failure(this.message);

  final String message;

  factory Failure.network() => const NetworkFailure();
  factory Failure.timeout() => const TimeoutFailure();
  factory Failure.unauthorized() => const UnauthorizedFailure();
  factory Failure.notFound([
    String message = 'We could not find that product.',
  ]) => NotFoundFailure(message);
  factory Failure.server([
    String message = 'Something went wrong on our side.',
  ]) => ServerFailure(message);
  factory Failure.validation([
    String message = 'Please check your details and try again.',
  ]) => ValidationFailure(message);
  factory Failure.unknown([
    String message = 'Something unexpected happened.',
  ]) => UnknownFailure(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure()
    : super('No internet connection. Check your network and try again.');
}

class TimeoutFailure extends Failure {
  const TimeoutFailure()
    : super('This is taking longer than expected. Please try again.');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure()
    : super('Your session has expired. Please sign in again.');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
