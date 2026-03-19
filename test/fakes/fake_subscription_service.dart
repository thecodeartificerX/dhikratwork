// test/fakes/fake_subscription_service.dart

import 'package:dhikratwork/services/subscription_service.dart';

/// In-memory fake of [SubscriptionService] for use in unit and widget tests.
class FakeSubscriptionService implements SubscriptionService {
  /// Map of email → isActive. Seed in tests.
  final Map<String, bool> _statusMap;
  bool simulateOffline;

  FakeSubscriptionService({
    Map<String, bool>? statusMap,
    this.simulateOffline = false,
  }) : _statusMap = statusMap ?? {};

  @override
  Future<bool> checkSubscription(String email) async {
    if (simulateOffline) throw const SubscriptionOfflineException();
    return _statusMap[email.toLowerCase().trim()] ?? false;
  }

  @override
  Future<bool> refreshStatus(String email) => checkSubscription(email);
}
