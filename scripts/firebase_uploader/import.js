/**
 * ==============================================================================
 * SCRIPT IMPORT DATA TỪ JSON LÊN CLOUD FIRESTORE CHO CINEMA APP
 * ==============================================================================
 *
 * Tính năng chính:
 * 1. KHÔNG CẦN TẢI FILE KEY: Mặc định sử dụng Web API Key đã có sẵn trong
 *    `firebase_options.dart` để kết nối thẳng tới Firestore.
 * 2. Tự động dùng Admin SDK nếu phát hiện file `serviceAccountKey.json`.
 * 3. Hỗ trợ import 1 file JSON đơn lẻ hoặc nhiều file cùng lúc (--all, --dir).
 * 4. Tự động nhận diện file JSON đa collection: { "movies": [...], "genres": [...] }.
 * 5. Chiến lược Document ID thông minh (theo slug, movieId_episode, id, hoặc auto-ID).
 * 6. Hỗ trợ --dry-run (chạy thử) và --clear (làm sạch trước khi ghi).
 */

const fs = require('fs');
const path = require('path');

// Cấu hình Firebase mặc định lấy từ lib/firebase_options.dart của dự án
const DEFAULT_CONFIG = {
  projectId: 'cinema-app-b760e',
  apiKey: 'AIzaSyBDTqJpixcj5fF6KUUY4xieg_5TOC867_M',
  appId: '1:797999836605:web:7688a386eb0adf57cf76d4',
};

// 1. Kiểm tra xem có serviceAccountKey.json không
function findServiceAccountKey() {
  const possibleNames = [
    'serviceAccountKey.json',
    'serviceAccount.json',
    'firebase-admin.json',
  ];

  for (const name of possibleNames) {
    const filePath = path.resolve(__dirname, name);
    if (fs.existsSync(filePath)) return filePath;
  }

  const currentFiles = fs.readdirSync(__dirname);
  for (const file of currentFiles) {
    if (file.endsWith('.json') && file.toLowerCase().includes('firebase')) {
      const fullPath = path.resolve(__dirname, file);
      try {
        const json = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
        if (json.type === 'service_account' && json.private_key) {
          return fullPath;
        }
      } catch (_) {}
    }
  }
  return null;
}

// 2. Chuyển đổi dữ liệu JS sang định dạng Firestore REST Field Values
function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: val.toString() };
    return { doubleValue: val };
  }
  if (typeof val === 'string') return { stringValue: val };
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toFirestoreValue) } };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      if (v !== undefined) {
        fields[k] = toFirestoreValue(v);
      }
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v !== undefined) {
      fields[k] = toFirestoreValue(v);
    }
  }
  return fields;
}

// 3. Phân tích tham số dòng lệnh (CLI Arguments)
function parseArguments() {
  const args = process.argv.slice(2);
  const options = {
    file: null,
    dir: null,
    collection: null,
    all: false,
    clear: false,
    dryRun: false,
    help: false,
  };

  for (const arg of args) {
    if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else if (arg === '--all' || arg === '-a') {
      options.all = true;
    } else if (arg === '--clear') {
      options.clear = true;
    } else if (arg === '--dry-run') {
      options.dryRun = true;
    } else if (arg.startsWith('--file=')) {
      options.file = arg.substring('--file='.length);
    } else if (arg.startsWith('--dir=')) {
      options.dir = arg.substring('--dir='.length);
    } else if (arg.startsWith('--collection=')) {
      options.collection = arg.substring('--collection='.length);
    } else if (!arg.startsWith('-') && !options.file) {
      options.file = arg;
    }
  }

  return options;
}

function printHelp() {
  console.log(`
\x1b[1m\x1b[36mCÁCH SỬ DỤNG SCRIPT IMPORT FIREBASE (ZERO CONFIG - KHÔNG CẦN FILE KEY)\x1b[0m
------------------------------------------------------------------------------
\x1b[1m1. Import 1 file JSON đơn lẻ:\x1b[0m
   node import.js data/movies.sample.json
   node import.js --file=data/movies.sample.json --collection=movies

\x1b[1m2. Import TẤT CẢ các file JSON trong thư mục (nhiều file 1 lúc):\x1b[0m
   node import.js --all               (mặc định quét thư mục ./data/)
   node import.js --dir=./data        (quét thư mục chỉ định)

\x1b[1m3. Import 1 file JSON chứa nhiều collection:\x1b[0m
   node import.js data/full_db.json
   (Tự động nhận diện nếu JSON có dạng { "movies": [...], "genres": [...] })

\x1b[1m4. Các cờ bổ trợ:\x1b[0m
   --dry-run        Chạy thử nghiệm kiểm tra dữ liệu mà không ghi vào Firebase
   --clear          Xóa dữ liệu cũ của collection trước khi import mới
   --collection=xxx Chỉ định tên collection trên Firestore
   --help, -h       Hiển thị màn hình này
`);
}

// 4. Xác định Document ID theo quy ước của Cinema App
function resolveDocId(item, collectionName) {
  if (!item || typeof item !== 'object') return null;

  // Tập phim: {movieId}_{episodeNumber} -> ví dụ: "1_1"
  if (collectionName === 'episodes' && item.movieId !== undefined && item.episodeNumber !== undefined) {
    return `${item.movieId}_${item.episodeNumber}`;
  }

  // Ưu tiên Document ID theo slug (movies/genres/countries)
  if (item.slug && typeof item.slug === 'string' && item.slug.trim()) {
    return item.slug.trim();
  }

  // Nếu không có slug, dùng id
  if (item.id !== undefined && item.id !== null) {
    return String(item.id);
  }

  // Nếu là user
  if (item.uid) return String(item.uid);

  return null;
}

// 5. Xác định tên Collection từ tên file
function detectCollectionName(filePath, overrideName) {
  if (overrideName) return overrideName;
  const baseName = path.basename(filePath, path.extname(filePath));
  return baseName.replace(/\.sample$/, '');
}

// 6. Xóa dữ liệu cũ của collection
async function clearCollection(engine, collectionName) {
  console.log(`   \x1b[33m[!] Đang xóa dữ liệu cũ trong collection "${collectionName}"...\x1b[0m`);

  if (engine.type === 'admin') {
    const snapshot = await engine.db.collection(collectionName).get();
    if (snapshot.empty) return;
    const batchSize = 400;
    let batch = engine.db.batch();
    let count = 0;
    for (const doc of snapshot.docs) {
      batch.delete(doc.ref);
      count++;
      if (count % batchSize === 0) {
        await batch.commit();
        batch = engine.db.batch();
      }
    }
    if (count % batchSize !== 0) await batch.commit();
    console.log(`   \x1b[32m[✓] Đã xóa ${count} documents cũ (Admin SDK).\x1b[0m`);
  } else {
    // REST API
    const listUrl = `https://firestore.googleapis.com/v1/projects/${DEFAULT_CONFIG.projectId}/databases/(default)/documents/${collectionName}?key=${DEFAULT_CONFIG.apiKey}&pageSize=300`;
    try {
      const res = await fetch(listUrl);
      if (!res.ok) return;
      const data = await res.json();
      if (!data.documents || data.documents.length === 0) return;

      for (const doc of data.documents) {
        await fetch(`https://firestore.googleapis.com/v1/${doc.name}?key=${DEFAULT_CONFIG.apiKey}`, { method: 'DELETE' });
      }
      console.log(`   \x1b[32m[✓] Đã xóa ${data.documents.length} documents cũ.\x1b[0m`);
    } catch (e) {
      console.warn(`   [!] Không thể xóa tự động dữ liệu cũ: ${e.message}`);
    }
  }
}

// 7. Ghi dữ liệu vào Firestore
async function uploadCollectionData(engine, collectionName, items, dryRun) {
  console.log(`\n\x1b[1m🚀 Đang xử lý collection: \x1b[36m"${collectionName}"\x1b[0m (Tổng: \x1b[33m${items.length}\x1b[0m bản ghi)`);

  if (items.length === 0) {
    console.log('   (Không có dữ liệu để import)');
    return;
  }

  if (dryRun) {
    console.log(`   \x1b[33m[DRY RUN]\x1b[0m Mô phỏng ghi ${items.length} bản ghi vào collection "${collectionName}".`);
    for (let i = 0; i < Math.min(3, items.length); i++) {
      const docId = resolveDocId(items[i], collectionName);
      console.log(`   Mẫu [${i + 1}] Doc ID: "${docId || '(auto-id)'}" =>`, items[i].name || items[i].title || items[i]);
    }
    return;
  }

  // --- CÁCH 1: DÙNG ADMIN SDK (NẾU CÓ KEY) ---
  if (engine.type === 'admin') {
    const BATCH_LIMIT = 400;
    let batch = engine.db.batch();
    let batchCount = 0;
    let totalCommitted = 0;

    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const docId = resolveDocId(item, collectionName);
      const colRef = engine.db.collection(collectionName);
      const docRef = docId ? colRef.doc(docId) : colRef.doc();

      batch.set(docRef, item, { merge: true });
      batchCount++;

      if (batchCount >= BATCH_LIMIT) {
        await batch.commit();
        totalCommitted += batchCount;
        console.log(`   \x1b[32m[✓]\x1b[0m Đã tải lên ${totalCommitted}/${items.length} bản ghi...`);
        batch = engine.db.batch();
        batchCount = 0;
      }
    }
    if (batchCount > 0) {
      await batch.commit();
      totalCommitted += batchCount;
    }
    console.log(`\x1b[32m   🎉 Thành công: Đã import ${totalCommitted} documents vào "${collectionName}".\x1b[0m`);
    return;
  }

  // --- CÁCH 2: DÙNG REST API (TRỰC TIẾP KHÔNG CẦN KEY FILE) ---
  const CONCURRENCY = 8; // Chạy song song 8 request cùng lúc
  let successCount = 0;
  let failCount = 0;

  for (let i = 0; i < items.length; i += CONCURRENCY) {
    const chunk = items.slice(i, i + CONCURRENCY);
    await Promise.all(
      chunk.map(async (item) => {
        const docId = resolveDocId(item, collectionName);
        let url;
        let method;

        if (docId) {
          url = `https://firestore.googleapis.com/v1/projects/${DEFAULT_CONFIG.projectId}/databases/(default)/documents/${collectionName}/${encodeURIComponent(docId)}?key=${DEFAULT_CONFIG.apiKey}`;
          method = 'PATCH';
        } else {
          url = `https://firestore.googleapis.com/v1/projects/${DEFAULT_CONFIG.projectId}/databases/(default)/documents/${collectionName}?key=${DEFAULT_CONFIG.apiKey}`;
          method = 'POST';
        }

        try {
          const res = await fetch(url, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ fields: toFirestoreFields(item) }),
          });

          if (res.ok) {
            successCount++;
          } else {
            const err = await res.json().catch(() => ({}));
            failCount++;
            console.error(`   \x1b[31m[✗] Lỗi ghi doc "${docId}":\x1b[0m`, err.error?.message || res.statusText);
          }
        } catch (e) {
          failCount++;
          console.error(`   \x1b[31m[✗] Lỗi mạng khi ghi doc "${docId}":\x1b[0m`, e.message);
        }
      })
    );

    const progress = Math.min(i + CONCURRENCY, items.length);
    process.stdout.write(`   \x1b[36m⏳ Tiến độ: ${progress}/${items.length} bản ghi...\x1b[0m\r`);
  }

  console.log(`\x1b[32m\n   🎉 Hoàn tất: Đã tải lên ${successCount}/${items.length} documents vào "${collectionName}".\x1b[0m`);
  if (failCount > 0) {
    console.log(`   \x1b[33m[!] Có ${failCount} bản ghi gặp lỗi.\x1b[0m`);
  }
}

// 8. Đọc và phân tích file JSON
async function processJsonFile(engine, filePath, specifiedCollection, clear, dryRun) {
  const fullPath = path.resolve(filePath);
  if (!fs.existsSync(fullPath)) {
    console.error(`\x1b[31m[LỖI] Không tìm thấy file: ${filePath}\x1b[0m`);
    return;
  }

  console.log(`\n======================================================`);
  console.log(`📂 Đọc file: \x1b[35m${path.basename(fullPath)}\x1b[0m`);
  console.log(`   Đường dẫn: ${fullPath}`);

  let parsedData;
  try {
    const rawContent = fs.readFileSync(fullPath, 'utf8');
    parsedData = JSON.parse(rawContent);
  } catch (e) {
    console.error(`\x1b[31m[LỖI] File không đúng định dạng JSON: ${e.message}\x1b[0m`);
    return;
  }

  // Trường hợp 1: Mảng [ { ... }, { ... } ]
  if (Array.isArray(parsedData)) {
    const colName = detectCollectionName(fullPath, specifiedCollection);
    if (clear && !dryRun) await clearCollection(engine, colName);
    await uploadCollectionData(engine, colName, parsedData, dryRun);
    return;
  }

  // Trường hợp 2: Object { ... }
  if (typeof parsedData === 'object' && parsedData !== null) {
    const keys = Object.keys(parsedData);
    const hasArrayValues = keys.length > 0 && keys.every(k => Array.isArray(parsedData[k]));

    if (hasArrayValues && !specifiedCollection) {
      // Đa collection: { "movies": [...], "genres": [...] }
      console.log(`\x1b[34m[ℹ] Phát hiện file đa collection: (${keys.join(', ')})\x1b[0m`);
      for (const colName of keys) {
        if (clear && !dryRun) await clearCollection(engine, colName);
        await uploadCollectionData(engine, colName, parsedData[colName], dryRun);
      }
    } else {
      // Key-value map: { "id1": { ... } }
      const colName = detectCollectionName(fullPath, specifiedCollection);
      const items = [];
      for (const [key, val] of Object.entries(parsedData)) {
        if (typeof val === 'object' && val !== null) {
          if (!val.id && !val.slug) val._key = key;
          items.push(val);
        }
      }
      if (clear && !dryRun) await clearCollection(engine, colName);
      await uploadCollectionData(engine, colName, items, dryRun);
    }
  }
}

// 9. Khởi động kết nối
function initEngine() {
  const adminKey = findServiceAccountKey();
  if (adminKey) {
    try {
      const admin = require('firebase-admin');
      const serviceAccount = require(adminKey);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log(`\x1b[32m[✓]\x1b[0m Đã nạp Admin SDK từ: \x1b[33m${path.basename(adminKey)}\x1b[0m`);
      return { type: 'admin', db: admin.firestore() };
    } catch (_) {}
  }

  // Mặc định: Dùng cấu hình trực tiếp từ dự án
  console.log(`\x1b[32m[✓]\x1b[0m Kết nối trực tiếp Firestore qua API Key dự án: \x1b[33m${DEFAULT_CONFIG.projectId}\x1b[0m (Không cần file key)`);
  return { type: 'client' };
}

// 10. Hàm chính
async function main() {
  const options = parseArguments();

  if (options.help) {
    printHelp();
    return;
  }

  let engine = null;
  if (!options.dryRun) {
    engine = initEngine();
  } else {
    console.log('\x1b[33m[CHẾ ĐỘ THỬ NGHIỆM - DRY RUN]\x1b[0m Không kết nối Firebase, chỉ kiểm tra cấu trúc dữ liệu.');
    engine = { type: 'dryRun' };
  }

  try {
    if (options.all || options.dir) {
      const targetDir = options.dir ? path.resolve(options.dir) : path.resolve(__dirname, 'data');
      if (!fs.existsSync(targetDir)) {
        console.error(`\x1b[31m[LỖI] Không tìm thấy thư mục: ${targetDir}\x1b[0m`);
        process.exit(1);
      }

      const files = fs.readdirSync(targetDir)
        .filter(f => f.endsWith('.json'))
        .filter(f => !f.toLowerCase().includes('serviceaccount'));

      if (files.length === 0) {
        console.log(`\x1b[33m[!] Không tìm thấy file .json nào trong thư mục: ${targetDir}\x1b[0m`);
        return;
      }

      console.log(`\x1b[1m\x1b[36m📁 Tìm thấy ${files.length} file JSON cần import trong thư mục: ${targetDir}\x1b[0m`);
      for (const file of files) {
        const fullFilePath = path.join(targetDir, file);
        await processJsonFile(engine, fullFilePath, null, options.clear, options.dryRun);
      }
      console.log('\n\x1b[32m======================================================');
      console.log('✨ TẤT CẢ FILE ĐÃ ĐƯỢC IMPORT THÀNH CÔNG! ✨');
      console.log('======================================================\x1b[0m\n');
      return;
    }

    if (options.file) {
      await processJsonFile(engine, options.file, options.collection, options.clear, options.dryRun);
      console.log('\n\x1b[32m✨ HOÀN THÀNH IMPORT! ✨\x1b[0m\n');
      return;
    }

    console.log('\x1b[33m[!] Bạn chưa chỉ định file hoặc thư mục cần import.\x1b[0m');
    printHelp();

  } catch (err) {
    console.error('\x1b[31m[LỖI NGOẠI LỆ]:\x1b[0m', err);
  }
}

main();
