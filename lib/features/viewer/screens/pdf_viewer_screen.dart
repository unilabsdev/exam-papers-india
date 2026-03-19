import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/paper_model.dart';
import '../../downloads/providers/download_provider.dart';
import '../providers/pdf_cache_provider.dart';

/// Full-featured PDF Viewer backed by syncfusion_flutter_pdfviewer.
///
/// Features:
///   • Network PDF loading with progress + error states
///   • Page count display & prev/next navigation
///   • Jump-to-page dialog
///   • In-document text search with highlight cycling
///   • Download & Share action stubs (wire url_launcher / share_plus)
class PDFViewerScreen extends ConsumerStatefulWidget {
  final String pdfUrl;
  final String title;
  /// If non-null and non-empty, open this local file directly (offline read).
  final String? localPath;
  // Optional paper metadata — enables Download button in viewer
  final String? paperId;
  final String? examId;
  final int? year;
  final String? categoryId;
  final String? categoryName;

  const PDFViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.localPath,
    this.paperId,
    this.examId,
    this.year,
    this.categoryId,
    this.categoryName,
  });

  @override
  ConsumerState<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends ConsumerState<PDFViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _searchCtrl = TextEditingController();

  // v27 search API: PdfViewerController.searchText() returns PdfTextSearchResult
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  bool _isLoading        = true;
  bool _hasError         = false;
  bool _isFileUnavailable = false;
  String _errorMsg       = '';

  int _currentPage = 1;
  int _totalPages  = 0;
  bool _isSearchOpen = false;

  @override
  void dispose() {
    _controller.dispose();
    _searchCtrl.dispose();
    _searchResult.clear();
    super.dispose();
  }

  // ── Event handlers ─────────────────────────────────────────────────────────

  void _onLoaded(PdfDocumentLoadedDetails d) => setState(() {
        _isLoading  = false;
        _hasError   = false;
        _totalPages = d.document.pages.count;
      });

  void _onLoadFailed(PdfDocumentLoadFailedDetails d) => setState(() {
        _isLoading = false;
        _hasError  = true;
        _errorMsg  = d.description;
        // Detect HTTP 400/404 — file not uploaded to storage yet
        _isFileUnavailable = _errorMsg.contains('400') ||
            _errorMsg.contains('404') ||
            _errorMsg.contains('Bad Request') ||
            _errorMsg.contains('Not Found');
      });

  void _onPageChanged(PdfPageChangedDetails d) =>
      setState(() => _currentPage = d.newPageNumber);

  void _toggleSearch() {
    setState(() => _isSearchOpen = !_isSearchOpen);
    if (!_isSearchOpen) {
      _searchResult.clear();
      _searchCtrl.clear();
    }
  }

  void _runSearch(String query) {
    if (query.trim().isEmpty) return;
    _searchResult = _controller.searchText(query);
  }

  void _retry() => setState(() {
        _isLoading = true;
        _hasError  = false;
      });

  void _share() {
    final url = widget.pdfUrl;
    if (url.isEmpty) return;
    Share.share('${widget.title}\n$url', subject: widget.title);
  }

  void _download() {
    final pid = widget.paperId;
    if (pid == null || widget.pdfUrl.isEmpty) return;
    final paper = PaperModel(
      id:           pid,
      title:        widget.title,
      pdfUrl:       widget.pdfUrl,
      examId:       widget.examId ?? '',
      year:         widget.year ?? 0,
      categoryId:   widget.categoryId ?? '',
      categoryName: widget.categoryName ?? '',
    );
    ref.read(downloadProvider.notifier).download(paper);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download started…')),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: _appBar(context),
      body: _body(),
      bottomNavigationBar: (_hasError || _isLoading) ? null : _bottomNav(),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  AppBar _appBar(BuildContext context) => AppBar(
        backgroundColor: const Color(0xFF2C2C2E),
        foregroundColor: Colors.white,
        surfaceTintColor: const Color(0xFF2C2C2E),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Page $_currentPage of $_totalPages',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearchOpen
                  ? Icons.search_off_rounded
                  : Icons.search_rounded,
              color: _isSearchOpen
                  ? AppColors.primaryLight
                  : Colors.white70,
            ),
            tooltip: 'Search in PDF',
          ),
          // Download — only shown when not already downloaded/downloading
          if (widget.localPath == null || widget.localPath!.isEmpty)
            Builder(builder: (ctx) {
              final dlStates = ref.watch(downloadProvider);
              final dlState  = widget.paperId != null
                  ? (dlStates[widget.paperId] ?? const DownloadState())
                  : const DownloadState();
              final isDownloaded = dlState.status == DownloadStatus.downloaded;
              final isDownloading = dlState.status == DownloadStatus.downloading;
              return IconButton(
                onPressed: (widget.paperId == null || isDownloaded || isDownloading)
                    ? null
                    : _download,
                icon: Icon(
                  isDownloaded
                      ? Icons.download_done_rounded
                      : Icons.download_rounded,
                  color: isDownloaded
                      ? Colors.greenAccent
                      : (widget.paperId != null ? Colors.white70 : Colors.white30),
                ),
                tooltip: isDownloaded ? 'Downloaded' : 'Download',
              );
            }),
          IconButton(
            onPressed: widget.pdfUrl.isEmpty ? null : _share,
            icon: const Icon(Icons.share_rounded, color: Colors.white70),
            tooltip: 'Share',
          ),
          const SizedBox(width: 4),
        ],
      );

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _body() {
    // ── Offline: open local file directly, skip cache provider ────────────
    final localPath = widget.localPath;
    if (localPath != null && localPath.isNotEmpty) {
      return Stack(
        children: [
          if (!_hasError)
            Padding(
              padding: EdgeInsets.only(top: _isSearchOpen ? 56 : 0),
              child: SfPdfViewer.file(
                File(localPath),
                controller: _controller,
                enableDoubleTapZooming: true,
                enableTextSelection: true,
                pageLayoutMode: PdfPageLayoutMode.continuous,
                scrollDirection: PdfScrollDirection.vertical,
                onDocumentLoaded: _onLoaded,
                onDocumentLoadFailed: _onLoadFailed,
                onPageChanged: _onPageChanged,
              ),
            ),
          if (_isSearchOpen && !_hasError)
            Positioned(
              top: 0, left: 0, right: 0,
              child: _SearchBar(
                controller: _searchCtrl,
                onSearch: _runSearch,
                onNext: () => _searchResult.nextInstance(),
                onPrev: () => _searchResult.previousInstance(),
                onClear: () { _searchResult.clear(); _searchCtrl.clear(); },
              ),
            ),
          if (_isLoading && !_hasError) const _LoadingOverlay(),
          if (_hasError) _ErrorView(message: _errorMsg, onRetry: _retry),
        ],
      );
    }

    // ── Online: NULL url → File Not Available ──────────────────────────────
    if (widget.pdfUrl.isEmpty) return const _InvalidUrlView();

    final cacheState = ref.watch(pdfCacheProvider(widget.pdfUrl));

    // File not uploaded to storage — show unavailable screen immediately
    if (cacheState.hasError) {
      return _FileUnavailableView(onBack: () => Navigator.of(context).pop());
    }

    return Stack(
      children: [
        // PDF Viewer — use local cached file if ready, else stream from network
        if (!_hasError)
          Padding(
            padding: EdgeInsets.only(top: _isSearchOpen ? 56 : 0),
            child: Builder(builder: (context) {
              final cachedPath = cacheState.valueOrNull;
              final useFile = cachedPath != null &&
                  cachedPath.isNotEmpty &&
                  cachedPath != widget.pdfUrl;
              if (useFile) {
                return SfPdfViewer.file(
                  File(cachedPath),
                  controller: _controller,
                  enableDoubleTapZooming: true,
                  enableTextSelection: true,
                  pageLayoutMode: PdfPageLayoutMode.continuous,
                  scrollDirection: PdfScrollDirection.vertical,
                  onDocumentLoaded: _onLoaded,
                  onDocumentLoadFailed: _onLoadFailed,
                  onPageChanged: _onPageChanged,
                );
              }
              return SfPdfViewer.network(
                widget.pdfUrl,
                controller: _controller,
                enableDoubleTapZooming: true,
                enableTextSelection: true,
                pageLayoutMode: PdfPageLayoutMode.continuous,
                scrollDirection: PdfScrollDirection.vertical,
                onDocumentLoaded: _onLoaded,
                onDocumentLoadFailed: _onLoadFailed,
                onPageChanged: _onPageChanged,
              );
            }),
          ),

        // Search bar
        if (_isSearchOpen && !_hasError)
          Positioned(
            top: 0, left: 0, right: 0,
            child: _SearchBar(
              controller: _searchCtrl,
              onSearch: _runSearch,
              onNext: () => _searchResult.nextInstance(),
              onPrev: () => _searchResult.previousInstance(),
              onClear: () {
                _searchResult.clear();
                _searchCtrl.clear();
              },
            ),
          ),

        // Loading overlay
        if (_isLoading && !_hasError) const _LoadingOverlay(),

        // Error view
        if (_hasError)
          _isFileUnavailable
              ? _FileUnavailableView(onBack: () => Navigator.of(context).pop())
              : _ErrorView(message: _errorMsg, onRetry: _retry),
      ],
    );
  }

  // ── Bottom navigation bar ──────────────────────────────────────────────────

  Widget _bottomNav() => Container(
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFF2C2C2E),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _currentPage > 1
                  ? () => _controller.previousPage()
                  : null,
              icon: Icon(Icons.navigate_before_rounded,
                  size: 28,
                  color: _currentPage > 1
                      ? Colors.white70
                      : Colors.white24),
              tooltip: 'Previous page',
            ),

            // Tappable page indicator → jump-to-page dialog
            GestureDetector(
              onTap: _showGoToPageDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),

            IconButton(
              onPressed: _currentPage < _totalPages
                  ? () => _controller.nextPage()
                  : null,
              icon: Icon(Icons.navigate_next_rounded,
                  size: 28,
                  color: _currentPage < _totalPages
                      ? Colors.white70
                      : Colors.white24),
              tooltip: 'Next page',
            ),
          ],
        ),
      );

  // ── Go to page dialog ──────────────────────────────────────────────────────

  void _showGoToPageDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Go to Page',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '1 – $_totalPages',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.primaryLight)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(ctrl.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _controller.jumpToPage(page);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Go',
                style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }
}

// ── Internal sub-widgets ───────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF1C1C1E),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.5),
              SizedBox(height: 16),
              Text('Loading PDF…',
                  style:
                      TextStyle(color: Colors.white60, fontSize: 14)),
            ],
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image_rounded,
                  size: 56, color: Colors.white30),
              const SizedBox(height: 16),
              const Text('Failed to load PDF',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(message,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

class _FileUnavailableView extends StatelessWidget {
  final VoidCallback onBack;
  const _FileUnavailableView({required this.onBack});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.white30),
              const SizedBox(height: 20),
              const Text(
                'File Not Available',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text(
                'This paper has not been uploaded yet.\nPlease check back later.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A3A3C),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
}

class _InvalidUrlView extends StatelessWidget {
  const _InvalidUrlView();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.white30),
              const SizedBox(height: 20),
              const Text(
                'File Not Available',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text(
                'This paper has not been uploaded yet.\nPlease check back later.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A3A3C),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.onNext,
    required this.onPrev,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        color: const Color(0xFF3A3A3C),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                onSubmitted: onSearch,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search in document…',
                  hintStyle:
                      TextStyle(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
            _iconBtn(Icons.expand_less_rounded, onPrev),
            _iconBtn(Icons.expand_more_rounded, onNext),
            _iconBtn(Icons.close_rounded, onClear, size: 18),
          ],
        ),
      );

  Widget _iconBtn(IconData icon, VoidCallback cb, {double size = 20}) =>
      IconButton(
        onPressed: cb,
        icon: Icon(icon, color: Colors.white70, size: size),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
}
