import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/paper_model.dart';
import 'paper_repository.dart';

/// Live Supabase implementation of [IPaperRepository].
///
/// Schema: papers table uses year_id (UUID FK → exam_years) and file_url.
/// We resolve year_id from the year integer, then join categories for name.
class SupabasePaperRepository implements IPaperRepository {
  final SupabaseClient _client;
  const SupabasePaperRepository(this._client);

  @override
  Future<List<PaperModel>> getPapers(PaperParams params) async {
    final rows = await _client
        .from('papers')
        .select()
        .eq('exam_id', params.examId)
        .eq('year', params.year)
        .eq('category_id', params.categoryId)
        .order('created_at', ascending: true);

    return (rows as List<dynamic>).map((row) {
      final r = row as Map<String, dynamic>;
      return PaperModel(
        id:              r['id'] as String,
        title:           (r['title'] as String).replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim(),
        examId:          r['exam_id'] as String,
        year:            r['year'] as int,
        categoryId:      r['category_id'] as String,
        categoryName:    r['category_name'] as String? ?? '',
        pdfUrl:          r['pdf_url'] as String?,
        downloadUrl:     r['download_url'] as String?,
        fileSizeMb:      (r['file_size_mb'] as num?)?.toDouble(),
        language:        r['language'] as String?,
        totalQuestions:  r['total_questions'] as int?,
        totalMarks:      r['total_marks'] as int?,
        durationMinutes: r['duration_minutes'] as int?,
      );
    }).toList();
  }
}
