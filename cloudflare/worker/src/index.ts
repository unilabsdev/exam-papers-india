import { createClient } from '@supabase/supabase-js';

// ── Env bindings (set via wrangler secrets / wrangler.toml) ───────────────────

export interface Env {
  PAPERS_BUCKET: R2Bucket;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  // Optional: a shared secret the Flutter app sends in X-Worker-Key header
  // to protect the /list endpoint. Leave empty to allow unauthenticated reads.
  WORKER_API_KEY: string;
}

// ── Prefix maps (keep in sync with file_name_parser.dart) ────────────────────

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

// ── Filename parser ───────────────────────────────────────────────────────────

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
  const base = clean.replace(/\d+$/, '');
  const num  = extractNumber(clean);
  const name = SUBJECT_NAMES[base];
  if (name && num != null) return `${name} Paper ${num}`;
  return SUBJECT_NAMES[base] ?? null;
}

function resolveOptional(examId: string, subParts: string[]): [string, string, string, string] {
  if (subParts.length === 0) {
    return [`${examId}_mains_optional`, 'Mains Optional Papers', 'assignment', 'Optional Paper'];
  }
  const lastPart   = subParts[subParts.length - 1];
  const paperNum   = extractNumber(lastPart);
  const subjectParts = (paperNum != null && lastPart === `p${paperNum}`)
    ? subParts.slice(0, -1) : subParts;
  const fullKey    = subjectParts.join('_').toLowerCase();
  const firstKey   = subjectParts.length > 0 ? subjectParts[0].toLowerCase() : '';
  const baseKey    = firstKey.replace(/\d+$/, '');
  const subjectName = SUBJECT_NAMES[fullKey] ?? SUBJECT_NAMES[firstKey] ?? SUBJECT_NAMES[baseKey] ?? titleCase(subjectParts.join(' '));
  const num  = paperNum ?? extractNumber(firstKey);
  const title = num != null ? `${subjectName} Paper ${num}` : subjectName;
  return [`${examId}_mains_optional`, 'Mains Optional Papers', 'assignment', title];
}

function deriveTitle(parts: string[], fallback: string): string {
  if (parts.length === 0) return fallback;
  const key = parts.join('_').toLowerCase();
  if (SUBJECT_NAMES[key]) return SUBJECT_NAMES[key];
  const firstKey    = parts[0].toLowerCase();
  const baseKey     = firstKey.replace(/\d+$/, '');
  const subjectName = SUBJECT_NAMES[firstKey] ?? SUBJECT_NAMES[baseKey] ?? titleCase(parts[0]);
  const num = extractNumber(parts[parts.length - 1]);
  return num != null ? `${subjectName} Paper ${num}` : subjectName;
}

function resolveCategory(examId: string, year: number, parts: string[]): [string, string, string, string] {
  if (parts.length === 0) return [`${examId}_papers`, 'Question Papers', 'assignment', 'Paper'];

  const p0 = parts[0].toLowerCase();

  if (p0 === 'n' || p0 === 'n1' || p0 === 'notification') {
    return [`${examId}_exam_notification`, 'Exam Notification', 'notifications', `${year} Notification`];
  }
  if (isRomanNumeral(p0)) {
    const setLabel = p0.toUpperCase();
    const subParts = parts.slice(1);
    if (subParts.length === 0) return [`${examId}_set_${p0}`, `Set ${setLabel}`, 'assignment', `Set ${setLabel}`];
    const subjectName = lookupSubject(subParts.join('_').toLowerCase()) ?? titleCase(subParts.join(' '));
    return [`${examId}_set_${p0}`, `Set ${setLabel}`, 'assignment', subjectName];
  }
  if (/^p\d+[a-z]?$/.test(p0) && parts.length === 1) {
    const num    = p0.replace(/^p/, '').replace(/[a-z]$/, '');
    const suffix = p0.replace(/^p\d+/, '').toUpperCase();
    return [`${examId}_question_papers`, 'Question Papers', 'assignment', `Paper ${num}${suffix ? ` (${suffix})` : ''}`];
  }
  if (p0 === 'pre' || p0 === 'prelims') {
    return [`${examId}_prelims`, 'Prelims Papers', 'school', deriveTitle(parts.slice(1), 'Paper')];
  }
  if (p0 === 'm' || p0 === 'mgs' || p0 === 'mains') {
    if (p0 === 'mgs' || (p0 === 'm' && parts.length === 1)) {
      const num = extractNumber(p0) ?? (parts.length > 1 ? extractNumber(parts[1]) : null);
      return [`${examId}_mains`, 'Mains', 'menu_book', num != null ? `General Studies Paper ${num}` : 'General Studies'];
    }
    const subParts = parts.slice(1);
    if (subParts.length > 0 && subParts[0].toLowerCase() === 'compulsory') {
      const lang = subParts.length > 1 ? (SUBJECT_NAMES[subParts[1].toLowerCase()] ?? titleCase(subParts[1])) : 'Language';
      return [`${examId}_comp_lang`, 'Compulsory Language', 'language', lang];
    }
    if (subParts.length > 0 && subParts[0].toLowerCase() === 'literature') {
      const lang     = subParts.length > 1 ? (SUBJECT_NAMES[subParts[1].toLowerCase()] ?? titleCase(subParts[1])) : 'Literature';
      const paperNum = subParts.length > 2 ? extractNumber(subParts[2]) : null;
      return [`${examId}_mains_literature`, 'Mains Literature Papers', 'library_books', `${lang}${paperNum != null ? ` Paper ${paperNum}` : ''}`];
    }
    if (subParts.length > 0 && subParts[0].toLowerCase() === 'optional') {
      return resolveOptional(examId, subParts.slice(1));
    }
    if (subParts.length >= 2 && subParts[0].toLowerCase() === 'general' && subParts[1].toLowerCase() === 'studies') {
      const num = subParts.length > 2 ? extractNumber(subParts[subParts.length - 1]) : null;
      return [`${examId}_mains_gs`, 'Mains General Studies Papers', 'menu_book', num != null ? `General Studies Paper ${num}` : 'General Studies'];
    }
    return [`${examId}_mains_gs`, 'Mains General Studies Papers', 'menu_book', deriveTitle(subParts, 'Paper')];
  }
  if (p0 === 'opt' || p0 === 'optional') return resolveOptional(examId, parts.slice(1));
  if (p0 === 'comp') {
    const lang = parts.length > 1 ? (SUBJECT_NAMES[parts[1].toLowerCase()] ?? titleCase(parts[1])) : 'Language';
    return [`${examId}_comp_lang`, 'Compulsory Language', 'language', lang];
  }
  if (p0 === 'lit') {
    const lang     = parts.length > 1 ? (SUBJECT_NAMES[parts[1].toLowerCase()] ?? titleCase(parts[1])) : 'Literature';
    const paperNum = parts.length > 2 ? extractNumber(parts[2]) : null;
    return [`${examId}_mains_literature`, 'Mains Literature Papers', 'library_books', `${lang}${paperNum != null ? ` Paper ${paperNum}` : ''}`];
  }
  if (p0 === 'essay') return [`${examId}_mains_essay`, 'Mains Essay Papers', 'edit_note', 'Essay'];
  if (/^mgs\d+$/.test(p0)) {
    return [`${examId}_mains_gs`, 'Mains General Studies Papers', 'menu_book', `General Studies Paper ${extractNumber(p0)}`];
  }
  const subjectName = lookupSubject(parts.join('_')) ?? lookupSubject(p0) ?? titleCase(parts.join(' '));
  return [`${examId}_papers`, 'Question Papers', 'assignment', subjectName];
}

function parseFilename(filename: string, r2BaseUrl: string): ParsedFile | null {
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

  return { id: raw, examId, year, categoryId: catId, categoryName: catName, categoryIconName: catIcon, title, pdfUrl: `${r2BaseUrl}${filename}` };
}

// ── Supabase DB helpers ───────────────────────────────────────────────────────

async function upsertToDb(parsed: ParsedFile, supabase: ReturnType<typeof createClient>) {
  const { error: yearErr } = await supabase.rpc('upsert_exam_year', {
    p_exam_id: parsed.examId, p_year: parsed.year, p_paper_count: 1,
  });
  if (yearErr) console.error('upsert_exam_year error:', yearErr.message);

  const { error: catErr } = await supabase.from('categories').upsert(
    { id: parsed.categoryId, exam_id: parsed.examId, name: parsed.categoryName, icon_name: parsed.categoryIconName, description: parsed.categoryName },
    { onConflict: 'id', ignoreDuplicates: true },
  );
  if (catErr) console.error('categories upsert error:', catErr.message);

  const { error: paperErr } = await supabase.from('papers').upsert(
    { id: parsed.id, exam_id: parsed.examId, year: parsed.year, category_id: parsed.categoryId, category_name: parsed.categoryName, title: parsed.title, pdf_url: parsed.pdfUrl },
    { onConflict: 'id' },
  );
  if (paperErr) console.error('papers upsert error:', paperErr.message);
}

// ── Route helpers ─────────────────────────────────────────────────────────────

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  });
}

function checkApiKey(request: Request, env: Env): boolean {
  if (!env.WORKER_API_KEY) return true; // key not configured → open
  return request.headers.get('X-Worker-Key') === env.WORKER_API_KEY;
}

// ── Main fetch handler ────────────────────────────────────────────────────────

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url      = new URL(request.url);
    const pathname = url.pathname;

    // ── GET /list ── return all PDF filenames in the R2 bucket ───────────────
    if (request.method === 'GET' && pathname === '/list') {
      if (!checkApiKey(request, env)) return json({ error: 'Unauthorized' }, 401);

      const files: string[] = [];
      let cursor: string | undefined;

      do {
        const result: R2Objects = await env.PAPERS_BUCKET.list({ limit: 1000, cursor });
        for (const obj of result.objects) {
          if (obj.key.endsWith('.pdf')) files.push(obj.key);
        }
        cursor = result.truncated ? result.cursor : undefined;
      } while (cursor);

      return json({ files });
    }

    // ── POST /process ── webhook: process a single uploaded filename ─────────
    // Call this after uploading a PDF to R2 to instantly update the DB.
    // Body: { "filename": "upsc_cse_2024_mgs1.pdf" }
    if (request.method === 'POST' && pathname === '/process') {
      if (!checkApiKey(request, env)) return json({ error: 'Unauthorized' }, 401);

      let filename: string;
      try {
        const body = await request.json() as { filename?: string };
        filename   = body?.filename ?? '';
      } catch {
        return json({ error: 'Invalid JSON body' }, 400);
      }

      if (!filename) return json({ error: 'filename is required' }, 400);

      const r2BaseUrl = url.origin + '/'; // adjust if using a custom domain for public access
      const parsed    = parseFilename(filename, r2BaseUrl);
      if (!parsed) {
        console.log(`Skipping unrecognised file: ${filename}`);
        return json({ skipped: filename });
      }

      const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
      await upsertToDb(parsed, supabase);

      return json({ ok: true, parsed });
    }

    // ── R2 object-get passthrough (optional) ─────────────────────────────────
    // If your R2 bucket is NOT public, uncomment this to serve PDFs via the Worker.
    // if (request.method === 'GET' && pathname.startsWith('/papers/')) {
    //   const key    = pathname.slice('/papers/'.length);
    //   const object = await env.PAPERS_BUCKET.get(key);
    //   if (!object) return new Response('Not found', { status: 404 });
    //   return new Response(object.body, { headers: { 'Content-Type': 'application/pdf' } });
    // }

    return json({ error: 'Not found' }, 404);
  },
} satisfies ExportedHandler<Env>;
