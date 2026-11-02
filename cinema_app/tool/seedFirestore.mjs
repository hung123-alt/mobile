// seedFirestore.mjs — Gọi VSMOV API → Đổ thẳng vào Firestore cho mobile.
// Chạy: cd cinema_app/tool && npm i firebase-admin && node seedFirestore.mjs
// Cần file serviceAccountKey.json (Firebase Console → Project settings → Service accounts)
// hoặc set env GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
// ============================================================
// CHÍNH SÁCH (giống server/src/seed.ts — IDEMPOTENT):
//   • KHÔNG xóa collection nào. Phim cũ + Server 2 thêm tay GIỮ NGUYÊN.
//   • Chỉ INSERT phim MỚI (slug chưa có trong `movies`).
//   • Phim đã có → skip toàn bộ.
// ============================================================
import admin from 'firebase-admin';
import { readFileSync, existsSync } from 'fs';

const VSMOV = 'https://vsmov.com/api';
const PAGES = Number(process.env.SEED_PAGES ?? 5);
const DELAY = 1200;

const keyPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ?? './serviceAccountKey.json';
if (!existsSync(keyPath)) {
  console.error(`❌ Không thấy key: ${keyPath}`);
  console.error('Tải ở Firebase Console → Project settings → Service accounts → Generate key,');
  console.error('đặt vào cinema_app/tool/serviceAccountKey.json rồi chạy lại.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(readFileSync(keyPath, 'utf8'))),
});
const db = admin.firestore();

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

function mapType(vsmovType, catSlugs) {
  if (catSlugs.some((s) => s === 'hoat-hinh')) return 'hoat_hinh';
  if (catSlugs.some((s) => s.includes('anime'))) return 'anime';
  return vsmovType === 'tv' || vsmovType === 'series' ? 'phim_bo' : 'phim_le';
}
const mapStatus = (s) => (s === 'completed' ? 'completed' : 'ongoing');
function parseRating(v) {
  if (!v || v === '0.0') return 0;
  const n = parseFloat(v);
  return isNaN(n) ? 0 : Math.min(n, 9.9);
}
function parseEpisodes(epStr) {
  if (!epStr) return 0;
  const m = String(epStr).match(/(\d+)/g);
  if (!m) return 0;
  return m.length >= 2 ? parseInt(m[1]) : parseInt(m[0]);
}
const slugifyServer = (s) =>
  s.toLowerCase().trim().replace(/[^a-z0-9]+/gi, '-').replace(/^-+|-+$/g, '') ||
  'server-1';

async function fetchList() {
  console.log(`\n📥 Lấy danh sách phim (${PAGES} trang)...`);
  const all = [];
  for (let p = 1; p <= PAGES; p++) {
    try {
      const res = await fetch(`${VSMOV}/danh-sach/phim-moi-cap-nhat?page=${p}`, {
        headers: { Accept: 'application/json' },
      });
      const data = await res.json();
      if (data?.items?.length > 0) {
        all.push(...data.items);
        console.log(`   ✅ Trang ${p}: +${data.items.length} (tổng ${all.length})`);
      } else {
        console.log(`   ⚠️  Trang ${p}: trống, dừng.`);
        break;
      }
      if (p < PAGES) await wait(DELAY);
    } catch (e) {
      console.error(`   ❌ Trang ${p}: ${e.message}`);
      break;
    }
  }
  return all;
}

async function fetchDetail(slug) {
  try {
    const res = await fetch(`${VSMOV}/phim/${slug}`, {
      headers: { Accept: 'application/json' },
    });
    return await res.json();
  } catch {
    return null;
  }
}

async function getMaxMovieId() {
  const snap = await db.collection('movies').orderBy('id', 'desc').limit(1).get();
  return snap.empty ? 0 : Number(snap.docs[0].data().id ?? 0);
}

async function ensureGenre(cat) {
  const ref = db.collection('genres').doc(cat.slug);
  const doc = await ref.get();
  if (doc.exists) return doc.data();
  // id số để tương thích admin_movie_edit_page (movie_genres dùng genre_id int)
  const all = await db.collection('genres').get();
  let maxId = 0;
  all.forEach((d) => {
    const v = Number(d.data().id ?? 0);
    if (v > maxId) maxId = v;
  });
  const payload = { id: maxId + 1, name: cat.name, slug: cat.slug, is_visible: 1, isVisible: true };
  await ref.set(payload, { merge: true });
  return payload;
}

async function ensureCountry(c) {
  const ref = db.collection('countries').doc(c.slug);
  const doc = await ref.get();
  if (doc.exists) return doc.data();
  const all = await db.collection('countries').get();
  let maxId = 0;
  all.forEach((d) => {
    const v = Number(d.data().id ?? 0);
    if (v > maxId) maxId = v;
  });
  const payload = { id: maxId + 1, name: c.name, slug: c.slug };
  await ref.set(payload, { merge: true });
  return payload;
}

async function main() {
  console.log('═══════════════════════════════════════');
  console.log('  CINEMA MOBILE — Seed Firestore từ VSMOV');
  console.log('  (IDEMPOTENT: chỉ thêm phim mới theo slug)');
  console.log('═══════════════════════════════════════');

  const list = await fetchList();
  if (!list.length) {
    console.log('❌ Không lấy được phim nào.');
    process.exit(1);
  }

  let nextId = (await getMaxMovieId()) + 1;
  let insertedMovies = 0;
  let insertedEpisodes = 0;
  let skipped = 0;

  for (let i = 0; i < list.length; i++) {
    const item = list[i];
    const exist = await db.collection('movies').where('slug', '==', item.slug).limit(1).get();
    if (!exist.empty) {
      skipped++;
      continue;
    }

    const detailRes = await fetchDetail(item.slug);
    if (!detailRes?.movie) {
      skipped++;
      continue;
    }
    const detail = detailRes.movie;
    const episodes = Array.isArray(detailRes.episodes) ? detailRes.episodes : [];
    const categories = Array.isArray(detail.category) ? detail.category : [];
    const countries = Array.isArray(detail.country) ? detail.country : [];
    const catSlugs = categories.map((c) => c.slug);

    const type = mapType(detail.type || 'movie', catSlugs);
    const status = mapStatus(detail.status || 'ongoing');
    const rating = parseRating(detail.tmdb?.vote_average ?? '0');
    const totalEp = parseEpisodes(detail.episode_total);
    const nowIso = new Date().toISOString();
    const movieId = nextId++;

    const moviePayload = {
      id: movieId,
      title: detail.name,
      name: detail.name,
      slug: item.slug,
      description: detail.content ?? '',
      posterUrl: item.poster_url ?? null,
      poster_url: item.poster_url ?? null,
      bannerUrl: item.thumb_url ?? item.poster_url ?? null,
      banner_url: item.thumb_url ?? item.poster_url ?? null,
      type,
      status,
      releaseYear: detail.year || null,
      release_year: detail.year || null,
      totalEpisodes: totalEp,
      total_episodes: totalEp,
      isVisible: true,
      is_visible: 1,
      isFeatured: rating >= 8.5,
      is_featured: rating >= 8.5 ? 1 : 0,
      viewCount: detail.view || 0,
      view_count: detail.view || 0,
      avgRating: rating,
      avg_rating: rating,
      ratingCount: 0,
      rating_count: 0,
      createdAt: nowIso,
      created_at: nowIso,
      updatedAt: nowIso,
      updated_at: nowIso,
    };
    // docId = id dạng chuỗi → khớp AdminMovieEditPage (doc(targetMovieId.toString()))
    await db.collection('movies').doc(String(movieId)).set(moviePayload, { merge: true });
    insertedMovies++;

    for (const cat of categories) {
      const g = await ensureGenre(cat);
      await db
        .collection('movie_genres')
        .doc(`${movieId}_${g.id}`)
        .set({ movie_id: movieId, movieId, genre_id: g.id, genreId: g.id }, { merge: true });
    }
    for (const c of countries) {
      const co = await ensureCountry(c);
      await db
        .collection('movie_countries')
        .doc(`${movieId}_${co.id}`)
        .set({ movie_id: movieId, movieId, country_id: co.id, countryId: co.id }, { merge: true });
    }

    for (const server of episodes) {
      const serverData = Array.isArray(server?.server_data) ? server.server_data : [];
      const serverName = server?.server_name?.trim() || 'VSMOV';
      for (const ep of serverData) {
        const linkToSave = ep.link_embed || ep.link_m3u8;
        if (!linkToSave) continue;
        let epNum = 0;
        const m = String(ep.filename || ep.name || '').match(/\d+/);
        if (m) epNum = parseInt(m[0]);
        if (epNum <= 0) epNum = serverData.indexOf(ep) + 1;
        if (epNum <= 0) continue;
        // docId gồm server để multi-server cùng tập không đè nhau
        const epDocId = `${movieId}_${epNum}_${slugifyServer(serverName)}`;
        const epId = movieId * 1000 + epNum;
        await db
          .collection('episodes')
          .doc(epDocId)
          .set(
            {
              id: epId,
              movie_id: movieId,
              movieId,
              episode_number: epNum,
              episodeNumber: epNum,
              name: ep.filename || `Tập ${epNum}`,
              title: ep.filename || `Tập ${epNum}`,
              embed_url: linkToSave,
              embedUrl: linkToSave,
              server_name: serverName,
              serverName,
              duration_seconds: 0,
              durationSeconds: 0,
              skip_intro_seconds: 0,
              skipIntroSeconds: 0,
              updatedAt: nowIso,
              updated_at: nowIso,
            },
            { merge: true },
          );
        insertedEpisodes++;
      }
    }

    if ((i + 1) % 10 === 0) console.log(`   📦 Đã xử lý ${i + 1}/${list.length}...`);
    await wait(DELAY);
  }

  console.log('\n═══════════════════════════════════════');
  console.log('  KẾT QUẢ SEED FIRESTORE');
  console.log('═══════════════════════════════════════');
  console.log(`   ✅ Phim mới:  ${insertedMovies}`);
  console.log(`   ✅ Tập phim:  ${insertedEpisodes}`);
  console.log(`   ⏭️  Bỏ qua:   ${skipped} (slug đã có — giữ data cũ)`);
  console.log('═══════════════════════════════════════\n');
}

main().catch((e) => {
  console.error('❌ Lỗi:', e);
  process.exit(1);
});
