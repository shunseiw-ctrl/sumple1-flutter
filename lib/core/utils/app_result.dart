/// 汎用Result型（Dart 3.0+ sealed class）
///
/// サービス層からUI層への結果伝達に使用。
/// パターンマッチで網羅的にハンドリング可能。
sealed class AppResult<T> {
  const AppResult();

  bool get isSuccess => this is AppSuccess<T>;
  bool get isError => this is AppError<T>;

  T? get data => switch (this) {
        AppSuccess<T>(value: final v) => v,
        AppError<T>() => null,
      };

  String? get errorMessage => switch (this) {
        AppSuccess<T>() => null,
        AppError<T>(message: final m) => m,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? originalError) error,
  }) {
    return switch (this) {
      AppSuccess<T>(value: final v) => success(v),
      AppError<T>(message: final m, originalError: final e) => error(m, e),
    };
  }
}

final class AppSuccess<T> extends AppResult<T> {
  final T value;
  const AppSuccess(this.value);

  @override
  T get data => value;
}

final class AppError<T> extends AppResult<T> {
  final String message;
  final Object? originalError;
  const AppError(this.message, {this.originalError});
}
