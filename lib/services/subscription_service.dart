// lib/services/subscription_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Thrown when the device is offline and no cached Firestore data is available.
class SubscriptionOfflineException implements Exception {
  const SubscriptionOfflineException();
  @override
  String toString() => 'SubscriptionOfflineException: device is offline';
}

/// Stateless read-only wrapper around the Firestore `subscribers` collection.
///
/// Firestore security rules must allow: read `subscribers/{email}` by any
/// authenticated-or-anonymous client. No write access is ever granted to the
/// client. Backend setup (Cloud Function + Stripe webhook) is out of scope.
abstract interface class SubscriptionService {
  /// Returns true if [email] has `status == 'active'` in Firestore.
  ///
  /// Throws [SubscriptionOfflineException] if offline and Firestore has no
  /// cached document for this email.
  Future<bool> checkSubscription(String email);

  /// Force-refreshes Firestore cache and re-checks [email] status.
  Future<bool> refreshStatus(String email);
}

class FirestoreSubscriptionService implements SubscriptionService {
  final FirebaseFirestore _firestore;

  FirestoreSubscriptionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  FirestoreSubscriptionService.withInstance(this._firestore);

  @override
  Future<bool> checkSubscription(String email) async {
    final key = email.toLowerCase().trim();
    try {
      final doc = await _firestore
          .collection('subscribers')
          .doc(key)
          .get(const GetOptions(source: Source.serverAndCache));
      if (!doc.exists) return false;
      return doc.data()?['status'] == 'active';
    } on FirebaseException catch (e) {
      // Firestore maps offline errors to unavailable/failed-precondition codes.
      if (e.code == 'unavailable' || e.code == 'failed-precondition') {
        // Try cache-only fallback before giving up.
        try {
          final cached = await _firestore
              .collection('subscribers')
              .doc(key)
              .get(const GetOptions(source: Source.cache));
          return cached.data()?['status'] == 'active';
        } catch (_) {
          throw const SubscriptionOfflineException();
        }
      }
      rethrow;
    }
  }

  @override
  Future<bool> refreshStatus(String email) async {
    final key = email.toLowerCase().trim();
    try {
      final doc = await _firestore
          .collection('subscribers')
          .doc(key)
          .get(const GetOptions(source: Source.server));
      if (!doc.exists) return false;
      return doc.data()?['status'] == 'active';
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'failed-precondition') {
        throw const SubscriptionOfflineException();
      }
      rethrow;
    }
  }
}
