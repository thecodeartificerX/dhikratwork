// lib/utils/constants.dart
// Database-level constants. All table names and column names used in
// DatabaseService SQL queries are defined here. Never use raw strings in SQL.

// ---------------------------------------------------------------------------
// Database meta
// ---------------------------------------------------------------------------

/// SQLite database filename stored on disk.
const String kDatabaseName = 'dhikratwork.db';

/// Current schema version. Increment when adding migrations.
const int kDatabaseVersion = 1;

// ---------------------------------------------------------------------------
// Table: dhikr
// ---------------------------------------------------------------------------

const String tDhikr = 'dhikr';

const String cDhikrId = 'id';
const String cDhikrName = 'name';
const String cDhikrArabicText = 'arabic_text';
const String cDhikrTransliteration = 'transliteration';
const String cDhikrTranslation = 'translation';
const String cDhikrCategory = 'category';
const String cDhikrHadithReference = 'hadith_reference';
const String cDhikrIsPreloaded = 'is_preloaded';
const String cDhikrIsHidden = 'is_hidden';
const String cDhikrTargetCount = 'target_count';
const String cDhikrSortOrder = 'sort_order';
const String cDhikrCreatedAt = 'created_at';

// ---------------------------------------------------------------------------
// Table: dhikr_session
// ---------------------------------------------------------------------------

const String tDhikrSession = 'dhikr_session';

const String cSessionId = 'id';
const String cSessionDhikrId = 'dhikr_id';
const String cSessionCount = 'count';
const String cSessionStartedAt = 'started_at';
const String cSessionEndedAt = 'ended_at';
const String cSessionSource = 'source';

// ---------------------------------------------------------------------------
// Table: daily_summary
// ---------------------------------------------------------------------------

const String tDailySummary = 'daily_summary';

const String cSummaryId = 'id';
const String cSummaryDhikrId = 'dhikr_id';
const String cSummaryDate = 'date';
const String cSummaryTotalCount = 'total_count';
const String cSummarySessionCount = 'session_count';

// ---------------------------------------------------------------------------
// Table: goal
// ---------------------------------------------------------------------------

const String tGoal = 'goal';

const String cGoalId = 'id';
const String cGoalDhikrId = 'dhikr_id';
const String cGoalTargetCount = 'target_count';
const String cGoalPeriod = 'period';
const String cGoalIsActive = 'is_active';
const String cGoalCreatedAt = 'created_at';

// ---------------------------------------------------------------------------
// Table: achievement
// ---------------------------------------------------------------------------

const String tAchievement = 'achievement';

const String cAchievementId = 'id';
const String cAchievementKey = 'key';
const String cAchievementName = 'name';
const String cAchievementDescription = 'description';
const String cAchievementIconAsset = 'icon_asset';
const String cAchievementUnlockedAt = 'unlocked_at';

// ---------------------------------------------------------------------------
// Table: user_settings
// ---------------------------------------------------------------------------

const String tUserSettings = 'user_settings';

const String cSettingsId = 'id';
const String cSettingsActiveDhikrId = 'active_dhikr_id';
const String cSettingsGlobalHotkey = 'global_hotkey';
const String cSettingsWidgetVisible = 'widget_visible';
const String cSettingsWidgetPositionX = 'widget_position_x';
const String cSettingsWidgetPositionY = 'widget_position_y';
const String cSettingsWidgetDhikrIds = 'widget_dhikr_ids';
const String cSettingsThemeVariant = 'theme_variant';
const String cSettingsSubscriptionStatus = 'subscription_status';
const String cSettingsSubscriptionEmail = 'subscription_email';
const String cSettingsLastSubscriptionPrompt = 'last_subscription_prompt';
const String cSettingsCreatedAt = 'created_at';

// ---------------------------------------------------------------------------
// Table: streak
// ---------------------------------------------------------------------------

const String tStreak = 'streak';

const String cStreakId = 'id';
const String cStreakCurrentStreak = 'current_streak';
const String cStreakLongestStreak = 'longest_streak';
const String cStreakLastActiveDate = 'last_active_date';

// ---------------------------------------------------------------------------
// Domain value constants
// ---------------------------------------------------------------------------

/// Dhikr category values stored in [cDhikrCategory].
const String kCategoryGeneralTasbih = 'general_tasbih';
const String kCategoryPostSalah = 'post_salah';
const String kCategoryIstighfar = 'istighfar';
const String kCategorySalawat = 'salawat';
const String kCategoryDuaRemembrance = 'dua_remembrance';

/// Session source values stored in [cSessionSource].
const String kSourceHotkey = 'hotkey';
const String kSourceWidget = 'widget';
const String kSourceMainApp = 'main_app';

/// Goal period values stored in [cGoalPeriod].
const String kPeriodDaily = 'daily';
const String kPeriodWeekly = 'weekly';
const String kPeriodMonthly = 'monthly';

/// Subscription status values stored in [cSettingsSubscriptionStatus].
const String kSubscriptionFree = 'free';
const String kSubscriptionSubscribed = 'subscribed';

/// Default global hotkey combo.
const String kDefaultHotkey = 'ctrl+shift+d';

/// The single-row id enforced by CHECK constraint in user_settings and streak.
const int kSingleRowId = 1;

// ---------------------------------------------------------------------------
// Achievement key constants
// ---------------------------------------------------------------------------

const String kAchFirstDhikr = 'first_dhikr';
const String kAchCount100 = 'count_100';
const String kAchCount1000 = 'count_1000';
const String kAchCount10000 = 'count_10000';
const String kAchCount100000 = 'count_100000';
const String kAchStreak3 = 'streak_3';
const String kAchStreak7 = 'streak_7';
const String kAchStreak30 = 'streak_30';
const String kAchStreak100 = 'streak_100';
const String kAchGoalFirst = 'goal_first';
const String kAchGoalComplete = 'goal_complete';
const String kAchCustomDhikr = 'custom_dhikr';
const String kAchAllCategories = 'all_categories';
