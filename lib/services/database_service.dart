// lib/services/database_service.dart
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dhikratwork/data/preloaded_dhikr.dart';
import 'package:dhikratwork/utils/constants.dart';

/// Stateless service that owns the SQLite connection and executes raw SQL.
///
/// - All table and column names are referenced via constants from constants.dart.
/// - All queries use [whereArgs] — never string interpolation.
/// - Repositories are the only callers of this service.
///
/// Pass [dbPath] to override the default on-disk path (e.g. for in-memory
/// testing: `DatabaseService(dbPath: inMemoryDatabasePath)`).
class DatabaseService {
  DatabaseService._({String? dbPath}) : _dbPath = dbPath;

  static final DatabaseService instance = DatabaseService._();

  final String? _dbPath;
  Database? _database;

  /// Whether the database connection is currently open.
  bool get isOpen => _database != null && _database!.isOpen;

  /// Factory constructor for testing — pass an explicit path or
  /// [inMemoryDatabasePath] for a throwaway in-memory database.
  factory DatabaseService({String? dbPath}) {
    return DatabaseService._(dbPath: dbPath);
  }

  /// Explicitly opens the database. Idempotent — safe to call multiple times.
  /// Tests should call this in setUp; production code can use [database] getter.
  Future<void> open() async {
    if (_database != null && _database!.isOpen) return;
    _database = await _open();
  }

  /// Returns the open database, opening it lazily on first access.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  // ---------------------------------------------------------------------------
  // Open / Init
  // ---------------------------------------------------------------------------

  Future<Database> _open() async {
    final resolvedPath = _dbPath ??
        p.join(
          await databaseFactoryFfi.getDatabasesPath(),
          kDatabaseName,
        );
    return databaseFactoryFfi.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: kDatabaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _seedAchievements(db);
    await _seedPreloadedDhikr(db);
    await _seedDefaultSettings(db);
    await _seedDefaultStreak(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Version-based forward migration. Never drop tables.
    // Example for future v2:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $tDhikr ADD COLUMN new_col TEXT');
    // }
  }

  // ---------------------------------------------------------------------------
  // Schema creation
  // ---------------------------------------------------------------------------

  Future<void> _createTables(Database db) async {
    // dhikr
    await db.execute('''
      CREATE TABLE $tDhikr (
        $cDhikrId INTEGER PRIMARY KEY AUTOINCREMENT,
        $cDhikrName TEXT NOT NULL,
        $cDhikrArabicText TEXT NOT NULL,
        $cDhikrTransliteration TEXT NOT NULL,
        $cDhikrTranslation TEXT NOT NULL,
        $cDhikrCategory TEXT NOT NULL,
        $cDhikrHadithReference TEXT,
        $cDhikrIsPreloaded INTEGER NOT NULL DEFAULT 0,
        $cDhikrIsHidden INTEGER NOT NULL DEFAULT 0,
        $cDhikrTargetCount INTEGER,
        $cDhikrSortOrder INTEGER NOT NULL DEFAULT 0,
        $cDhikrCreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // dhikr_session
    await db.execute('''
      CREATE TABLE $tDhikrSession (
        $cSessionId INTEGER PRIMARY KEY AUTOINCREMENT,
        $cSessionDhikrId INTEGER NOT NULL REFERENCES $tDhikr($cDhikrId),
        $cSessionCount INTEGER NOT NULL DEFAULT 0,
        $cSessionStartedAt TEXT NOT NULL DEFAULT (datetime('now')),
        $cSessionEndedAt TEXT,
        $cSessionSource TEXT NOT NULL DEFAULT '$kSourceMainApp'
      )
    ''');

    // daily_summary
    await db.execute('''
      CREATE TABLE $tDailySummary (
        $cSummaryId INTEGER PRIMARY KEY AUTOINCREMENT,
        $cSummaryDhikrId INTEGER NOT NULL REFERENCES $tDhikr($cDhikrId),
        $cSummaryDate TEXT NOT NULL,
        $cSummaryTotalCount INTEGER NOT NULL DEFAULT 0,
        $cSummarySessionCount INTEGER NOT NULL DEFAULT 0,
        UNIQUE($cSummaryDhikrId, $cSummaryDate)
      )
    ''');

    // goal
    await db.execute('''
      CREATE TABLE $tGoal (
        $cGoalId INTEGER PRIMARY KEY AUTOINCREMENT,
        $cGoalDhikrId INTEGER REFERENCES $tDhikr($cDhikrId),
        $cGoalTargetCount INTEGER NOT NULL,
        $cGoalPeriod TEXT NOT NULL,
        $cGoalIsActive INTEGER NOT NULL DEFAULT 1,
        $cGoalCreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // achievement
    await db.execute('''
      CREATE TABLE $tAchievement (
        $cAchievementId INTEGER PRIMARY KEY AUTOINCREMENT,
        $cAchievementKey TEXT NOT NULL UNIQUE,
        $cAchievementName TEXT NOT NULL,
        $cAchievementDescription TEXT NOT NULL,
        $cAchievementIconAsset TEXT NOT NULL,
        $cAchievementUnlockedAt TEXT
      )
    ''');

    // user_settings (single row enforced by CHECK)
    await db.execute('''
      CREATE TABLE $tUserSettings (
        $cSettingsId INTEGER PRIMARY KEY CHECK ($cSettingsId = $kSingleRowId),
        $cSettingsActiveDhikrId INTEGER REFERENCES $tDhikr($cDhikrId),
        $cSettingsGlobalHotkey TEXT DEFAULT '$kDefaultHotkey',
        $cSettingsWidgetVisible INTEGER NOT NULL DEFAULT 1,
        $cSettingsWidgetPositionX REAL,
        $cSettingsWidgetPositionY REAL,
        $cSettingsWidgetDhikrIds TEXT,
        $cSettingsThemeVariant TEXT DEFAULT 'default',
        $cSettingsSubscriptionStatus TEXT NOT NULL DEFAULT '$kSubscriptionFree',
        $cSettingsSubscriptionEmail TEXT,
        $cSettingsLastSubscriptionPrompt TEXT,
        $cSettingsCreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // streak (single row enforced by CHECK)
    await db.execute('''
      CREATE TABLE $tStreak (
        $cStreakId INTEGER PRIMARY KEY CHECK ($cStreakId = $kSingleRowId),
        $cStreakCurrentStreak INTEGER NOT NULL DEFAULT 0,
        $cStreakLongestStreak INTEGER NOT NULL DEFAULT 0,
        $cStreakLastActiveDate TEXT
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------------

  Future<void> _seedPreloadedDhikr(Database db) async {
    final rows = getPreloadedDhikrMaps();
    for (final row in rows) {
      await db.insert(tDhikr, row);
    }
  }

  Future<void> _seedAchievements(Database db) async {
    final achievements = <Map<String, dynamic>>[
      {
        cAchievementKey: kAchFirstDhikr,
        cAchievementName: 'First Step',
        cAchievementDescription: 'Complete your first dhikr',
        cAchievementIconAsset: 'assets/icons/ach_first_dhikr.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchCount100,
        cAchievementName: 'Centurion',
        cAchievementDescription: '100 total presses',
        cAchievementIconAsset: 'assets/icons/ach_count_100.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchCount1000,
        cAchievementName: 'Devoted',
        cAchievementDescription: '1,000 total presses',
        cAchievementIconAsset: 'assets/icons/ach_count_1000.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchCount10000,
        cAchievementName: 'Steadfast',
        cAchievementDescription: '10,000 total presses',
        cAchievementIconAsset: 'assets/icons/ach_count_10000.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchCount100000,
        cAchievementName: 'Unwavering',
        cAchievementDescription: '100,000 total presses',
        cAchievementIconAsset: 'assets/icons/ach_count_100000.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchStreak3,
        cAchievementName: 'Consistent',
        cAchievementDescription: '3-day streak',
        cAchievementIconAsset: 'assets/icons/ach_streak_3.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchStreak7,
        cAchievementName: 'Weekly Warrior',
        cAchievementDescription: '7-day streak',
        cAchievementIconAsset: 'assets/icons/ach_streak_7.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchStreak30,
        cAchievementName: 'Monthly Mujahid',
        cAchievementDescription: '30-day streak',
        cAchievementIconAsset: 'assets/icons/ach_streak_30.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchStreak100,
        cAchievementName: 'Centurion of Days',
        cAchievementDescription: '100-day streak',
        cAchievementIconAsset: 'assets/icons/ach_streak_100.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchGoalFirst,
        cAchievementName: 'Goal Setter',
        cAchievementDescription: 'Set your first goal',
        cAchievementIconAsset: 'assets/icons/ach_goal_first.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchGoalComplete,
        cAchievementName: 'Achiever',
        cAchievementDescription: 'Complete a goal',
        cAchievementIconAsset: 'assets/icons/ach_goal_complete.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchCustomDhikr,
        cAchievementName: 'Personal Touch',
        cAchievementDescription: 'Create a custom dhikr',
        cAchievementIconAsset: 'assets/icons/ach_custom_dhikr.png',
        cAchievementUnlockedAt: null,
      },
      {
        cAchievementKey: kAchAllCategories,
        cAchievementName: 'Well-Rounded',
        cAchievementDescription: 'Dhikr from every category in one day',
        cAchievementIconAsset: 'assets/icons/ach_all_categories.png',
        cAchievementUnlockedAt: null,
      },
    ];

    for (final row in achievements) {
      await db.insert(tAchievement, row);
    }
  }

  Future<void> _seedDefaultSettings(Database db) async {
    await db.insert(tUserSettings, <String, dynamic>{
      cSettingsId: kSingleRowId,
      cSettingsGlobalHotkey: kDefaultHotkey,
      cSettingsWidgetVisible: 1,
      cSettingsSubscriptionStatus: kSubscriptionFree,
      cSettingsCreatedAt: DateTime.now().toIso8601String(),
    });
  }

  Future<void> _seedDefaultStreak(Database db) async {
    await db.insert(tStreak, <String, dynamic>{
      cStreakId: kSingleRowId,
      cStreakCurrentStreak: 0,
      cStreakLongestStreak: 0,
      cStreakLastActiveDate: null,
    });
  }

  // ---------------------------------------------------------------------------
  // Generic CRUD wrappers (for use by Repositories)
  // ---------------------------------------------------------------------------

  /// Insert a row into [table]. Returns the new row id.
  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await database;
    return db.insert(
      table,
      values,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Query [table] with optional filtering.
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Update rows in [table] matching [where].
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await database;
    return db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Delete rows from [table] matching [where].
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Execute a raw SQL query and return result rows.
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  /// Execute a raw SQL statement (DDL, pragma, etc.) with no return value.
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  // ---------------------------------------------------------------------------
  // CRUD: dhikr
  // ---------------------------------------------------------------------------

  Future<int> insertDhikr(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(tDhikr, row);
  }

  Future<List<Map<String, dynamic>>> queryAllDhikr({
    bool includeHidden = false,
  }) async {
    final db = await database;
    if (includeHidden) {
      return db.query(tDhikr, orderBy: '$cDhikrSortOrder ASC, $cDhikrId ASC');
    }
    return db.query(
      tDhikr,
      where: '$cDhikrIsHidden = ?',
      whereArgs: <int>[0],
      orderBy: '$cDhikrSortOrder ASC, $cDhikrId ASC',
    );
  }

  Future<List<Map<String, dynamic>>> queryDhikrByCategory(
    String category,
  ) async {
    final db = await database;
    return db.query(
      tDhikr,
      where: '$cDhikrCategory = ? AND $cDhikrIsHidden = ?',
      whereArgs: <dynamic>[category, 0],
      orderBy: '$cDhikrSortOrder ASC',
    );
  }

  Future<Map<String, dynamic>?> queryDhikrById(int id) async {
    final db = await database;
    final rows = await db.query(
      tDhikr,
      where: '$cDhikrId = ?',
      whereArgs: <int>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> updateDhikr(int id, Map<String, dynamic> row) async {
    final db = await database;
    return db.update(
      tDhikr,
      row,
      where: '$cDhikrId = ?',
      whereArgs: <int>[id],
    );
  }

  /// Soft-delete for preloaded dhikr (sets is_hidden = 1).
  Future<int> hideDhikr(int id) async {
    final db = await database;
    return db.update(
      tDhikr,
      <String, dynamic>{cDhikrIsHidden: 1},
      where: '$cDhikrId = ? AND $cDhikrIsPreloaded = ?',
      whereArgs: <int>[id, 1],
    );
  }

  /// Hard-delete only for user-created dhikr (is_preloaded = 0).
  Future<int> deleteDhikr(int id) async {
    final db = await database;
    return db.delete(
      tDhikr,
      where: '$cDhikrId = ? AND $cDhikrIsPreloaded = ?',
      whereArgs: <int>[id, 0],
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD: dhikr_session
  // ---------------------------------------------------------------------------

  Future<int> insertSession(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(tDhikrSession, row);
  }

  Future<List<Map<String, dynamic>>> querySessionsByDhikr(int dhikrId) async {
    final db = await database;
    return db.query(
      tDhikrSession,
      where: '$cSessionDhikrId = ?',
      whereArgs: <int>[dhikrId],
      orderBy: '$cSessionStartedAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> querySessionsForDate(String date) async {
    final db = await database;
    // date is 'YYYY-MM-DD'; started_at is ISO datetime — match by prefix
    return db.query(
      tDhikrSession,
      where: '$cSessionStartedAt LIKE ?',
      whereArgs: <String>['$date%'],
      orderBy: '$cSessionStartedAt DESC',
    );
  }

  Future<int> updateSession(int id, Map<String, dynamic> row) async {
    final db = await database;
    return db.update(
      tDhikrSession,
      row,
      where: '$cSessionId = ?',
      whereArgs: <int>[id],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return db.delete(
      tDhikrSession,
      where: '$cSessionId = ?',
      whereArgs: <int>[id],
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD: daily_summary
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> querySummary(int dhikrId, String date) async {
    final db = await database;
    final rows = await db.query(
      tDailySummary,
      where: '$cSummaryDhikrId = ? AND $cSummaryDate = ?',
      whereArgs: <dynamic>[dhikrId, date],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> querySummariesForDate(
    String date,
  ) async {
    final db = await database;
    return db.query(
      tDailySummary,
      where: '$cSummaryDate = ?',
      whereArgs: <String>[date],
    );
  }

  Future<List<Map<String, dynamic>>> querySummariesForDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    return db.query(
      tDailySummary,
      where: '$cSummaryDate >= ? AND $cSummaryDate <= ?',
      whereArgs: <String>[startDate, endDate],
      orderBy: '$cSummaryDate ASC',
    );
  }

  /// Upserts a daily summary row. If none exists for (dhikrId, date), inserts.
  /// Otherwise increments totals by [countDelta] and [sessionDelta].
  Future<void> upsertDailySummary({
    required int dhikrId,
    required String date,
    required int countDelta,
    int sessionDelta = 0,
  }) async {
    final db = await database;
    final existing = await querySummary(dhikrId, date);
    if (existing == null) {
      await db.insert(tDailySummary, <String, dynamic>{
        cSummaryDhikrId: dhikrId,
        cSummaryDate: date,
        cSummaryTotalCount: countDelta,
        cSummarySessionCount: sessionDelta,
      });
    } else {
      final newTotal = (existing[cSummaryTotalCount] as int) + countDelta;
      final newSessions =
          (existing[cSummarySessionCount] as int) + sessionDelta;
      await db.update(
        tDailySummary,
        <String, dynamic>{
          cSummaryTotalCount: newTotal,
          cSummarySessionCount: newSessions,
        },
        where: '$cSummaryDhikrId = ? AND $cSummaryDate = ?',
        whereArgs: <dynamic>[dhikrId, date],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CRUD: goal
  // ---------------------------------------------------------------------------

  Future<int> insertGoal(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(tGoal, row);
  }

  Future<List<Map<String, dynamic>>> queryActiveGoals() async {
    final db = await database;
    return db.query(
      tGoal,
      where: '$cGoalIsActive = ?',
      whereArgs: <int>[1],
      orderBy: '$cGoalCreatedAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> queryAllGoals() async {
    final db = await database;
    return db.query(tGoal, orderBy: '$cGoalCreatedAt DESC');
  }

  Future<int> updateGoal(int id, Map<String, dynamic> row) async {
    final db = await database;
    return db.update(
      tGoal,
      row,
      where: '$cGoalId = ?',
      whereArgs: <int>[id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return db.delete(
      tGoal,
      where: '$cGoalId = ?',
      whereArgs: <int>[id],
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD: achievement
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> queryAllAchievements() async {
    final db = await database;
    return db.query(tAchievement, orderBy: '$cAchievementId ASC');
  }

  Future<Map<String, dynamic>?> queryAchievementByKey(String key) async {
    final db = await database;
    final rows = await db.query(
      tAchievement,
      where: '$cAchievementKey = ?',
      whereArgs: <String>[key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Marks an achievement as unlocked by setting [cAchievementUnlockedAt].
  /// No-op if already unlocked.
  Future<int> unlockAchievement(String key, String unlockedAt) async {
    final db = await database;
    return db.update(
      tAchievement,
      <String, dynamic>{cAchievementUnlockedAt: unlockedAt},
      where: '$cAchievementKey = ? AND $cAchievementUnlockedAt IS NULL',
      whereArgs: <String>[key],
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD: user_settings (single row)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> querySettings() async {
    final db = await database;
    final rows = await db.query(
      tUserSettings,
      where: '$cSettingsId = ?',
      whereArgs: <int>[kSingleRowId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> updateSettings(Map<String, dynamic> row) async {
    final db = await database;
    return db.update(
      tUserSettings,
      row,
      where: '$cSettingsId = ?',
      whereArgs: <int>[kSingleRowId],
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD: streak (single row)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> queryStreak() async {
    final db = await database;
    final rows = await db.query(
      tStreak,
      where: '$cStreakId = ?',
      whereArgs: <int>[kSingleRowId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> updateStreak(Map<String, dynamic> row) async {
    final db = await database;
    return db.update(
      tStreak,
      row,
      where: '$cStreakId = ?',
      whereArgs: <int>[kSingleRowId],
    );
  }

  // ---------------------------------------------------------------------------
  // Utility
  // ---------------------------------------------------------------------------

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
