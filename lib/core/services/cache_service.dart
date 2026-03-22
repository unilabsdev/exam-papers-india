import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thrown when the device is offline and no local cache exists for a key.
class NoCacheException implements Exception {
  const NoCacheException();
  @override
  String toString() => 'NoCacheException: no cached data available';
}

/// Lightweight local cache backed by shared_preferences.
///
/// Keys:
///   cache_exams                          → List<ExamRow>  (includes icon_name)
///   cache_years_{examId}                 → List<YearRow>
///   cache_categories_{examId}_{year}     → List<CategoryRow> (includes icon_name)
///   cache_papers_{examId}_{year}_{catId} → List<PaperRow>
///
/// Each key also has a companion `{key}_ts` storing the save timestamp (ms).
/// Cache is considered fresh for 24 hours after saving.
class CacheService {
  static const _examsKey         = 'cache_exams';
  static const _yearsPrefix      = 'cache_years_';
  static const _categoriesPrefix = 'cache_categories_';
  static const _papersPrefix     = 'cache_papers_';

  static const Duration _ttl = Duration(hours: 24);

  // ── Freshness ─────────────────────────────────────────────────────────────

  /// Returns true if [key] was saved less than 24 hours ago.
  static Future<bool> isFresh(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('${key}_ts');
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age < _ttl.inMilliseconds;
  }

  static Future<void> _saveTs(SharedPreferences prefs, String key) async {
    await prefs.setInt('${key}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  // ── Exams ─────────────────────────────────────────────────────────────────

  static const examsKey = _examsKey;

  static Future<void> saveExams(List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_examsKey, jsonEncode(rows));
    await _saveTs(prefs, _examsKey);
  }

  static Future<List<Map<String, dynamic>>?> loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_examsKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // ── Years ─────────────────────────────────────────────────────────────────

  static String yearsKey(String examId) => '$_yearsPrefix$examId';

  static Future<void> saveYears(
    String examId,
    List<Map<String, dynamic>> rows,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = yearsKey(examId);
    await prefs.setString(key, jsonEncode(rows));
    await _saveTs(prefs, key);
  }

  static Future<List<Map<String, dynamic>>?> loadYears(String examId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(yearsKey(examId));
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // ── Categories ────────────────────────────────────────────────────────────

  static String categoriesKey(String examId, int year) =>
      '$_categoriesPrefix${examId}_$year';

  static Future<void> saveCategories(
    String examId,
    int year,
    List<Map<String, dynamic>> rows,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = categoriesKey(examId, year);
    await prefs.setString(key, jsonEncode(rows));
    await _saveTs(prefs, key);
  }

  static Future<List<Map<String, dynamic>>?> loadCategories(
    String examId,
    int year,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(categoriesKey(examId, year));
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // ── Papers ────────────────────────────────────────────────────────────────

  static String papersKey(String examId, int year, String categoryId) =>
      '$_papersPrefix${examId}_${year}_$categoryId';

  static Future<void> savePapers(
    String examId,
    int year,
    String categoryId,
    List<Map<String, dynamic>> rows,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = papersKey(examId, year, categoryId);
    await prefs.setString(key, jsonEncode(rows));
    await _saveTs(prefs, key);
  }

  static Future<List<Map<String, dynamic>>?> loadPapers(
    String examId,
    int year,
    String categoryId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(papersKey(examId, year, categoryId));
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }
}
