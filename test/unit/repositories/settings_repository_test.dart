// test/unit/repositories/settings_repository_test.dart

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dhikratwork/repositories/settings_repository.dart';
import 'package:dhikratwork/utils/constants.dart';
import '../../fakes/fake_database_service.dart';

void main() {
  late FakeDatabaseService fakeDb;
  late SettingsRepository repo;

  setUp(() {
    fakeDb = FakeDatabaseService();
    repo = SettingsRepository(fakeDb);
  });

  tearDown(() => fakeDb.reset());

  // -------------------------------------------------------------------------
  // getSettings — initial state (no row)
  // -------------------------------------------------------------------------

  group('getSettings — first call (no row in DB)', () {
    test('creates and returns a default settings row', () async {
      final settings = await repo.getSettings();
      expect(settings, isNotNull);
      expect(settings.id, kSingleRowId);
      expect(settings.globalHotkey, kDefaultHotkey);
      expect(settings.subscriptionStatus, kSubscriptionFree);
      expect(settings.widgetVisible, isTrue);
    });

    test('inserts the default row into the database', () async {
      await repo.getSettings();
      final rows = fakeDb.tableRows(tUserSettings);
      expect(rows.length, 1);
      expect(rows.first[cSettingsId], kSingleRowId);
    });
  });

  // -------------------------------------------------------------------------
  // getSettings — subsequent call (row exists)
  // -------------------------------------------------------------------------

  group('getSettings — row already exists', () {
    test('reads the existing row without creating a new one', () async {
      await repo.getSettings(); // Creates the row
      await repo.getSettings(); // Should reuse it
      final rows = fakeDb.tableRows(tUserSettings);
      expect(rows.length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // updateSettings
  // -------------------------------------------------------------------------

  group('updateSettings', () {
    test('persists all changed fields', () async {
      final original = await repo.getSettings();
      final modified = original.copyWith(
        globalHotkey: 'ctrl+alt+d',
        widgetVisible: false,
        subscriptionStatus: kSubscriptionSubscribed,
      );
      await repo.updateSettings(modified);
      final fresh = await repo.getSettings();
      expect(fresh.globalHotkey, 'ctrl+alt+d');
      expect(fresh.widgetVisible, isFalse);
      expect(fresh.subscriptionStatus, kSubscriptionSubscribed);
    });
  });

  // -------------------------------------------------------------------------
  // setActiveDhikr
  // -------------------------------------------------------------------------

  group('setActiveDhikr', () {
    test('updates active_dhikr_id', () async {
      await repo.getSettings();
      await repo.setActiveDhikr(42);
      final settings = await repo.getSettings();
      expect(settings.activeDhikrId, 42);
    });

    test('can clear active dhikr with null', () async {
      await repo.getSettings();
      await repo.setActiveDhikr(42);
      await repo.setActiveDhikr(null);
      final settings = await repo.getSettings();
      expect(settings.activeDhikrId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // setHotkey
  // -------------------------------------------------------------------------

  group('setHotkey', () {
    test('updates global_hotkey', () async {
      await repo.getSettings();
      await repo.setHotkey('ctrl+alt+z');
      final settings = await repo.getSettings();
      expect(settings.globalHotkey, 'ctrl+alt+z');
    });
  });

  // -------------------------------------------------------------------------
  // setWidgetVisible
  // -------------------------------------------------------------------------

  group('setWidgetVisible', () {
    test('can set visible to false', () async {
      await repo.getSettings();
      await repo.setWidgetVisible(false);
      final settings = await repo.getSettings();
      expect(settings.widgetVisible, isFalse);
    });

    test('can set visible back to true', () async {
      await repo.getSettings();
      await repo.setWidgetVisible(false);
      await repo.setWidgetVisible(true);
      final settings = await repo.getSettings();
      expect(settings.widgetVisible, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // setWidgetPosition
  // -------------------------------------------------------------------------

  group('setWidgetPosition', () {
    test('persists x and y coordinates', () async {
      await repo.getSettings();
      await repo.setWidgetPosition(100.5, 200.75);
      final settings = await repo.getSettings();
      expect(settings.widgetPositionX, closeTo(100.5, 0.001));
      expect(settings.widgetPositionY, closeTo(200.75, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // setWidgetDhikrIds
  // -------------------------------------------------------------------------

  group('setWidgetDhikrIds', () {
    test('persists list of ids as JSON string', () async {
      await repo.getSettings();
      await repo.setWidgetDhikrIds([1, 3, 7]);
      final settings = await repo.getSettings();
      // widgetDhikrIds is stored as a JSON string in the model
      expect(settings.widgetDhikrIds, isNotNull);
      final decoded = jsonDecode(settings.widgetDhikrIds!) as List<dynamic>;
      expect(decoded.cast<int>(), [1, 3, 7]);
    });

    test('can set an empty list', () async {
      await repo.getSettings();
      await repo.setWidgetDhikrIds([]);
      final settings = await repo.getSettings();
      final decoded = jsonDecode(settings.widgetDhikrIds!) as List<dynamic>;
      expect(decoded, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // setSubscriptionStatus
  // -------------------------------------------------------------------------

  group('setSubscriptionStatus', () {
    test('sets status and email together', () async {
      await repo.getSettings();
      await repo.setSubscriptionStatus(kSubscriptionSubscribed, 'test@test.com');
      final settings = await repo.getSettings();
      expect(settings.subscriptionStatus, kSubscriptionSubscribed);
      expect(settings.subscriptionEmail, 'test@test.com');
    });

    test('can set status with null email', () async {
      await repo.getSettings();
      await repo.setSubscriptionStatus(kSubscriptionFree, null);
      final settings = await repo.getSettings();
      expect(settings.subscriptionStatus, kSubscriptionFree);
      expect(settings.subscriptionEmail, isNull);
    });
  });
}
