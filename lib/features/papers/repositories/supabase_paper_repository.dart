import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/cache_service.dart';
import '../../../models/paper_model.dart';
import 'paper_repository.dart';

const _storageBase =
    'https://hsvgjgnfrtufrfswwoeu.supabase.co/storage/v1/object/public/papers/';

class SupabasePaperRepository implements IPaperRepository {
  final SupabaseClient _client;
  const SupabasePaperRepository(this._client);

  @override
  Future<List<PaperModel>> getPapers(PaperParams params) async {
    final key = CacheService.papersKey(params.examId, params.year, params.categoryId);
    final fresh = await CacheService.isFresh(key);
    final cached = await CacheService.loadPapers(
      params.examId, params.year, params.categoryId,
    );

    if (fresh && cached != null) {
      _fetchAndSave(params).ignore();
      return cached.map(PaperModel.fromJson).toList();
    }

    try {
      return await _fetchAndSave(params);
    } catch (_) {
      if (cached != null) return cached.map(PaperModel.fromJson).toList();
      throw const NoCacheException();
    }
  }

  Future<List<PaperModel>> _fetchAndSave(PaperParams params) async {
    final rows = await _client
        .from('papers')
        .select()
        .eq('exam_id', params.examId)
        .eq('year', params.year)
        .eq('category_id', params.categoryId)
        .order('created_at', ascending: true);

    final result = <PaperModel>[];
    final cacheRows = <Map<String, dynamic>>[];

    for (final row in rows as List<dynamic>) {
      final r = row as Map<String, dynamic>;
      final model = PaperModel(
        id:              r['id'] as String,
        title:           (r['title'] as String).replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim(),
        examId:          r['exam_id'] as String,
        year:            r['year'] as int,
        categoryId:      r['category_id'] as String,
        categoryName:    r['category_name'] as String? ?? '',
        pdfUrl:          (r['pdf_url'] as String?) ?? '$_storageBase${r['id']}.pdf',
        downloadUrl:     r['download_url'] as String?,
        fileSizeMb:      (r['file_size_mb'] as num?)?.toDouble(),
        language:        r['language'] as String?,
        totalQuestions:  r['total_questions'] as int?,
        totalMarks:      r['total_marks'] as int?,
        durationMinutes: r['duration_minutes'] as int?,
      );
      result.add(model);
      cacheRows.add(model.toJson());
    }

    await CacheService.savePapers(
      params.examId, params.year, params.categoryId, cacheRows,
    );
    return result;
  }
}
