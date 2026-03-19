const String _storageBase =
    'https://hsvgjgnfrtufrfswwoeu.supabase.co/storage/v1/object/public/papers/';

// ── Parsed file result ─────────────────────────────────────────────────────────

class ParsedFile {
  final String id;           // filename without .pdf
  final String examId;
  final int year;
  final String categoryId;
  final String categoryName;
  final String categoryIconName;
  final String title;
  final String pdfUrl;

  const ParsedFile({
    required this.id,
    required this.examId,
    required this.year,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIconName,
    required this.title,
    required this.pdfUrl,
  });
}

// ── Parser ─────────────────────────────────────────────────────────────────────

class FileNameParser {
  FileNameParser._();

  // Two-part file prefix → exam_id in DB  (checked before single-part)
  static const _twoPartPrefixToId = {
    'upsc_cse': 'upsc',
    'ies_iss':  'ies_iss',
    'nda_na':   'nda',
  };

  // Single-part file prefix → exam_id in DB
  static const _onePartPrefixToId = {
    'capf':  'capf',
    'cisf':  'cisf',
    'cds':   'cds',
    'cgse':  'cgse',
    'cmse':  'cms',
    'cso':   'so_ldce',
    'ese':   'ese',
    'ifos':  'geo_scientist',
  };

  // Human-readable subject names
  static const _subjectNames = {
    'gs':      'General Studies',
    'gat':                 'General Ability Test',
    'general_ability_test':'General Ability Test',
    'gk':      'General Knowledge',
    'eng':     'English',
    'math':    'Mathematics',
    'maths':   'Mathematics',
    'mp':      'Mathematics',
    'stat':    'Statistics',
    'ie':      'Indian Economics',
    'ge':      'General Economics',
    'agp':     'Agriculture',
    'aep':     'Agriculture Engineering',
    'anthro':  'Anthropology',
    'chem':    'General Chemistry',
    'geo':     'General Geology',
    'geol':    'General Geology',
    'geop':    'General Geophysics',
    'geoph':   'General Geophysics',
    'hydro':   'Hydrogeology',
    'civil':   'Civil Engineering',
    'mech':    'Mechanical Engineering',
    'ee':      'Electrical Engineering',
    'elec':    'Electronics and Telecommunication Engineering',
    'cs':      'Computer Science',
    'it':      'Information Technology',
    'botany':  'Botany',
    'zoology': 'Zoology',
    'physics': 'Physics',
    'forestry':'Forestry',
    'geology': 'Geology',
    'assamese':'Assamese',
    'bengali': 'Bengali',
    'ben':     'Bengali',
    'gujarati':'Gujarati',
    'guj':     'Gujarati',
    'hindi':   'Hindi',
    'kannada': 'Kannada',
    'malayalam':'Malayalam',
    'manipuri':'Manipuri',
    'marathi': 'Marathi',
    'odia':    'Odia',
    'punjabi': 'Punjabi',
    'sanskrit':'Sanskrit',
    'sindhi':  'Sindhi',
    'tamil':   'Tamil',
    'telugu':  'Telugu',
    'urdu':    'Urdu',
    'english': 'English',
    'agriculture': 'Agriculture',
    'animal':  'Animal Husbandry',
    'chemical':'Chemical Engineering',
    'statistics':'Statistics',
    'geography':'Geography',
    'management':'Management',
    'sociology':'Sociology',
    'history': 'History',
    'commerce':'Commerce',
    'law':     'Law',
    'philosophy':'Philosophy',
    'psychology':'Psychology',
    'political':'Political Science',
  };

  static const _categoryIcons = {
    'Prelims':              'school',
    'Mains':                'menu_book',
    'Question Papers':      'assignment',
    'Exam Notification':    'notifications',
    'Compulsory Language':  'language',
    'Literature':           'library_books',
    'Optional':             'assignment',
  };

  /// Parse a storage filename (with or without .pdf) into a [ParsedFile].
  /// Returns null if the filename doesn't match a known exam pattern.
  static ParsedFile? parse(String filename) {
    // Strip .pdf
    final raw = filename.endsWith('.pdf')
        ? filename.substring(0, filename.length - 4)
        : filename;

    final parts = raw.split('_');
    if (parts.length < 3) return null;

    // Try two-part prefix first (e.g. upsc_cse, ies_iss, nda_na)
    String? examId;
    var yearIndex = 1;
    if (parts.length >= 4) {
      final twoPartKey = '${parts[0]}_${parts[1]}'.toLowerCase();
      final twoPartId = _twoPartPrefixToId[twoPartKey];
      if (twoPartId != null) {
        examId = twoPartId;
        yearIndex = 2;
      }
    }
    // Fall back to single-part prefix
    examId ??= _onePartPrefixToId[parts[0].toLowerCase()];
    if (examId == null) return null;

    // Year comes right after prefix
    final year = int.tryParse(parts[yearIndex]);
    if (year == null || year < 2000 || year > 2100) return null;

    final rest = parts.sublist(yearIndex + 1);
    final (catId, catName, catIcon, title) = _resolveCategory(examId, year, rest);

    return ParsedFile(
      id:               raw,
      examId:           examId,
      year:             year,
      categoryId:       catId,
      categoryName:     catName,
      categoryIconName: catIcon,
      title:            title,
      pdfUrl:           '$_storageBase$filename',
    );
  }

  // ── Category resolution ──────────────────────────────────────────────────────

  static (String, String, String, String) _resolveCategory(
      String examId, int year, List<String> parts) {
    if (parts.isEmpty) {
      return ('${examId}_papers', 'Question Papers', 'assignment', 'Paper');
    }

    final p0 = parts[0].toLowerCase();

    // ── Exam Notification ────────────────────────────────────────────────────
    if (p0 == 'n' || p0 == 'n1' || p0 == 'notification') {
      return (
        '${examId}_exam_notification',
        'Exam Notification',
        'notifications',
        '$year Notification',
      );
    }

    // ── Set indicator (CDS I/II, NDA I/II) ──────────────────────────────────
    if (_isRomanNumeral(p0)) {
      final setLabel = p0.toUpperCase();
      final subParts = parts.sublist(1);
      if (subParts.isEmpty) {
        return ('${examId}_set_$p0', 'Set $setLabel', 'assignment', 'Set $setLabel');
      }
      final subjectKey = subParts.join('_').toLowerCase();
      final subjectName = _lookupSubject(subjectKey) ?? _titleCase(subParts.join(' '));
      final catId = '${examId}_set_$p0';
      return (catId, 'Set $setLabel', 'assignment', subjectName);
    }

    // ── Simple numbered paper (p1, p2, p2a …) ───────────────────────────────
    if (RegExp(r'^p\d+[a-z]?$').hasMatch(p0) && parts.length == 1) {
      final num = p0.replaceAll(RegExp(r'^p'), '').replaceAll(RegExp(r'[a-z]$'), '');
      final suffix = p0.replaceAll(RegExp(r'^p\d+'), '').toUpperCase();
      return (
        '${examId}_question_papers',
        'Question Papers',
        'assignment',
        'Paper $num${suffix.isNotEmpty ? ' ($suffix)' : ''}',
      );
    }

    // ── Prelims ──────────────────────────────────────────────────────────────
    if (p0 == 'pre' || p0 == 'prelims') {
      final subParts = parts.sublist(1);
      final title = _deriveTitle(subParts, 'Paper');
      return ('${examId}_prelims', 'Prelims Papers', 'school', title);
    }

    // ── Mains (m, mgs, mains) ────────────────────────────────────────────────
    if (p0 == 'm' || p0 == 'mgs' || p0 == 'mains') {
      // e.g. upsc_2024_mgs1 or cgse_2024_m_chem1
      if (p0 == 'mgs' || (p0 == 'm' && parts.length == 1)) {
        // mgs1, mgs2 → Mains, General Studies Paper 1
        final num = _extractNumber(p0);
        final baseNum = num ?? _extractNumber(parts.length > 1 ? parts[1] : '');
        return (
          '${examId}_mains',
          'Mains',
          'menu_book',
          baseNum != null ? 'General Studies Paper $baseNum' : 'General Studies',
        );
      }
      final subParts = parts.sublist(1);
      // Handle mains_compulsory → Compulsory Language
      if (subParts.isNotEmpty && subParts[0].toLowerCase() == 'compulsory') {
        final lang = subParts.length > 1
            ? (_subjectNames[subParts[1].toLowerCase()] ?? _titleCase(subParts[1]))
            : 'Language';
        return ('${examId}_comp_lang', 'Compulsory Language', 'language', lang);
      }
      // Handle mains_literature → Mains Literature Papers (single folder)
      if (subParts.isNotEmpty && subParts[0].toLowerCase() == 'literature') {
        final lang = subParts.length > 1
            ? (_subjectNames[subParts[1].toLowerCase()] ?? _titleCase(subParts[1]))
            : 'Literature';
        final paperNum = subParts.length > 2 ? _extractNumber(subParts[2]) : null;
        return (
          '${examId}_mains_literature',
          'Mains Literature Papers',
          'library_books',
          '$lang${paperNum != null ? ' Paper $paperNum' : ''}',
        );
      }
      // Handle mains_optional → Mains Optional Papers (single folder)
      if (subParts.isNotEmpty && subParts[0].toLowerCase() == 'optional') {
        return _resolveOptional(examId, subParts.sublist(1));
      }
      // Handle mains_general_studies → Mains General Studies Papers
      if (subParts.length >= 2 && subParts[0].toLowerCase() == 'general' && subParts[1].toLowerCase() == 'studies') {
        final num = subParts.length > 2 ? _extractNumber(subParts.last) : null;
        return (
          '${examId}_mains_gs',
          'Mains General Studies Papers',
          'menu_book',
          num != null ? 'General Studies Paper $num' : 'General Studies',
        );
      }
      final title = _deriveTitle(subParts, 'Paper');
      return ('${examId}_mains_gs', 'Mains General Studies Papers', 'menu_book', title);
    }

    // ── Optional ─────────────────────────────────────────────────────────────
    if (p0 == 'opt' || p0 == 'optional') {
      return _resolveOptional(examId, parts.sublist(1));
    }

    // ── Compulsory Language ──────────────────────────────────────────────────
    if (p0 == 'comp') {
      final lang = parts.length > 1
          ? (_subjectNames[parts[1].toLowerCase()] ?? _titleCase(parts[1]))
          : 'Language';
      return ('${examId}_comp_lang', 'Compulsory Language', 'language', lang);
    }

    // ── Literature ────────────────────────────────────────────────────────────
    if (p0 == 'lit') {
      final lang = parts.length > 1
          ? (_subjectNames[parts[1].toLowerCase()] ?? _titleCase(parts[1]))
          : 'Literature';
      final paperNum = parts.length > 2 ? _extractNumber(parts[2]) : null;
      return (
        '${examId}_mains_literature',
        'Mains Literature Papers',
        'library_books',
        '$lang${paperNum != null ? ' Paper $paperNum' : ''}',
      );
    }

    // ── Essay ─────────────────────────────────────────────────────────────────
    if (p0 == 'essay') {
      return ('${examId}_mains_essay', 'Mains Essay Papers', 'edit_note', 'Essay');
    }

    // ── mgs1…mgs4 (UPSC Mains GS) ────────────────────────────────────────────
    if (RegExp(r'^mgs\d+$').hasMatch(p0)) {
      final num = _extractNumber(p0);
      return ('${examId}_mains_gs', 'Mains General Studies Papers', 'menu_book', 'General Studies Paper $num');
    }

    // ── Fallback: try as a subject code (IES/ISS pattern: gs, ge1, stat2…) ───
    final subjectName = _lookupSubject(parts.join('_')) ??
        _lookupSubject(p0) ??
        _titleCase(parts.join(' '));
    return ('${examId}_papers', 'Question Papers', 'assignment', subjectName);
  }

  // ── Optional subject resolution ──────────────────────────────────────────────

  static (String, String, String, String) _resolveOptional(
      String examId, List<String> subParts) {
    if (subParts.isEmpty) {
      return ('${examId}_mains_optional', 'Mains Optional Papers', 'assignment', 'Optional Paper');
    }

    // Join all subject parts, strip trailing paper number
    final lastPart = subParts.last;
    final paperNum = _extractNumber(lastPart);
    final subjectParts = (paperNum != null && lastPart == 'p$paperNum')
        ? subParts.sublist(0, subParts.length - 1)
        : subParts;

    // Try joining all subject parts as lookup key
    final fullKey = subjectParts.join('_').toLowerCase();
    final firstKey = subjectParts.isNotEmpty ? subjectParts[0].toLowerCase() : '';
    final baseKey = firstKey.replaceAll(RegExp(r'\d+$'), '');

    final subjectName = _subjectNames[fullKey] ??
        _subjectNames[firstKey] ??
        _subjectNames[baseKey] ??
        _titleCase(subjectParts.join(' '));

    // Paper number from either the last part or embedded in key
    final num = paperNum ?? _extractNumber(firstKey);
    final title = num != null ? '$subjectName Paper $num' : subjectName;

    // All optional papers go into one grouped category
    return ('${examId}_mains_optional', 'Mains Optional Papers', 'assignment', title);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static String _deriveTitle(List<String> parts, String fallback) {
    if (parts.isEmpty) return fallback;
    final key = parts.join('_').toLowerCase();
    if (_subjectNames.containsKey(key)) return _subjectNames[key]!;

    final firstKey = parts[0].toLowerCase();
    final baseKey = firstKey.replaceAll(RegExp(r'\d+$'), '');
    final subjectName = _subjectNames[firstKey] ??
        _subjectNames[baseKey] ??
        _titleCase(parts[0]);

    final num = _extractNumber(parts.last);
    return num != null ? '$subjectName Paper $num' : subjectName;
  }

  static String? _lookupSubject(String key) {
    final clean = key.toLowerCase();
    if (_subjectNames.containsKey(clean)) return _subjectNames[clean];
    final base = clean.replaceAll(RegExp(r'\d+$'), '');
    final num = _extractNumber(clean);
    final name = _subjectNames[base];
    if (name != null && num != null) return '$name Paper $num';
    return _subjectNames[base];
  }

  static int? _extractNumber(String s) {
    final match = RegExp(r'\d+$').firstMatch(s);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  static bool _isRomanNumeral(String s) =>
      RegExp(r'^(i{1,3}|iv|vi{0,3}|ix|xi{0,3})$').hasMatch(s.toLowerCase());

  static String _titleCase(String s) => s.isEmpty
      ? s
      : s
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' ');

  static String iconFor(String categoryName) {
    for (final entry in _categoryIcons.entries) {
      if (categoryName.startsWith(entry.key)) return entry.value;
    }
    return 'assignment';
  }
}
