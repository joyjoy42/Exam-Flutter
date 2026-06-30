import 'app_exception.dart';

/// Discriminated union for async UI state, mirroring the Loading /
/// Loaded(balance) / Error states called out in the spec — but generic so
/// every repository/provider in the app can reuse it instead of each
/// feature inventing its own enum + nullable-fields combo.
sealed class Result<T> {
  const Result();
}

class Loading<T> extends Result<T> {
  const Loading();
}

class Success<T> extends Result<T> {
  const Success(this.data, {this.isStale = false});

  final T data;

  /// True when this value came from cache past its TTL because a live
  /// refresh failed (offline fallback). The UI can show a subtle
  /// "données hors-ligne" hint instead of a hard error.
  final bool isStale;
}

class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppException error;
}
