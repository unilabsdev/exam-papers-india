import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads a PDF from [url] to the temp directory and returns the local path.
/// On subsequent calls the cached file is returned immediately.
final pdfCacheProvider =
    FutureProvider.autoDispose.family<String, String>((ref, url) async {
  if (url.isEmpty) return '';

  final dir = await getTemporaryDirectory();
  final filename = '${url.hashCode.abs()}.pdf';
  final file = File('${dir.path}/$filename');

  if (await file.exists()) return file.path;

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }
  return url; // fall back to network URL on error
});
