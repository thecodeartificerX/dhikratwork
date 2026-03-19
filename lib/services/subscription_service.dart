// lib/services/subscription_service.dart

import 'dart:async';

/// Thrown when the device is offline and no cached subscription data is available.
class SubscriptionOfflineException implements Exception {
  const SubscriptionOfflineException();
  @override
  String toString() => 'SubscriptionOfflineException: device is offline';
}

/// Stateless read-only subscription verification interface.
///
/// Implementations check whether [email] holds an active subscription.
abstract interface class SubscriptionService {
  /// Returns true if [email] has an active subscription.
  ///
  /// Throws [SubscriptionOfflineException] if offline and no cached data
  /// is available for this email.
  Future<bool> checkSubscription(String email);

  /// Force-refreshes cached data and re-checks [email] status.
  Future<bool> refreshStatus(String email);
}

/// MVP stub that always reports "not subscribed".
///
/// Swap this out for a real implementation (e.g. Firestore, REST) once
/// subscription billing is wired up.
class NoOpSubscriptionService implements SubscriptionService {
  @override
  Future<bool> checkSubscription(String email) async => false;

  @override
  Future<bool> refreshStatus(String email) async => false;
}
