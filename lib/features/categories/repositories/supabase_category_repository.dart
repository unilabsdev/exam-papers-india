import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/cache_service.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../models/category_model.dart';
import 'category_repository.dart';

class SupabaseCategoryRepository implements ICategoryRepository {
  static const String _table = 'categories';

  final SupabaseClient _client;
  const SupabaseCategoryRepository(this._client);

  @override
  Future<List<CategoryModel>> getCategories(String examId, int year) async {
    final key = CacheService.categoriesKey(examId, year);
    final fresh = await CacheService.isFresh(key);
    final cached = await CacheService.loadCategories(examId, year);

    if (fresh && cached != null) {
      unawaited(_fetchAndSave(examId, year));
      return _fromCacheRows(cached);
    }

    try {
      return await _fetchAndSave(examId, year);
    } catch (_) {
      if (cached != null) return _fromCacheRows(cached);
      throw const NoCacheException();
    }
  }

  Future<List<CategoryModel>> _fetchAndSave(String examId, int year) async {
    final paperRows = await _client
        .from('papers')
        .select('category_id, category_name, pdf_url')
        .eq('exam_id', examId)
        .eq('year', year);

    final papers = paperRows as List<dynamic>;
    if (papers.isEmpty) return [];

    final categoryIds = <String>{};
    final countMap = <String, int>{};
    for (final row in papers) {
      final id = row['category_id'] as String;
      categoryIds.add(id);
      if (row['pdf_url'] != null) {
        countMap[id] = (countMap[id] ?? 0) + 1;
      }
    }

    final rows = await _client
        .from(_table)
        .select()
        .inFilter('id', categoryIds.toList())
        .order('name', ascending: true);

    final result = <CategoryModel>[];
    final cacheRows = <Map<String, dynamic>>[];

    for (final row in rows as List<dynamic>) {
      final r = row as Map<String, dynamic>;
      final id = r['id'] as String;
      final count = countMap[id] ?? 0;

      result.add(CategoryModel(
        id:          id,
        name:        r['name'] as String,
        examId:      r['exam_id'] as String,
        icon:        IconMapper.get(r['icon_name'] as String?),
        description: r['description'] as String? ?? '',
        paperCount:  count,
      ));

      cacheRows.add({...r, 'paper_count': count});
    }

    await CacheService.saveCategories(examId, year, cacheRows);
    return result;
  }

  List<CategoryModel> _fromCacheRows(List<Map<String, dynamic>> rows) {
    return rows.map((r) => CategoryModel(
      id:          r['id'] as String,
      name:        r['name'] as String,
      examId:      r['exam_id'] as String,
      icon:        IconMapper.get(r['icon_name'] as String?),
      description: r['description'] as String? ?? '',
      paperCount:  r['paper_count'] as int? ?? 0,
    )).toList();
  }
}
