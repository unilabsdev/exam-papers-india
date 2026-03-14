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
    // Step 1: resolve year UUID from the year integer
    final yearRow = await _client
        .from('exam_years')
        .select('id')
        .eq('exam_id', params.examId)
        .eq('year', params.year)
        .maybeSingle();

    if (yearRow == null) return [];
    final yearId = yearRow['id'] as String;

    // Step 2: fetch papers + join categories for the display name
    final rows = await _client
        .from('papers')
        .select('*, categories(name)')
        .eq('exam_id', params.examId)
        .eq('year_id', yearId)
        .eq('category_id', params.categoryId)
        .order('sort_order', ascending: true);

    return (rows as List<dynamic>).map((row) {
      final r = row as Map<String, dynamic>;
      final categoryData = r['categories'] as Map<String, dynamic>?;
      final fileUrl = r['file_url'] as String?;

      return PaperModel(
        id:              r['id'] as String,
        title:           r['title'] as String,
        examId:          r['exam_id'] as String,
        year:            params.year,
        categoryId:      r['category_id'] as String,
        categoryName:    categoryData?['name'] as String? ?? '',
        pdfUrl:          fileUrl,
        downloadUrl:     fileUrl,
        fileSizeMb:      (r['file_size_mb'] as num?)?.toDouble(),
        language:        r['language'] as String?,
        totalQuestions:  r['total_questions'] as int?,
        totalMarks:      r['total_marks'] as int?,
        durationMinutes: r['duration_minutes'] as int?,
      );
    }).toList();
  }
}
