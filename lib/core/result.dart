/// Minimal Result type for domain-level success/failure.
///
/// Keep it framework-agnostic so it can live in [domain] without pulling
/// Flutter or async plumbing.
sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T? get valueOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  E? get errorOrNull => switch (this) {
        Ok() => null,
        Err(:final error) => error,
      };

  R when<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final error) => err(error),
      };
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;
}
