// lib/data/preloaded_dhikr.dart
import 'package:dhikratwork/utils/constants.dart';

/// Returns all preloaded dhikr seed rows as raw maps for SQLite insertion.
///
/// Arabic text includes full tashkeel (harakat) as specified in the design doc.
/// All entries have [cDhikrIsPreloaded] = 1 and [cDhikrIsHidden] = 0.
/// The [cDhikrId] field is intentionally omitted so AUTOINCREMENT assigns IDs.
List<Map<String, dynamic>> getPreloadedDhikrMaps() {
  return <Map<String, dynamic>>[
    // -------------------------------------------------------------------------
    // General Tasbih (sort_order 0–5)
    // -------------------------------------------------------------------------
    {
      cDhikrName: 'SubhanAllah',
      cDhikrArabicText: 'سُبْحَانَ اللَّهِ',
      cDhikrTransliteration: 'Subhanallah',
      cDhikrTranslation: 'Glory be to Allah',
      cDhikrCategory: kCategoryGeneralTasbih,
      cDhikrHadithReference: 'Quran 17:43',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: null,
      cDhikrSortOrder: 0,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },
    {
      cDhikrName: 'Alhamdulillah',
      cDhikrArabicText: 'اَلْحَمْدُ لِلَّهِ',
      cDhikrTransliteration: 'Al-hamdu lillah',
      cDhikrTranslation: 'All praise is due to Allah',
      cDhikrCategory: kCategoryGeneralTasbih,
      cDhikrHadithReference: 'Quran 1:2',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: null,
      cDhikrSortOrder: 1,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },
    {
      cDhikrName: 'Allahu Akbar',
      cDhikrArabicText: 'اللَّهُ أَكْبَرُ',
      cDhikrTransliteration: 'Allahu Akbar',
      cDhikrTranslation: 'Allah is the Greatest',
      cDhikrCategory: kCategoryGeneralTasbih,
      cDhikrHadithReference: 'Bukhari/Muslim',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: null,
      cDhikrSortOrder: 2,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },
    {
      cDhikrName: 'La ilaha illAllah',
      cDhikrArabicText: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
      cDhikrTransliteration: 'La ilaha illallah',
      cDhikrTranslation: 'There is no god but Allah',
      cDhikrCategory: kCategoryGeneralTasbih,
      cDhikrHadithReference: 'Quran 47:19',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: null,
      cDhikrSortOrder: 3,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },
    {
      cDhikrName: 'SubhanAllahi wa bihamdih',
      cDhikrArabicText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      cDhikrTransliteration: 'Subhanallahi wa bihamdih',
      cDhikrTranslation: 'Glory and praise be to Allah',
      cDhikrCategory: kCategoryGeneralTasbih,
      cDhikrHadithReference: 'Bukhari 6405',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: null,
      cDhikrSortOrder: 4,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },
    {
      cDhikrName: 'SubhanAllahil Azeem',
      cDhikrArabicText: 'سُبْحَانَ اللَّهِ الْعَظِيمِ',
      cDhikrTransliteration: 'Subhanallahil Azeem',
      cDhikrTranslation: 'Glory be to Allah, the Magnificent',
      cDhikrCategory: kCategoryGeneralTasbih,
      cDhikrHadithReference: 'Bukhari 6406',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: null,
      cDhikrSortOrder: 5,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },

    // -------------------------------------------------------------------------
    // Post-Salah (sort_order 10–13)
    // -------------------------------------------------------------------------
    {
      cDhikrName: 'SubhanAllah (post-salah)',
      cDhikrArabicText: 'سُبْحَانَ اللَّهِ',
      cDhikrTransliteration: 'Subhanallah',
      cDhikrTranslation: 'Glory be to Allah',
      cDhikrCategory: kCategoryPostSalah,
      cDhikrHadithReference: 'Muslim 597',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: 33,
      cDhikrSortOrder: 10,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },
    {
      cDhikrName: 'Alhamdulillah (post-salah)',
      cDhikrArabicText: 'اَلْحَمْدُ لِلَّهِ',
      cDhikrTransliteration: 'Al-hamdu lillah',
      cDhikrTranslation: 'All praise is due to Allah',
      cDhikrCategory: kCategoryPostSalah,
      cDhikrHadithReference: 'Muslim 597',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: 33,
      cDhikrSortOrder: 11,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },
    {
      cDhikrName: 'Allahu Akbar (post-salah)',
      cDhikrArabicText: 'اللَّهُ أَكْبَرُ',
      cDhikrTransliteration: 'Allahu Akbar',
      cDhikrTranslation: 'Allah is the Greatest',
      cDhikrCategory: kCategoryPostSalah,
      cDhikrHadithReference: 'Muslim 597',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: 34,
      cDhikrSortOrder: 12,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },
    {
      cDhikrName: 'Ayat al-Kursi',
      cDhikrArabicText:
          'آيَةُ الْكُرْسِيِّ',
      cDhikrTransliteration: 'Ayat al-Kursi',
      cDhikrTranslation: 'The Throne Verse (Quran 2:255)',
      cDhikrCategory: kCategoryPostSalah,
      cDhikrHadithReference: 'Quran 2:255',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: 1,
      cDhikrSortOrder: 13,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },

    // -------------------------------------------------------------------------
    // Istighfar (sort_order 20–21)
    // -------------------------------------------------------------------------
    {
      cDhikrName: 'Astaghfirullah',
      cDhikrArabicText: 'أَسْتَغْفِرُ اللَّهَ',
      cDhikrTransliteration: 'Astaghfirullah',
      cDhikrTranslation: 'I seek forgiveness from Allah',
      cDhikrCategory: kCategoryIstighfar,
      cDhikrHadithReference: 'Riyad as-Salihin',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: null,
      cDhikrSortOrder: 20,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },
    {
      cDhikrName: 'Sayyid al-Istighfar',
      cDhikrArabicText:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي، فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
      cDhikrTransliteration: 'Allahumma anta rabbi la ilaha illa anta...',
      cDhikrTranslation: 'The master supplication for forgiveness',
      cDhikrCategory: kCategoryIstighfar,
      cDhikrHadithReference: 'Bukhari 6306',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: null,
      cDhikrSortOrder: 21,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },

    // -------------------------------------------------------------------------
    // Salawat (sort_order 30)
    // -------------------------------------------------------------------------
    {
      cDhikrName: 'Durood Ibrahim',
      cDhikrArabicText:
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
      cDhikrTransliteration:
          "Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad...",
      cDhikrTranslation:
          'O Allah, send blessings upon Muhammad and the family of Muhammad...',
      cDhikrCategory: kCategorySalawat,
      cDhikrHadithReference: 'Bukhari 3370',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: null,
      cDhikrSortOrder: 30,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },

    // -------------------------------------------------------------------------
    // Dua & Remembrance (sort_order 40–41)
    // -------------------------------------------------------------------------
    {
      cDhikrName: 'Hawqala',
      cDhikrArabicText: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      cDhikrTransliteration: 'La hawla wa la quwwata illa billah',
      cDhikrTranslation:
          'There is no power nor strength except with Allah',
      cDhikrCategory: kCategoryDuaRemembrance,
      cDhikrHadithReference: 'Bukhari 4205',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: null,
      cDhikrSortOrder: 40,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },
    {
      cDhikrName: 'HasbunAllah',
      cDhikrArabicText: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      cDhikrTransliteration: "Hasbunallah wa ni'mal wakeel",
      cDhikrTranslation:
          'Allah is sufficient for us, and He is the best Disposer of affairs',
      cDhikrCategory: kCategoryDuaRemembrance,
      cDhikrHadithReference: 'Quran 3:173',
      cDhikrIsPreloaded: 1,
      cDhikrIsHidden: 0,
      cDhikrTargetCount: null,
      cDhikrSortOrder: 41,
      cDhikrCreatedAt: '2026-03-19 00:00:00',
    },
  ];
}
