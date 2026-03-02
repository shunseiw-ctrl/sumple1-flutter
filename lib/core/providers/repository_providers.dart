import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/job_repository.dart';
import '../../data/repositories/application_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/earnings_repository.dart';

/// JobRepository プロバイダー
final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository();
});

/// ApplicationRepository プロバイダー
final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepository();
});

/// NotificationRepository プロバイダー
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// EarningsRepository プロバイダー
final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return EarningsRepository();
});
