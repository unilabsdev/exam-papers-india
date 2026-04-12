import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../utils/file_name_parser.dart';

/// Scans the Supabase `papers` storage bucket on startup and auto-populates
/// the `exam_years`, `categories`, and `papers` DB tables for any files that
/// don't yet have corresponding rows.
///
/// This means: upload a PDF named `{paper_id}.pdf` → it appears in the app
/// automatically on next launch, with no manual SQL required.
class StorageSyncService {
  final SupabaseClient _client;

  const StorageSyncService(this._client);

  /// Run the sync. Silently no-ops if storage listing is unavailable.
  Future<void> sync() async {
    try {
      final files = await _listAllFiles();
      if (files.isEmpty) return;

      final parsed = files
          .map(FileNameParser.parse)
          .whereType<ParsedFile>()
          .toList();

      if (parsed.isEmpty) return;

      await _upsertYears(parsed);
      await _upsertCategories(parsed);
      await _upsertPapers(parsed);
    } catch (_) {
      // Sync is best-effort — never crash the app
    }
  }

  // ── Storage listing ──────────────────────────────────────────────────────────

  Future<List<String>> _listAllFiles() async {
    final uri = Uri.parse('${AppConstants.r2WorkerUrl}/list');
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['files'] as List<dynamic>).cast<String>();
  }

  // ── Upsert exam_years ────────────────────────────────────────────────────────

  Future<void> _upsertYears(List<ParsedFile> files) async {
    // Collect unique (exam_id, year) pairs
    final pairs = <String>{};
    for (final f in files) {
      pairs.add('${f.examId}|${f.year}');
    }

    // Fetch existing years to avoid unnecessary inserts
    final existing = await _client
        .from('exam_years')
        .select('exam_id, year');

    final existingPairs = <String>{};
    for (final row in existing as List<dynamic>) {
      final r = row as Map<String, dynamic>;
      existingPairs.add('${r['exam_id']}|${r['year']}');
    }

    final toInsert = pairs
        .where((p) => !existingPairs.contains(p))
        .map((p) {
          final parts = p.split('|');
          return {
            'exam_id':   parts[0],
            'year':      int.parse(parts[1]),
            'is_latest': false,
          };
        })
        .toList();

    if (toInsert.isEmpty) return;

    // Insert in batches of 50
    for (var i = 0; i < toInsert.length; i += 50) {
      final batch = toInsert.sublist(
          i, (i + 50).clamp(0, toInsert.length));
      await _client.from('exam_years').insert(batch);
    }
  }

  // ── Upsert categories ────────────────────────────────────────────────────────

  Future<void> _upsertCategories(List<ParsedFile> files) async {
    // Collect unique categories
    final categories = <String, Map<String, dynamic>>{};
    for (final f in files) {
      if (!categories.containsKey(f.categoryId)) {
        categories[f.categoryId] = {
          'id':          f.categoryId,
          'exam_id':     f.examId,
          'name':        f.categoryName,
          'description': '',
          'icon_name':   f.categoryIconName,
        };
      }
    }

    // Fetch existing category IDs
    final existing = await _client.from('categories').select('id');
    final existingIds = <String>{};
    for (final row in existing as List<dynamic>) {
      existingIds.add((row as Map<String, dynamic>)['id'] as String);
    }

    final toInsert = categories.values
        .where((c) => !existingIds.contains(c['id']))
        .toList();

    if (toInsert.isEmpty) return;

    for (var i = 0; i < toInsert.length; i += 50) {
      final batch = toInsert.sublist(
          i, (i + 50).clamp(0, toInsert.length));
      await _client.from('categories').insert(batch);
    }
  }

  // ── Upsert papers ────────────────────────────────────────────────────────────

  Future<void> _upsertPapers(List<ParsedFile> files) async {
    // Fetch existing paper IDs
    final existing = await _client.from('papers').select('id');
    final existingIds = <String>{};
    for (final row in existing as List<dynamic>) {
      existingIds.add((row as Map<String, dynamic>)['id'] as String);
    }

    final toInsert = files
        .where((f) => !existingIds.contains(f.id))
        .map((f) => {
              'id':            f.id,
              'exam_id':       f.examId,
              'year':          f.year,
              'category_id':   f.categoryId,
              'category_name': f.categoryName,
              'title':         f.title,
              'pdf_url':       f.pdfUrl,
              'language':      'English',
            })
        .toList();

    if (toInsert.isEmpty) return;

    for (var i = 0; i < toInsert.length; i += 50) {
      final batch = toInsert.sublist(
          i, (i + 50).clamp(0, toInsert.length));
      await _client.from('papers').insert(batch);
    }
  }
}
