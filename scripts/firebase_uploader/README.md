# 🎬 Firebase Data Uploader cho Cinema App

Công cụ bằng Node.js dùng để import / seed dữ liệu từ các file JSON lên Firebase Cloud Firestore cho dự án Cinema App.

---

## ✨ Điểm nổi bật
- **⚡ KHÔNG CẦN TẢI FILE KEY**: Tự động sử dụng Web API Key đã có sẵn trong dự án ([`firebase_options.dart`](../../cinema_app/lib/firebase_options.dart)). Bạn có thể chạy ngay lập tức mà không cần bất kỳ bước cài đặt tài khoản phức tạp nào.
- **📁 Hỗ trợ linh hoạt**: Import từng file lẻ, nhiều file cùng lúc (`--all`), hoặc 1 file JSON chứa nhiều collection.
- **🎯 Chuẩn dữ liệu Cinema App**: Tự động đặt Document ID theo `slug`, `movieId_episodeNumber` khớp hoàn toàn với ứng dụng Flutter.

---

## 🚀 Cách sử dụng ngay (Chạy được luôn)

Mở terminal tại thư mục này:

```bash
cd C:\Users\admin\Documents\CODE\Mobile\mobile\scripts\firebase_uploader
```

### 1. Import 1 file JSON đơn lẻ
Script tự động lấy tên file làm tên collection (ví dụ `movies.json` -> collection `movies`):

```bash
# Import file mẫu phim
node import.js data/movies.sample.json

# Hoặc chỉ định rõ tên collection cần nạp vào
node import.js --file=data/movies.sample.json --collection=movies
```

### 2. Import TẤT CẢ các file JSON trong thư mục (nhiều file 1 lúc)
Đặt tất cả file JSON (`movies.json`, `genres.json`, `countries.json`,...) vào thư mục `data/`:

```bash
# Tải toàn bộ file trong thư mục data/ lên Firestore
node import.js --all

# Hoặc chỉ định một thư mục bất kỳ khác
node import.js --dir=./path/to/my-data
```

### 3. Import 1 file JSON chứa nhiều Collection
Nếu file JSON có định dạng gom nhiều bảng:
```json
{
  "genres": [ { "id": 1, "name": "Hành Động", "slug": "hanh-dong" } ],
  "movies": [ { "id": 1, "name": "Lật Mặt 7", "slug": "lat-mat-7" } ]
}
```
Chạy:
```bash
node import.js du_lieu_tong_hop.json
```

---

## 🛠️ Các cờ tùy chọn hữu ích

- **`--dry-run`**: Kiểm tra file JSON và xem trước Document ID mà **không ghi** vào Firestore:
  ```bash
  node import.js data/movies.sample.json --dry-run
  ```
- **`--clear`**: Xóa dữ liệu cũ trong collection trước khi import:
  ```bash
  node import.js data/movies.sample.json --clear
  ```

---

## 🔒 Khi nào cần file `serviceAccountKey.json`?

- **Hiện tại**: Database Firestore của bạn đang ở chế độ cho phép đọc/ghi qua API Key công khai của app, nên **bạn không cần tải file key**.
- **Trong tương lai**: Nếu sau này bạn thắt chặt Security Rules (ví dụ `allow write: if false;` chỉ cho phép Admin ghi dữ liệu), lúc đó bạn chỉ cần tải `serviceAccountKey.json` từ Firebase Console thả vào thư mục này, script sẽ tự động nhận diện và chuyển sang chế độ Admin SDK.
