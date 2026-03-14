import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/theme/app_colors.dart';
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

  const PDFViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  ConsumerState<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends ConsumerState<PDFViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _searchCtrl = TextEditingController();

  // v27 search API: PdfViewerController.searchText() returns PdfTextSearchResult
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  bool _isLoading  = true;
  bool _hasError   = false;
  String _errorMsg = '';

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
          IconButton(
            onPressed: widget.pdfUrl.isEmpty
                ? null
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Opening download…')),
                    ),
            icon: const Icon(Icons.download_rounded, color: Colors.white70),
            tooltip: 'Download',
          ),
          IconButton(
            onPressed: widget.pdfUrl.isEmpty ? null : () {},
            icon: const Icon(Icons.share_rounded, color: Colors.white70),
            tooltip: 'Share',
          ),
          const SizedBox(width: 4),
        ],
      );

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _body() {
    if (widget.pdfUrl.isEmpty) return const _InvalidUrlView();

    return Stack(
      children: [
        // PDF Viewer — use local cached file if ready, else stream from network
        if (!_hasError)
          Padding(
            padding: EdgeInsets.only(top: _isSearchOpen ? 56 : 0),
            child: Builder(builder: (context) {
              final cacheState = ref.watch(pdfCacheProvider(widget.pdfUrl));
              final localPath = cacheState.valueOrNull;
              final useFile = localPath != null &&
                  localPath.isNotEmpty &&
                  localPath != widget.pdfUrl;
              if (useFile) {
                return SfPdfViewer.file(
                  File(localPath),
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
          _ErrorView(message: _errorMsg, onRetry: _retry),
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
                  color: Colors.white.withOpacity(0.08),
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

class _InvalidUrlView extends StatelessWidget {
  const _InvalidUrlView();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off_rounded, size: 48, color: Colors.white30),
            SizedBox(height: 12),
            Text('No PDF URL provided',
                style: TextStyle(color: Colors.white54, fontSize: 15)),
          ],
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
