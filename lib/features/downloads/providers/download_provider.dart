import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/paper_model.dart';

const _prefsKey = 'downloaded_papers_v1';

// ── Download status ────────────────────────────────────────────────────────────

enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

class DownloadState {
  final DownloadStatus status;
  final double progress; // 0.0 – 1.0
  final String? localPath;
  final String? error;

  const DownloadState({
    this.status = DownloadStatus.notDownloaded,
    this.progress = 0.0,
    this.localPath,
    this.error,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    String? localPath,
    String? error,
  }) =>
      DownloadState(
        status: status ?? this.status,
        progress: progress ?? this.progress,
        localPath: localPath ?? this.localPath,
        error: error ?? this.error,
      );
}

// ── Persisted record ────────────────────────────────────────────────────────────

class DownloadedPaperRecord {
  final String id;
  final String title;
  final String examId;
  final String? examName;
  final int year;
  final String categoryId;
  final String categoryName;
  final String pdfUrl;
  final String localPath;
  final DateTime downloadedAt;

  const DownloadedPaperRecord({
    required this.id,
    required this.title,
    required this.examId,
    this.examName,
    required this.year,
    required this.categoryId,
    required this.categoryName,
    required this.pdfUrl,
    required this.localPath,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'examId': examId,
        'examName': examName,
        'year': year,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'pdfUrl': pdfUrl,
        'localPath': localPath,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory DownloadedPaperRecord.fromJson(Map<String, dynamic> json) =>
      DownloadedPaperRecord(
        id: json['id'] as String,
        title: json['title'] as String,
        examId: json['examId'] as String,
        examName: json['examName'] as String?,
        year: json['year'] as int,
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
        pdfUrl: json['pdfUrl'] as String,
        localPath: json['localPath'] as String,
        downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      );
}

// ── Notifier ────────────────────────────────────────────────────────────────────

class DownloadNotifier extends StateNotifier<Map<String, DownloadState>> {
  DownloadNotifier() : super({}) {
    _loadFromPrefs();
  }

  final _dio = Dio();
  List<DownloadedPaperRecord> _records = [];

  // ── Persistence ──────────────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];

    _records = raw
        .map((s) =>
            DownloadedPaperRecord.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();

    // Verify files still exist on disk; prune missing ones
    final valid = <DownloadedPaperRecord>[];
    for (final r in _records) {
      if (await File(r.localPath).exists()) valid.add(r);
    }
    _records = valid;
    await _saveToPrefs();

    final newState = <String, DownloadState>{};
    for (final r in _records) {
      newState[r.id] = DownloadState(
        status: DownloadStatus.downloaded,
        localPath: r.localPath,
      );
    }
    state = newState;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _prefsKey, _records.map((r) => jsonEncode(r.toJson())).toList());
  }

  // ── Download ─────────────────────────────────────────────────────────────────

  Future<void> download(PaperModel paper, {String? examName}) async {
    final url = paper.pdfUrl;
    if (url == null || url.isEmpty) return;
    if (state[paper.id]?.status == DownloadStatus.downloading) return;

    // Mark as downloading with 0 progress
    state = {
      ...state,
      paper.id: const DownloadState(
          status: DownloadStatus.downloading, progress: 0),
    };

    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      await downloadsDir.create(recursive: true);

      final filename = '${paper.id}_${paper.year}.pdf';
      final localPath = '${downloadsDir.path}/$filename';

      await _dio.download(
        url,
        localPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            state = {
              ...state,
              paper.id: DownloadState(
                status: DownloadStatus.downloading,
                progress: received / total,
              ),
            };
          }
        },
      );

      final record = DownloadedPaperRecord(
        id: paper.id,
        title: paper.title,
        examId: paper.examId,
        examName: examName,
        year: paper.year,
        categoryId: paper.categoryId,
        categoryName: paper.categoryName,
        pdfUrl: url,
        localPath: localPath,
        downloadedAt: DateTime.now(),
      );

      _records.removeWhere((r) => r.id == paper.id);
      _records.add(record);
      await _saveToPrefs();

      state = {
        ...state,
        paper.id: DownloadState(
          status: DownloadStatus.downloaded,
          localPath: localPath,
        ),
      };
    } catch (e) {
      state = {
        ...state,
        paper.id: DownloadState(
          status: DownloadStatus.failed,
          error: e.toString(),
        ),
      };
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  Future<void> deleteDownload(String paperId) async {
    final current = state[paperId];
    if (current?.localPath != null) {
      try {
        await File(current!.localPath!).delete();
      } catch (_) {}
    }
    _records.removeWhere((r) => r.id == paperId);
    await _saveToPrefs();

    final updated = Map<String, DownloadState>.from(state);
    updated.remove(paperId);
    state = updated;
  }

  // ── Accessors ────────────────────────────────────────────────────────────────

  List<DownloadedPaperRecord> get allDownloads =>
      List.unmodifiable(_records.reversed.toList());

  DownloadState stateFor(String paperId) =>
      state[paperId] ?? const DownloadState();
}

// ── Provider ─────────────────────────────────────────────────────────────────────

final downloadProvider =
    StateNotifierProvider<DownloadNotifier, Map<String, DownloadState>>(
  (ref) => DownloadNotifier(),
);
