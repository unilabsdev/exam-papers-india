import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/year_model.dart';
import 'year_repository.dart';

/// Live Supabase implementation of [IYearRepository].
///
/// Expected table: `exam_years`
/// Columns: id SERIAL, exam_id TEXT, year INTEGER,
///          paper_count INTEGER, is_latest BOOLEAN
class SupabaseYearRepository implements IYearRepository {
  static const String _table = 'exam_years';

  final SupabaseClient _client;
  const SupabaseYearRepository(this._client);

  @override
  Future<List<YearModel>> getYears(String examId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('exam_id', examId)
        .order('year', ascending: false);

    final yearRows = rows as List<dynamic>;
    if (yearRows.isEmpty) return [];

    // Live paper count per year from papers table
    final years = yearRows.map((r) => (r as Map<String, dynamic>)['year'] as int).toList();
    final paperRows = await _client
        .from('papers')
        .select('year')
        .eq('exam_id', examId)
        .inFilter('year', years)
        .not('category_id', 'ilike', '%notification%')
        .not('pdf_url', 'is', null);

    final countMap = <int, int>{};
    for (final row in paperRows as List<dynamic>) {
      final y = (row as Map<String, dynamic>)['year'] as int;
      countMap[y] = (countMap[y] ?? 0) + 1;
    }

    return yearRows.map((row) {
      final r = row as Map<String, dynamic>;
      final year = r['year'] as int;
      return YearModel(
        year:       year,
        examId:     r['exam_id'] as String,
        paperCount: countMap[year] ?? 0,
        isLatest:   r['is_latest'] as bool? ?? false,
      );
    }).toList();
  }
}
