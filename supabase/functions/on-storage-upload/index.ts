import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ── Config ─────────────────────────────────────────────────────────────────────

const SUPABASE_URL     = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const STORAGE_BASE     = `${SUPABASE_URL}/storage/v1/object/public/papers/`;

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

// ── Prefix maps ────────────────────────────────────────────────────────────────

const TWO_PART_PREFIX: Record<string, string> = {
  upsc_cse: 'upsc',
  ies_iss:  'ies_iss',
  nda_na:   'nda',
};

const ONE_PART_PREFIX: Record<string, string> = {
  capf: 'capf',
  cisf: 'cisf',
  cds:  'cds',
  cgse: 'cgse',
  cmse: 'cms',
  cso:  'so_ldce',
  ese:  'ese',
  ifos: 'geo_scientist',
};

// ── Subject names ──────────────────────────────────────────────────────────────

const SUBJECT_NAMES: Record<string, string> = {
  gs: 'General Studies', gat: 'General Ability Test', general_ability_test: 'General Ability Test',
  gk: 'General Knowledge', eng: 'English', math: 'Mathematics', maths: 'Mathematics',
  mp: 'Mathematics', stat: 'Statistics', ie: 'Indian Economics', ge: 'General Economics',
  agp: 'Agriculture', aep: 'Agriculture Engineering', anthro: 'Anthropology',
  chem: 'General Chemistry', geo: 'General Geology', geol: 'General Geology',
  geop: 'General Geophysics', geoph: 'General Geophysics', hydro: 'Hydrogeology',
  civil: 'Civil Engineering', mech: 'Mechanical Engineering', ee: 'Electrical Engineering',
  elec: 'Electronics and Telecommunication Engineering', cs: 'Computer Science',
  it: 'Information Technology', botany: 'Botany', zoology: 'Zoology', physics: 'Physics',
  forestry: 'Forestry', geology: 'Geology', assamese: 'Assamese', bengali: 'Bengali',
  ben: 'Bengali', gujarati: 'Gujarati', guj: 'Gujarati', hindi: 'Hindi', kannada: 'Kannada',
  malayalam: 'Malayalam', manipuri: 'Manipuri', marathi: 'Marathi', odia: 'Odia',
  punjabi: 'Punjabi', sanskrit: 'Sanskrit', sindhi: 'Sindhi', tamil: 'Tamil',
  telugu: 'Telugu', urdu: 'Urdu', english: 'English', agriculture: 'Agriculture',
  animal: 'Animal Husbandry', chemical: 'Chemical Engineering', statistics: 'Statistics',
  geography: 'Geography', management: 'Management', sociology: 'Sociology',
  history: 'History', commerce: 'Commerce', law: 'Law', philosophy: 'Philosophy',
  psychology: 'Psychology', political: 'Political Science',
};

const CATEGORY_ICONS: Record<string, string> = {
  Prelims: 'school', Mains: 'menu_book', 'Question Papers': 'assignment',
  'Exam Notification': 'notifications', 'Compulsory Language': 'language',
  Literature: 'library_books', Optional: 'assignment',
};

// ── Parser ─────────────────────────────────────────────────────────────────────

interface ParsedFile {
  id: string; examId: string; year: number;
  categoryId: string; categoryName: string; categoryIconName: string;
  title: string; pdfUrl: string;
}

function extractNumber(s: string): number | null {
  const m = s.match(/\d+$/);
  return m ? parseInt(m[0], 10) : null;
}

function titleCase(s: string): string {
  return s.split(' ').map(w => w ? w[0].toUpperCase() + w.slice(1).toLowerCase() : w).join(' ');
}

function isRomanNumeral(s: string): boolean {
  return /^(i{1,3}|iv|vi{0,3}|ix|xi{0,3})$/.test(s.toLowerCase());
}

function lookupSubject(key: string): string | null {
  const clean = key.toLowerCase();
  if (SUBJECT_NAMES[clean]) return SUBJECT_NAMES[clean];
  const base  = clean.replace(/\d+$/, '');
  const num   = extractNumber(clean);
  const name  = SUBJECT_NAMES[base];
  if (name && num != null) return `${name} Paper ${num}`;
  return SUBJECT_NAMES[base] ?? null;
}

function iconFor(categoryName: string): string {
  for (const [key, icon] of Object.entries(CATEGORY_ICONS)) {
    if (categoryName.startsWith(key)) return icon;
  }
  return 'assignment';
}

function resolveOptional(examId: string, subParts: string[]): [string, string, string, string] {
  if (subParts.length === 0) {
    return [`${examId}_mains_optional`, 'Mains Optional Papers', 'assignment', 'Optional Paper'];
  }

  const lastPart  = subParts[subParts.length - 1];
  const paperNum  = extractNumber(lastPart);
  const subjectParts = (paperNum != null && lastPart === `p${paperNum}`)
    ? subParts.slice(0, -1)
    : subParts;

  const fullKey  = subjectParts.join('_').toLowerCase();
  const firstKey = subjectParts.length > 0 ? subjectParts[0].toLowerCase() : '';
  const baseKey  = firstKey.replace(/\d+$/, '');

  const subjectName = SUBJECT_NAMES[fullKey]
    ?? SUBJECT_NAMES[firstKey]
    ?? SUBJECT_NAMES[baseKey]
    ?? titleCase(subjectParts.join(' '));

  const num   = paperNum ?? extractNumber(firstKey);
  const title = num != null ? `${subjectName} Paper ${num}` : subjectName;

  return [`${examId}_mains_optional`, 'Mains Optional Papers', 'assignment', title];
}

function deriveTitle(parts: string[], fallback: string): string {
  if (parts.length === 0) return fallback;
  const key = parts.join('_').toLowerCase();
  if (SUBJECT_NAMES[key]) return SUBJECT_NAMES[key];
  const firstKey = parts[0].toLowerCase();
  const baseKey  = firstKey.replace(/\d+$/, '');
  const subjectName = SUBJECT_NAMES[firstKey] ?? SUBJECT_NAMES[baseKey] ?? titleCase(parts[0]);
  const num = extractNumber(parts[parts.length - 1]);
  return num != null ? `${subjectName} Paper ${num}` : subjectName;
}

function resolveCategory(
  examId: string, _year: number, parts: string[]
): [string, string, string, string] {

  if (parts.length === 0) {
    return [`${examId}_papers`, 'Question Papers', 'assignment', 'Paper'];
  }

  const p0 = parts[0].toLowerCase();

  // Exam Notification
  if (p0 === 'n' || p0 === 'n1' || p0 === 'notification') {
    return [`${examId}_exam_notification`, 'Exam Notification', 'notifications', `${_year} Notification`];
  }

  // Set indicator (CDS I/II, NDA I/II)
  if (isRomanNumeral(p0)) {
    const setLabel  = p0.toUpperCase();
    const subParts  = parts.slice(1);
    if (subParts.length === 0) return [`${examId}_set_${p0}`, `Set ${setLabel}`, 'assignment', `Set ${setLabel}`];
    const subjectKey  = subParts.join('_').toLowerCase();
    const subjectName = lookupSubject(subjectKey) ?? titleCase(subParts.join(' '));
    return [`${examId}_set_${p0}`, `Set ${setLabel}`, 'assignment', subjectName];
  }

  // Simple numbered paper (p1, p2, p2a …)
  if (/^p\d+[a-z]?$/.test(p0) && parts.length === 1) {
    const num    = p0.replace(/^p/, '').replace(/[a-z]$/, '');
    const suffix = p0.replace(/^p\d+/, '').toUpperCase();
    return [`${examId}_question_papers`, 'Question Papers', 'assignment',
      `Paper ${num}${suffix ? ` (${suffix})` : ''}`];
  }

  // Prelims
  if (p0 === 'pre' || p0 === 'prelims') {
    const subParts = parts.slice(1);
    const title    = deriveTitle(subParts, 'Paper');
    return [`${examId}_prelims`, 'Prelims Papers', 'school', title];
  }

  // Mains
  if (p0 === 'm' || p0 === 'mgs' || p0 === 'mains') {
    if (p0 === 'mgs' || (p0 === 'm' && parts.length === 1)) {
      const num = extractNumber(p0) ?? (parts.length > 1 ? extractNumber(parts[1]) : null);
      return [`${examId}_mains`, 'Mains', 'menu_book',
        num != null ? `General Studies Paper ${num}` : 'General Studies'];
    }
    const subParts = parts.slice(1);
    if (subParts.length > 0 && subParts[0].toLowerCase() === 'compulsory') {
      const lang = subParts.length > 1 ? (SUBJECT_NAMES[subParts[1].toLowerCase()] ?? titleCase(subParts[1])) : 'Language';
      return [`${examId}_comp_lang`, 'Compulsory Language', 'language', lang];
    }
    if (subParts.length > 0 && subParts[0].toLowerCase() === 'literature') {
      const lang     = subParts.length > 1 ? (SUBJECT_NAMES[subParts[1].toLowerCase()] ?? titleCase(subParts[1])) : 'Literature';
      const paperNum = subParts.length > 2 ? extractNumber(subParts[2]) : null;
      return [`${examId}_mains_literature`, 'Mains Literature Papers', 'library_books',
        `${lang}${paperNum != null ? ` Paper ${paperNum}` : ''}`];
    }
    if (subParts.length > 0 && subParts[0].toLowerCase() === 'optional') {
      return resolveOptional(examId, subParts.slice(1));
    }
    if (subParts.length >= 2 && subParts[0].toLowerCase() === 'general' && subParts[1].toLowerCase() === 'studies') {
      const num = subParts.length > 2 ? extractNumber(subParts[subParts.length - 1]) : null;
      return [`${examId}_mains_gs`, 'Mains General Studies Papers', 'menu_book',
        num != null ? `General Studies Paper ${num}` : 'General Studies'];
    }
    const title = deriveTitle(subParts, 'Paper');
    return [`${examId}_mains_gs`, 'Mains General Studies Papers', 'menu_book', title];
  }

  // Optional
  if (p0 === 'opt' || p0 === 'optional') return resolveOptional(examId, parts.slice(1));

  // Compulsory Language
  if (p0 === 'comp') {
    const lang = parts.length > 1 ? (SUBJECT_NAMES[parts[1].toLowerCase()] ?? titleCase(parts[1])) : 'Language';
    return [`${examId}_comp_lang`, 'Compulsory Language', 'language', lang];
  }

  // Literature
  if (p0 === 'lit') {
    const lang     = parts.length > 1 ? (SUBJECT_NAMES[parts[1].toLowerCase()] ?? titleCase(parts[1])) : 'Literature';
    const paperNum = parts.length > 2 ? extractNumber(parts[2]) : null;
    return [`${examId}_mains_literature`, 'Mains Literature Papers', 'library_books',
      `${lang}${paperNum != null ? ` Paper ${paperNum}` : ''}`];
  }

  // Essay
  if (p0 === 'essay') return [`${examId}_mains_essay`, 'Mains Essay Papers', 'edit_note', 'Essay'];

  // mgs1…mgs4
  if (/^mgs\d+$/.test(p0)) {
    const num = extractNumber(p0);
    return [`${examId}_mains_gs`, 'Mains General Studies Papers', 'menu_book', `General Studies Paper ${num}`];
  }

  // Fallback
  const subjectName = lookupSubject(parts.join('_')) ?? lookupSubject(p0) ?? titleCase(parts.join(' '));
  return [`${examId}_papers`, 'Question Papers', 'assignment', subjectName];
}

function parseFilename(filename: string): ParsedFile | null {
  const raw   = filename.endsWith('.pdf') ? filename.slice(0, -4) : filename;
  const parts = raw.split('_');
  if (parts.length < 3) return null;

  let examId: string | null = null;
  let yearIndex = 1;

  if (parts.length >= 4) {
    const twoPartKey = `${parts[0]}_${parts[1]}`.toLowerCase();
    const twoPartId  = TWO_PART_PREFIX[twoPartKey];
    if (twoPartId) { examId = twoPartId; yearIndex = 2; }
  }
  examId = examId ?? ONE_PART_PREFIX[parts[0].toLowerCase()] ?? null;
  if (!examId) return null;

  const year = parseInt(parts[yearIndex], 10);
  if (isNaN(year) || year < 2000 || year > 2100) return null;

  const rest = parts.slice(yearIndex + 1);
  const [catId, catName, catIcon, title] = resolveCategory(examId, year, rest);

  return {
    id:               raw,
    examId,
    year,
    categoryId:       catId,
    categoryName:     catName,
    categoryIconName: catIcon,
    title,
    pdfUrl:           `${STORAGE_BASE}${filename}`,
  };
}

// ── DB helpers ─────────────────────────────────────────────────────────────────

async function ensureExamYear(examId: string, year: number, paperCount = 1) {
  // Upsert exam_years row; increment paper_count if it already exists
  const { error } = await supabase.rpc('upsert_exam_year', {
    p_exam_id:    examId,
    p_year:       year,
    p_paper_count: paperCount,
  });
  if (error) console.error('ensureExamYear error:', error.message);
}

async function ensureCategory(
  categoryId: string, examId: string, name: string, icon: string
) {
  const { error } = await supabase.from('categories').upsert(
    { id: categoryId, exam_id: examId, name, icon_name: icon, description: name },
    { onConflict: 'id', ignoreDuplicates: true }
  );
  if (error) console.error('ensureCategory error:', error.message);
}

async function upsertPaper(p: ParsedFile) {
  const { error } = await supabase.from('papers').upsert(
    {
      id:            p.id,
      exam_id:       p.examId,
      year:          p.year,
      category_id:   p.categoryId,
      category_name: p.categoryName,
      title:         p.title,
      pdf_url:       p.pdfUrl,
    },
    { onConflict: 'id' }
  );
  if (error) console.error('upsertPaper error:', error.message);
}

// ── Entry point ────────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  try {
    const body = await req.json();
    // Supabase storage webhook payload: body.record.name contains the file path
    const record = body?.record ?? body;
    const fileName = record?.name ?? record?.key ?? '';

    if (!fileName) {
      return new Response(JSON.stringify({ error: 'No filename in payload' }), { status: 400 });
    }

    // Strip leading bucket prefix if present (e.g. "papers/upsc_cse_2024_mgs1.pdf")
    const rawName = fileName.includes('/') ? fileName.split('/').pop()! : fileName;

    const parsed = parseFilename(rawName);
    if (!parsed) {
      console.log(`Skipping unrecognised file: ${rawName}`);
      return new Response(JSON.stringify({ skipped: rawName }), { status: 200 });
    }

    console.log(`Processing: ${rawName} → exam=${parsed.examId}, year=${parsed.year}, cat=${parsed.categoryId}`);

    // Write to DB in order: exam_year → category → paper
    await ensureExamYear(parsed.examId, parsed.year);
    await ensureCategory(parsed.categoryId, parsed.examId, parsed.categoryName, parsed.categoryIconName);
    await upsertPaper(parsed);

    return new Response(JSON.stringify({ ok: true, parsed }), { status: 200 });
  } catch (err) {
    console.error('Edge function error:', err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
