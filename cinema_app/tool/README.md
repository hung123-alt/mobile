# Tool seed Firestore cho app mobile

Script lấy phim từ **VSMOV API** rồi đổ thẳng vào **Firestore** (mobile đọc
Firestore, không đọc MySQL — nên script này tách riêng khỏi `server/src/seed.ts`).

Viết bằng **Dart thuần**, chạy bằng `dart run` — **không cần Node.js**, không cần
Flutter SDK.

## Chạy

```bash
cd cinema_app/tool
dart pub get
dart run seed_firestore.dart
```

Lấy nhiều phim hơn (mặc định 5 trang):

```bash
SEED_PAGES=8 dart run seed_firestore.dart
```

## Xác thực — chọn 1 trong 2

### Cách 1 — Đăng nhập bằng tài khoản admin (khuyến nghị, KHÔNG cần tải key)

Firestore rules của app cho phép admin đã đăng nhập ghi `movies` / `episodes`:

```
match /movies/{slug} { allow write: if isSignedIn() && isAdmin(); }
```

nên script chỉ cần đăng nhập Firebase Auth bằng tài khoản admin rồi dùng
`idToken` làm Bearer token cho Firestore REST API.

**PowerShell:**

```powershell
$env:SEED_ADMIN_EMAIL = "admin@phimplay24.com"
$env:SEED_ADMIN_PASSWORD = "mat-khau-admin"
dart run seed_firestore.dart
```

**Bash / macOS / Linux:**

```bash
export SEED_ADMIN_EMAIL="admin@phimplay24.com"
export SEED_ADMIN_PASSWORD="mat-khau-admin"
dart run seed_firestore.dart
```

API key đã điền sẵn trong script (API key là public, nằm trong app client).
Muốn đổi thì set `SEED_API_KEY` / `SEED_PROJECT_ID`.

> Lưu ý: tài khoản admin phải có doc trong collection `admins` với docId = uid
> của tài khoản đó, nếu không rules sẽ từ chối ghi.

### Cách 2 — Service account key

1. Firebase Console → Project settings → **Service accounts** → Generate new private key.
2. Đặt file JSON vào `cinema_app/tool/serviceAccountKey.json`.

File này đã được `.gitignore` loại trừ, **không được commit lên git**.

Hoặc dùng biến môi trường:

```bash
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json dart run seed_firestore.dart
```

Cách này bypass rules (không cần tài khoản admin).

## Chính sách seed (IDEMPOTENT — giống `server/src/seed.ts`)

- **Không xóa** dữ liệu nào. Phim cũ + Server 2 thêm tay giữ nguyên.
- Chỉ **thêm phim mới** (slug chưa có trong collection `movies`).
- Phim đã có → **skip toàn bộ**, không đè Server 1 lẫn Server 2.
- Muốn seed lại 1 phim → xóa doc phim đó trong Firestore rồi chạy lại.

## Dữ liệu ghi vào

| Collection | Doc ID | Ghi chú |
|---|---|---|
| `movies` | `{id}` | Đủ 2 bộ field `camelCase` + `snake_case` như `AdminMovieEditPage` đang lưu |
| `episodes` | `{movieId}_{tap}_{server}` | Có server trong docId → multi-server cùng 1 tập không đè nhau |
| `genres` | `{slug}` | Tự tăng `id` số |
| `countries` | `{slug}` | Tự tăng `id` số |
| `movie_genres` | `{movieId}_{genreId}` | |
| `movie_countries` | `{movieId}_{countryId}` | |

Link tập phim lấy theo thứ tự ưu tiên `link_embed` → `link_m3u8` (giống seed MySQL).
Link được chuẩn hoá khi phát bởi `lib/core/utils/video_source.dart`, nên VSMOV /
YouTube / `.mp4` / `.m3u8` đều chạy được.
