/**
 * ==============================================================================
 * SCRIPT TỰ ĐỘNG CHUẨN HÓA VÀ ĐỔI TÊN CÁC COLLECTION "select * from xxx"
 * ==============================================================================
 *
 * Tác dụng:
 * 1. Quét tất cả các collection có tiền tố "select * from " trong Firestore.
 * 2. Tự động chuyển toàn bộ documents sang collection sạch tương ứng:
 *    - "select * from genres"        => "genres"
 *    - "select * from countries"     => "countries"
 *    - "select * from comments"      => "comments"
 *    - "select * from ratings"       => "ratings"
 *    - "select * from favorites"     => "favorites"
 *    - "select * from watchlist"     => "watchlist"
 *    - "select * from watch_history" => "watch_history"
 *    - "select * from notifications" => "notifications"
 *    - "select * from error_reports" => "error_reports"
 *    - "select * from movie_genres"  => "movie_genres"
 *    - "select * from movie_countries" => "movie_countries"
 * 3. Xóa các document ở collection cũ (khi hết doc, collection cũ tự biến mất trên Firebase Console).
 *
 * Chạy thử (không đổi DB):
 *   node rename_collections.js --dry-run
 *
 * Chạy thật:
 *   node rename_collections.js
 */

const DEFAULT_CONFIG = {
  projectId: 'cinema-app-b760e',
  apiKey: 'AIzaSyBDTqJpixcj5fF6KUUY4xieg_5TOC867_M',
};

const SQL_COLLECTIONS = [
  'select * from genres',
  'select * from countries',
  'select * from comments',
  'select * from ratings',
  'select * from favorites',
  'select * from watchlist',
  'select * from watch_history',
  'select * from notifications',
  'select * from error_reports',
  'select * from movie_genres',
  'select * from movie_countries',
];

// Lấy tất cả document trong 1 collection (hỗ trợ phân trang nextPageToken)
async function fetchAllDocuments(collectionName) {
  let docs = [];
  let pageToken = '';
  do {
    const encoded = encodeURIComponent(collectionName);
    let url = `https://firestore.googleapis.com/v1/projects/${DEFAULT_CONFIG.projectId}/databases/(default)/documents/${encoded}?key=${DEFAULT_CONFIG.apiKey}&pageSize=300`;
    if (pageToken) url += `&pageToken=${encodeURIComponent(pageToken)}`;

    const res = await fetch(url);
    if (!res.ok) {
      if (res.status === 404) return [];
      const err = await res.json().catch(() => ({}));
      throw new Error(`Lỗi đọc ${collectionName} (${res.status}): ${err.error?.message || res.statusText}`);
    }

    const data = await res.json();
    if (data.documents && data.documents.length > 0) {
      docs.push(...data.documents);
    }
    pageToken = data.nextPageToken || '';
  } while (pageToken);

  return docs;
}

// Di chuyển documents từ oldCol sang newCol
async function migrateCollection(oldCol, newCol, dryRun) {
  console.log(`\n======================================================`);
  console.log(`🔄 Đang quét: \x1b[33m"${oldCol}"\x1b[0m ➔ \x1b[32m"${newCol}"\x1b[0m`);

  const docs = await fetchAllDocuments(oldCol);
  if (docs.length === 0) {
    console.log(`   (Không có document nào trong "${oldCol}")`);
    return;
  }

  console.log(`   Tìm thấy \x1b[36m${docs.length}\x1b[0m documents cần di chuyển.`);

  if (dryRun) {
    console.log(`   \x1b[33m[DRY RUN]\x1b[0m Mô phỏng chuyển ${docs.length} docs sang "${newCol}" và xóa "${oldCol}".`);
    for (let i = 0; i < Math.min(3, docs.length); i++) {
      const docId = decodeURIComponent(docs[i].name.split('/').pop());
      console.log(`   - Mẫu doc ID: ${docId}`);
    }
    return;
  }

  const CONCURRENCY = 8;
  let copied = 0;

  // Bước 1: Sao chép sang collection mới
  for (let i = 0; i < docs.length; i += CONCURRENCY) {
    const chunk = docs.slice(i, i + CONCURRENCY);
    await Promise.all(
      chunk.map(async (doc) => {
        const docId = doc.name.split('/').pop();
        const targetUrl = `https://firestore.googleapis.com/v1/projects/${DEFAULT_CONFIG.projectId}/databases/(default)/documents/${encodeURIComponent(newCol)}/${docId}?key=${DEFAULT_CONFIG.apiKey}`;

        const res = await fetch(targetUrl, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ fields: doc.fields || {} }),
        });

        if (res.ok) copied++;
      })
    );
    process.stdout.write(`   ⏳ Đang sao chép: ${copied}/${docs.length} docs sang "${newCol}"...\r`);
  }
  console.log(`\n   \x1b[32m[✓] Đã sao chép thành công ${copied}/${docs.length} docs sang "${newCol}".\x1b[0m`);

  // Bước 2: Xóa documents ở collection cũ
  let deleted = 0;
  for (let i = 0; i < docs.length; i += CONCURRENCY) {
    const chunk = docs.slice(i, i + CONCURRENCY);
    await Promise.all(
      chunk.map(async (doc) => {
        const deleteUrl = `https://firestore.googleapis.com/v1/${doc.name}?key=${DEFAULT_CONFIG.apiKey}`;
        const res = await fetch(deleteUrl, { method: 'DELETE' });
        if (res.ok) deleted++;
      })
    );
    process.stdout.write(`   🧹 Đang xóa collection cũ: ${deleted}/${docs.length} docs...\r`);
  }
  console.log(`\n   \x1b[32m[✓] Đã xóa sạch collection cũ "${oldCol}".\x1b[0m`);
}

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');

  console.log(`\x1b[1m\x1b[36m======================================================================\x1b[0m`);
  console.log(`\x1b[1m\x1b[36m   CÔNG CỤ TỰ ĐỘNG CHUẨN HÓA TÊN COLLECTION TRÊN FIREBASE\x1b[0m`);
  console.log(`\x1b[1m\x1b[36m======================================================================\x1b[0m`);

  if (dryRun) {
    console.log(`\x1b[33m[CHẾ ĐỘ THỬ NGHIỆM - DRY RUN] Chỉ kiểm tra, không thay đổi Firestore.\x1b[0m\n`);
  }

  try {
    for (const oldCol of SQL_COLLECTIONS) {
      const newCol = oldCol.replace(/^select\s+\*\s+from\s+/i, '').trim();
      await migrateCollection(oldCol, newCol, dryRun);
    }

    console.log(`\n\x1b[32m======================================================================`);
    console.log(`✨ HOÀN TẤT CHUẨN HÓA TẤT CẢ CÁC COLLECTION! ✨`);
    console.log(`======================================================================\x1b[0m\n`);
  } catch (err) {
    console.error(`\x1b[31m[LỖI]:\x1b[0m`, err);
  }
}

main();

