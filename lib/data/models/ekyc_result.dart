enum EkycStatus { notStarted, pending, approved, rejected, unavailable }

sealed class EkycResult {
  const EkycResult();
}

final class EkycSuccess extends EkycResult {
  final String verificationId;
  const EkycSuccess({required this.verificationId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EkycSuccess && verificationId == other.verificationId;

  @override
  int get hashCode => verificationId.hashCode;
}

final class EkycPending extends EkycResult {
  final String message;
  const EkycPending({required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EkycPending && message == other.message;

  @override
  int get hashCode => message.hashCode;
}

final class EkycError extends EkycResult {
  final String message;
  final Object? error;
  const EkycError({required this.message, this.error});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EkycError && message == other.message;

  @override
  int get hashCode => message.hashCode;
}

final class EkycUnavailable extends EkycResult {
  const EkycUnavailable();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EkycUnavailable;

  @override
  int get hashCode => runtimeType.hashCode;
}
