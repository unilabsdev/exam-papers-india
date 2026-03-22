import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/cache_service.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../models/exam_model.dart';
import 'exam_repository.dart';

class SupabaseExamRepository implements IExamRepository {
  static const String _table = 'exams';

  final SupabaseClient _client;
  const SupabaseExamRepository(this._client);

  @override
  Future<List<ExamModel>> getExams() async {
    final fresh = await CacheService.isFresh(CacheService.examsKey);
    final cached = await CacheService.loadExams();

    // Online + fresh cache → return cache, refresh in background
    if (fresh && cached != null) {
      unawaited(_fetchAndSave());
      return _fromCacheRows(cached);
    }

    // Online + stale/missing → fetch now
    try {
      return await _fetchAndSave();
    } catch (_) {
      // Network failed — fall back to whatever cache we have
      if (cached != null) return _fromCacheRows(cached);
      throw const NoCacheException();
    }
  }

  Future<List<ExamModel>> _fetchAndSave() async {
    final examRows = await _client
        .from(_table)
        .select()
        .order('name', ascending: true)
        .timeout(const Duration(seconds: 5));

    final rows = examRows as List<dynamic>;
    if (rows.isEmpty) return [];

    final paperRows = await _client
        .from('papers')
        .select('exam_id')
        .not('category_id', 'ilike', '%notification%')
        .not('pdf_url', 'is', null)
        .timeout(const Duration(seconds: 5));

    final countMap = <String, int>{};
    for (final row in paperRows as List<dynamic>) {
      final id = (row as Map<String, dynamic>)['exam_id'] as String;
      countMap[id] = (countMap[id] ?? 0) + 1;
    }

    final result = <ExamModel>[];
    final cacheRows = <Map<String, dynamic>>[];

    for (final row in rows) {
      final r = row as Map<String, dynamic>;
      final id = r['id'] as String;
      final count = countMap[id] ?? 0;

      result.add(ExamModel(
        id:          id,
        name:        r['name'] as String,
        shortName:   r['short_name'] as String,
        description: r['description'] as String? ?? '',
        conductedBy: r['conducted_by'] as String? ?? 'UPSC',
        icon:        IconMapper.get(r['icon_name'] as String?),
        color:       Color(r['color_value'] as int? ?? 0xFF2563EB),
        totalPapers: count,
      ));

      cacheRows.add({...r, 'total_papers': count});
    }

    await CacheService.saveExams(cacheRows);
    return result;
  }

  List<ExamModel> _fromCacheRows(List<Map<String, dynamic>> rows) {
    return rows.map((r) => ExamModel(
      id:          r['id'] as String,
      name:        r['name'] as String,
      shortName:   r['short_name'] as String,
      description: r['description'] as String? ?? '',
      conductedBy: r['conducted_by'] as String? ?? 'UPSC',
      icon:        IconMapper.get(r['icon_name'] as String?),
      color:       Color(r['color_value'] as int? ?? 0xFF2563EB),
      totalPapers: r['total_papers'] as int? ?? 0,
    )).toList();
  }
}
