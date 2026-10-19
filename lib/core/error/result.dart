import 'failure.dart';

sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Error<T>(:final error) => failure(error),
    };
  }
}

class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

class Error<T> extends Result<T> {
  const Error(this.error);

  final Failure error;
}
