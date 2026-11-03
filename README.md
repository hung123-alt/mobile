<!-- ═══════════════════════════════════════════════════════════
     PHIMHAY24H MOBILE — Cinema Neon README
     Flutter + Firebase + Gemini Voice · Phenikaa University · Nhóm 4
═══════════════════════════════════════════════════════════ -->
<div align="center">

![Header](https://capsule-render.vercel.app/api?type=waving&color=0:0b0b0f,50:1a1005,100:2b1400&height=240&section=header&text=PHIMHAY24H&fontSize=80&fontColor=f26522&animation=fadeIn&fontAlignY=35&desc=Ứng%20dụng%20xem%20phim%20Flutter%20—%20Firebase%20·%20Gemini%20Voice%20·%20Nhóm%204%20Phenikaa&descSize=17&descAlignY=63&descColor=ffcf9e)

<p align="center">
  <img src="https://readme-typing-svg.herokuapp.com?font=JetBrains+Mono&size=18&pause=1200&color=F26522&center=true&vCenter=true&width=820&height=50&lines=📱+Flutter+Mobile+%2B+Web+PWA+trên+Render;🔥+Firebase+Auth+%2B+Firestore+Realtime;🎙️+Trợ+lý+giọng+nói+Lina+%2F+Seven+(Gemini);🎬+Xem+phim+%2B+Xem+tiếp+%2B+Skip+Intro;🛡️+SecureStorage+·+XSS+Guard+·+Rate+Limit" alt="Typing SVG" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-đang%20phát%20triển-f26522?style=flat-square&labelColor=1a1005" alt="status"/>
  <img src="https://img.shields.io/badge/version-1.0.0-ffcf9e?style=flat-square&labelColor=1a1005" alt="version"/>
  <img src="https://img.shields.io/badge/flutter-3.x-02569B?style=flat-square&labelColor=1a1005&logo=flutter&logoColor=white" alt="flutter"/>
  <img src="https://img.shields.io/badge/tests-157%20passed-2ecc71?style=flat-square&labelColor=1a1005" alt="tests"/>
  <img src="https://img.shields.io/badge/firebase-auth%20%2B%20firestore-FFCA28?style=flat-square&labelColor=1a1005&logo=firebase&logoColor=white" alt="firebase"/>
  <img src="https://img.shields.io/badge/PRs-welcome-8A2BE2?style=flat-square&labelColor=1a1005" alt="PRs"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Gemini-Voice%20Assistant-8E75B2?style=for-the-badge&logo=google&logoColor=white" alt="Gemini"/>
  <img src="https://img.shields.io/badge/Render-PWA%20Live-46E3B7?style=for-the-badge&logo=render&logoColor=white" alt="Render"/>
  <img src="https://img.shields.io/badge/GitHub%20Actions-APK%20Build-2088FF?style=for-the-badge&logo=githubactions&logoColor=white" alt="Actions"/>
</p>

<p align="center">
  <a href="https://phimhay24h.onrender.com"><img src="https://img.shields.io/badge/🌐%20Bản%20Web%20PWA%20Live-phimhay24h.onrender.com-f26522?style=for-the-badge" alt="Web PWA"/></a>
  &nbsp;
  <a href="https://cloud.vmoscloud.com/screen/share/#token=164E-C79D-35E3-4E51-936E-3DEF-99E3-91B9"><img src="https://img.shields.io/badge/📱%20App%20Demo%20Cloud-VMOS%20Live-00C853?style=for-the-badge&logo=android&logoColor=white" alt="App Demo Cloud"/></a>
  &nbsp;
  <a href="https://github.com/hung123-alt/mobile/actions"><img src="https://img.shields.io/badge/📦%20Tải%20APK-GitHub%20Actions-2088FF?style=for-the-badge&logo=android&logoColor=white" alt="APK"/></a>
  &nbsp;
  <a href="#-demo-video--app-dùng-thử"><img src="https://img.shields.io/badge/🎬%20Video%20Demo-YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="Video Demo"/></a>
  &nbsp;
  <a href="#️-cài-đặt--chạy-nhanh"><img src="https://img.shields.io/badge/📖%20Docs-Hướng%20dẫn%20chạy-ffcf9e?style=for-the-badge" alt="Docs"/></a>
</p>

> 📱 **Dùng thử app ngay không cần cài:** mở link **App Demo Cloud (VMOS)** ở trên là xài trực tiếp trên trình duyệt — kèm bản **Web PWA**, file **APK** và **Video Demo YouTube** trong mục [📸 Demo sản phẩm](#-demo-video--app-dùng-thử).

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:f26522,100:2b1400&height=3&width=1000)

</div>

## 📋 Mục lục

<div align="center">

| | | | |
|:---:|:---:|:---:|:---:|
| [✨ Giới thiệu](#-giới-thiệu) | [🚀 Tính năng](#-tính-năng-nổi-bật) | [🔐 Demo tài khoản](#-demo-tài-khoản) | [🛠️ Module](#️-chức-năng-chính-theo-module) |
| [🧰 Công nghệ](#️-công-nghệ-sử-dụng) | [📁 Cấu trúc](#-cấu-trúc-dự-án-do-nhóm-tự-vẽ) | [🗄️ Dữ liệu](#️-mô-hình-dữ-liệu-firestore) | [🛡️ Bảo mật](#️-kiến-trúc-bảo-mật-do-nhóm-tự-vẽ) |
| [📊 Sơ đồ](#-sơ-đồ-hệ-thống-15-ảnh--2-sơ-đồ-tự-vẽ) | [🧪 Kiểm thử](#-kiểm-thử--kiểm-định-8a--8e) | [⚙️ Cài đặt](#️-cài-đặt--chạy-nhanh) | [👥 Nhóm](#-nhóm-phát-triển) |

</div>

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:2b1400,100:f26522&height=3&width=1000)

</div>

## ✨ Giới thiệu

**PhimHay24h Mobile** là ứng dụng xem phim trực tuyến đa nền tảng viết bằng **Flutter**, chạy trên **Android (APK)**, **Web PWA (Render)** và mọi nền tảng Flutter hỗ trợ.

Ba điểm khiến bản mobile khác biệt:

- **🔥 Firebase-native:** `firebase_auth` thay cho bảng `users` + JWT của NestJS, `cloud_firestore` thay cho MySQL — mọi phân quyền dồn về **`cinema_app/firestore.rules`** (hàm `isSignedIn()`, `isAdmin()`, `ownsProfile()`, `hasNoPlaintextPassword()`).
- **🎙️ Trợ lý giọng nói Lina / Seven:** `speech_to_text` + `flutter_tts` + `gemini_client` — bấm orb, nói *"tìm phim hành động"*, trợ lý tự mở trang tìm kiếm / chi tiết phim.
- **📦 Một codebase — hai đầu ra:** cùng một `cinema_app/` build ra **Web PWA qua Docker + Nginx trên Render** (`https://phimhay24h.onrender.com`) và **APK Android qua GitHub Actions** (`build-apk.yml` → `app-release.apk` ~59 MB, test được trên Appetize.io).

> 💡 Repo này là **nhánh `main` — bản Mobile**: `cinema_app/` (Flutter) + `server/` (NestJS tham khảo) + `client/` (React tham khảo) + `.github/workflows/build-apk.yml` (CI build APK) + `Dockerfile`/`render.yaml` (deploy Web).

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:f26522,100:2b1400&height=3&width=1000)

</div>

## 🚀 Tính năng nổi bật

```
🎬 Xem phim              →  WebView nhúng, chọn tập, phát video, tự chuyển tập
⏯️  Xem tiếp              →  Lưu tiến độ theo tập (watch_history), gợi ý tiếp tục
🔎 Tìm kiếm & Lọc         →  Debounce 400ms, lọc Thể loại + Quốc gia + Năm + Loại phim
🎲 Random phim            →  Random nhanh & Random nâng cao (trang Random)
💬 Bình luận & Đánh giá   →  Reply lồng nhau, chấm sao 1–10, chặn XSS từ client
❤️  Cá nhân hóa           →  Yêu thích · Xem sau · Lịch sử xem riêng từng user
🎙️  Trợ lý Lina/Seven     →  Ra lệnh giọng nói, đọc kết quả bằng TTS, mở phim bằng lời nói
🔐 Firebase Auth          →  Đăng ký / Đăng nhập / Quên & Đặt lại mật khẩu (deep link)
🌗 Dark / Light           →  ThemeProvider + lưu SharedPreferences, đổi tức thì
🛡️  Bảo mật nhiều lớp     →  SecureStorage · InputSanitizer · RateLimiter · Rules
📊 Admin Dashboard        →  Quản lý phim / tập / thể loại / user / bình luận / báo lỗi
📩 Chia sẻ & Deep link    →  share_plus + app_links, mở link là vào đúng phim
```

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:2b1400,100:f26522&height=3&width=1000)

</div>

## 🔐 Demo tài khoản

| Vai trò | Email | Mật khẩu | Quyền hạn |
|---------|-------|----------|-----------|
| 👑 **Admin** | `admin@phimhay24.com` | `admin123` | Toàn quyền — duyệt CRUD phim/tập/danh mục, khóa user, xử lý báo lỗi, xem dashboard |
| 👤 **User** | `user@phimhay24.com` | `admin123` | Xem phim, bình luận, đánh giá 1–10, yêu thích, xem sau, lịch sử, báo lỗi video |

> ⚠️ Tài khoản demo nằm trên project Firebase **`cinema-app-b760e`**. Nếu đăng nhập báo lỗi `operation-not-allowed`, hãy bật **Email/Password provider** trong Firebase Console → Authentication → Sign-in method.

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:f26522,100:2b1400&height=3&width=1000)

</div>

## 🛠️ Chức năng chính theo module

| Module (mobile) | Màn hình / Chức năng |
|--------|-----------|
| **Auth** | Đăng ký / Đăng nhập / Quên & Đặt lại mật khẩu (`forgot_password_page`, `reset_password_page` + `DeepLinkService`), lưu phiên bằng `AuthProvider` |
| **Home** | `home_page` + `hero_banner_carousel` + `trending_carousel` + `movie_row_section` — banner, trending, danh sách theo thể loại |
| **Search** | `search_page` + `search_input` (debounce) — tìm theo từ khóa, mở chi tiết |
| **Category** | `category_page` — lọc kết hợp thể loại / quốc gia / năm / loại phim |
| **Movie Detail** | `movie_detail_page` + `episode_grid` + `comment_section` + `rating_modal` — xem info, chọn tập, bình luận, chấm sao |
| **Player** | `player_page` + `embed_video_player` (mobile/web/stub) — phát video, chuyển tập, báo lỗi (`error_report_modal`) |
| **Comments** | Bình luận lồng nhau, `InputSanitizer.cleanText()` cắt HTML trước khi gửi, server/Firestore rules chặn tiếp |
| **Ratings** | Chấm sao 1–10 (`rating_stars`), upsert một user một điểm/phim |
| **Favorites / Watchlist** | `favorite_page`, `watchlist_provider`/`watchlist_repository` — toggle tim, đồng bộ Firestore |
| **Watch History** | `watch_history_page` + `watch_history_provider` — tự lưu tiến độ, hỗ trợ "Xem tiếp" |
| **Random** | `random_page` — random nhanh & nâng cao theo bộ lọc |
| **Voice Assistant** | `assistant_orb` + `assistant_panel` + `assistant_brain` + `gemini_client` — STT → Gemini → TTS + điều hướng |
| **Admin** | `admin_dashboard_page` + 5 tab (`admin_movies_tab`, `admin_users_tab`, `admin_comments_tab`, `admin_genres_tab`, `admin_notifications_tab`) + `admin_movie_edit_page` |
| **Profile** | `profile_page` + `account_info_page` — đổi theme, xem thông tin, đăng xuất (xóa sạch token) |

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:2b1400,100:f26522&height=3&width=1000)

</div>

## 🧰 Công nghệ sử dụng

<div align="center">

[![Tech Stack](https://skillicons.dev/icons?i=flutter,dart,firebase,nodejs,github,githubactions,docker,nginx,postman&theme=dark&perline=9)](https://skillicons.dev)

</div>

<br/>

| Layer | Công nghệ | Ghi chú |
|-------|-----------|---------|
| **Mobile UI** | Flutter 3.x + Dart (`sdk >=3.12.0`) | Material 3, `ListenableBuilder`, `NavigationShell` (Bottom Nav) |
| **State** | Provider thủ công (`AuthProvider`, `ThemeProvider`, `WatchlistProvider`, `WatchHistoryProvider`, `ToastProvider`) | Singleton + `ListenableBuilder`, không dùng Riverpod/Bloc để giữ code gọn cho đồ án |
| **Backend chính** | Firebase Auth + Cloud Firestore | Auth thay JWT NestJS; Firestore thay MySQL; rules ở `cinema_app/firestore.rules` |
| **Backend tham khảo** | NestJS 11 + TypeORM + MySQL (thư mục `server/`) | Giữ lại để đối chiếu kiến trúc module hóa với bản web |
| **Trợ lý giọng nói** | `speech_to_text` + `flutter_tts` + `gemini_client` (Google Gemini) | Persona Lina/Seven, `assistant_brain` điều hướng bằng lời nói |
| **Video** | `webview_flutter` + `embed_video_player` (mobile/web/stub) + `video_source.dart` | Phân loại HLS / Direct / Iframe, lọc scheme `javascript:`/`file://` |
| **Lưu trữ bí mật** | `flutter_secure_storage` (Keychain iOS / EncryptedSharedPreferences Android) | Token **không** nằm ở SharedPreferences XML plaintext |
| **Lưu trữ thường** | `shared_preferences` | Chỉ lưu `theme_mode`, cache UI không nhạy cảm |
| **Chia sẻ / Link** | `share_plus` + `app_links` + `DeepLinkService` | Share phim, deep link quên mật khẩu |
| **Deploy Web** | Docker multi-stage (Flutter stable → Nginx Alpine) + `render.yaml` | Live tại `https://phimhay24h.onrender.com` |
| **Build APK** | GitHub Actions `.github/workflows/build-apk.yml` | `app-release.apk` ~59 MB, test trên Appetize.io |
| **Kiểm thử** | `flutter_test` (13 file, 157 ca — xem mục 🧪) | Bao phủ yêu cầu 8a–8e |

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:f26522,100:2b1400&height=3&width=1000)

</div>

## 📁 Cấu trúc dự án (do nhóm tự vẽ)

> 🌳 Cây thư mục dưới do nhóm tự vẽ từ mã nguồn thật của nhánh `main` — **mỗi file có mũi tên → ghi rõ chức năng ngắn gọn**.

<details open>
<summary><b>📂 Bấm để thu gọn / mở rộng cây thư mục Mobile (cinema_app/) — chi tiết từng file</b></summary>

```text
mobile/  (repo root — nhánh main)
├── .github/workflows/build-apk.yml     → CI: Flutter stable → build app-release.apk (~59MB)
├── cinema_app/Dockerfile               → Multi-stage: flutter build web → nginx:alpine serve
├── render.yaml                         → Deploy Web PWA (dockerContext: .)
├── .dockerignore                       → Loại build/, .dart_tool/ khỏi context
├── Capture.PNG                         → Ảnh chụp màn hình demo cũ
├── README.md                           → Chính file này
│
├── docs/
│   └── images/                         → 17 ảnh: 15 sơ đồ nhóm + 2 ảnh web mới (home, admin)
│       ├── ClassDiagrams.drawio.png    → Sơ đồ lớp: 12 Entity + RefreshToken
│       ├── KTTongThe.drawio.png        → Kiến trúc tổng thể hệ thống
│       ├── SE_QLLSXEM.drawio.png       → Sequence: quản lý lịch sử xem
│       ├── SE_QuanLyPhimYeuThich.png   → Sequence: quản lý phim yêu thích
│       ├── Se_XemChiTietPhim.png       → Sequence: xem chi tiết phim
│       ├── ACLogin.png                 → Activity: đăng nhập
│       ├── AcTimKiemLocPhim.png        → Activity: tìm kiếm & lọc phim
│       ├── AC_BandAcc.png              → Activity: khóa tài khoản (Admin)
│       ├── AC_ChonTapVaPhatVideo.png   → Activity: chọn tập & phát video
│       ├── Movies_Mobile-Login.png     → Mobile flow: đăng nhập
│       ├── Movies_Mobile-Dang ky.png   → Mobile flow: đăng ký
│       ├── Movies_Mobile-search.png    → Mobile flow: tìm kiếm
│       ├── Movies_Mobile-watch.png     → Mobile flow: xem phim
│       ├── Movies_Mobile-comment.png   → Mobile flow: bình luận
│       ├── Movies_Mobile-like_dislike.png → Mobile flow: like / dislike
│       ├── web-home.png                → Ảnh web mới: trang chủ (giao diện User)
│       └── web-admin.png               → Ảnh web mới: trang Admin (giao diện yêu cầu)
│
├── scripts/                            → Script phụ trợ repo
│
└── cinema_app/                         → 📱 APP FLUTTER (thư mục quan trọng nhất)
    ├── pubspec.yaml                    → Khai báo phụ thuộc: firebase_auth, cloud_firestore,
    │                                     speech_to_text, flutter_tts, webview_flutter,
    │                                     flutter_secure_storage, share_plus, app_links
    ├── firebase.json                   → Cấu hình Firebase project
    ├── firestore.rules                 → ⭐ Luật phân quyền: isSignedIn/isAdmin/ownsProfile/...
    ├── lib/
    │   ├── main.dart                   → Entry: init Firebase → Theme → Auth → DeepLink → runApp
    │   ├── firebase_options.dart        → Cấu hình Firebase theo platform (flutterfire)
    │   │
    │   ├── assistant/                  → 🎙️ Trợ lý giọng nói Lina/Seven
    │   │   ├── assistant_brain.dart     → Bộ não: hiểu lệnh nói → chọn tool điều hướng
    │   │   ├── assistant_manager.dart   → Điều phối orb + panel + brain
    │   │   ├── assistant_orb.dart       → Nút orb nổi: bấm để nói
    │   │   ├── assistant_panel.dart     → Panel hội thoại với trợ lý
    │   │   ├── assistant_persona.dart   → Tính cách & lời thoại Lina/Seven
    │   │   ├── assistant_settings.dart  → Bật/tắt giọng nói, chọn persona
    │   │   ├── assistant_tools.dart     → Tool: mở tìm kiếm / mở phim / ...
    │   │   ├── gemini_client.dart       → Gọi API Google Gemini
    │   │   ├── text_normalizer.dart     → Chuẩn hóa tiếng Việt cho STT
    │   │   └── voice_assistant_service.dart → Nền STT + TTS: nghe → nói
    │   │
    │   ├── core/
    │   │   ├── constants/
    │   │   │   ├── app_colors.dart      → Bảng màu cinema neon dùng toàn app
    │   │   │   └── app_constants.dart   → Hằng số: giới hạn comment, debounce, key...
    │   │   ├── extensions/
    │   │   │   └── hex_color.dart       → Mở rộng: parse mã hex thành Color
    │   │   ├── firebase/
    │   │   │   ├── auth_service.dart    → Đăng ký/đăng nhập/reset qua Firebase Auth
    │   │   │   ├── firebase_service.dart → Khởi tạo & tiện ích Firebase chung
    │   │   │   ├── collection_names.dart → Tên collection Firestore tập trung
    │   │   │   ├── deep_link_service.dart → Lắng nghe deep link quên mật khẩu
    │   │   │   └── user_auth_map_service.dart → Nối Firebase UID ↔ profileId
    │   │   ├── security/               → 🛡️ Lớp bảo mật client
    │   │   │   ├── input_sanitizer.dart → Strip thẻ HTML, cắt 2000 ký tự, chặn XSS
    │   │   │   ├── rate_limiter.dart    → Chặn bấm spam 1200ms + debounce search 400ms
    │   │   │   └── secure_token_storage.dart → Token vào Keychain/EncryptedPrefs, logout xóa sạch
    │   │   ├── theme/
    │   │   │   └── app_theme.dart       → Theme Light/Dark Material 3
    │   │   └── utils/
    │   │       ├── validators.dart      → Validate form: required, email, password, rating 1–10
    │   │       ├── generic_utils.dart   → Tìm kiếm, lọc, sắp xếp, nhóm, chia trang list
    │   │       └── video_source.dart    → Parse YouTube ID, phân loại HLS/Direct/Iframe, chặn URL độc
    │   │
    │   ├── models/                     → Model parse mềm (chịu int/String/bool lộn xộn)
    │   │   ├── movie_model.dart         → Model phim + label hiển thị
    │   │   ├── episode_model.dart       → Model tập phim + skip-intro
    │   │   ├── comment_model.dart       → Model bình luận + reply lồng nhau
    │   │   ├── rating_model.dart        → Model điểm 1–10
    │   │   ├── genre_model.dart         → Model thể loại
    │   │   ├── country_model.dart       → Model quốc gia
    │   │   ├── user_model.dart          → Model hồ sơ user
    │   │   ├── notification_model.dart  → Model thông báo
    │   │   ├── watchlist_item_model.dart → Model mục xem sau / yêu thích
    │   │   ├── movie_detail_result.dart → Gộp phim + tập + bình luận + rating
    │   │   ├── page_result.dart         → Phân trang: list + total + page
    │   │   ├── api_response.dart        → Bọc response API generic
    │   │   ├── base_entity.dart         → Lớp cha: id + thời gian
    │   │   └── id_entity.dart           → Entity chỉ có id số
    │   ├── repositories/               → Repository Pattern: bắt ApiException ở biên
    │   │   ├── auth_repository.dart     → Đăng nhập/đăng ký, trả default khi lỗi
    │   │   ├── movie_repository.dart    → Lấy/lọc/random phim, lỗi → list rỗng
    │   │   ├── comment_repository.dart  → Gửi/xóa bình luận, lỗi → giữ UI cũ
    │   │   └── watchlist_repository.dart → Toggle yêu thích/xem sau, lỗi → rollback
    │   ├── services/                   → Gọi API / Firestore trực tiếp
    │   │   ├── api_service.dart         → Client HTTP + gắn token + timeout
    │   │   ├── auth_service.dart        → Service auth phía data
    │   │   ├── movie_service.dart       → Service phim phía data
    │   │   ├── firestore_movie_service.dart → Đọc/ghi phim trên Firestore
    │   │   ├── comment_service.dart     → Đọc/ghi bình luận Firestore
    │   │   ├── rating_service.dart      → Ghi điểm 1–10 lên Firestore
    │   │   ├── watchlist_service.dart   → Đọc/ghi yêu thích & xem sau
    │   │   ├── history_service.dart     → Lưu tiến độ xem từng tập
    │   │   └── notification_service.dart → Đọc thông báo
    │   ├── providers/                  → State: singleton + ListenableBuilder
    │   │   ├── auth_provider.dart       → Phiên đăng nhập + checkAuthStatus
    │   │   ├── theme_provider.dart      → Dark/Light + lưu SharedPreferences
    │   │   ├── toast_provider.dart      → Toast báo thành công/thất bại
    │   │   ├── watchlist_provider.dart  → State yêu thích / xem sau
    │   │   └── watch_history_provider.dart → State lịch sử + gợi ý xem tiếp
    │   ├── routes/
    │   │   ├── app_routes.dart          → Tên route tập trung
    │   │   └── app_router.dart          → Bản đồ route → màn hình + guard
    │   ├── pages/                      → 17 màn hình
    │   │   ├── home_page.dart           → Trang chủ: banner + trending + list
    │   │   ├── search_page.dart         → Tìm theo từ khóa + mở chi tiết
    │   │   ├── category_page.dart       → Lọc thể loại/quốc gia/năm/loại phim
    │   │   ├── favorite_page.dart       → List phim yêu thích
    │   │   ├── profile_page.dart        → Tài khoản + đổi theme + đăng xuất
    │   │   ├── movie_detail_page.dart   → Info phim + tập + bình luận + sao
    │   │   ├── player_page.dart         → Phát video + chuyển tập + báo lỗi
    │   │   ├── random_page.dart         → Random nhanh & nâng cao
    │   │   ├── watch_history_page.dart  → Lịch sử + nút xem tiếp
    │   │   ├── login_page.dart          → Đăng nhập Firebase
    │   │   ├── register_page.dart       → Đăng ký tài khoản
    │   │   ├── forgot_password_page.dart → Gửi mail quên mật khẩu
    │   │   ├── reset_password_page.dart → Đặt lại mật khẩu qua deep link
    │   │   ├── account_info_page.dart   → Xem/sửa thông tin cá nhân
    │   │   ├── forbidden_page.dart      → Trang 403 khi thiếu quyền
    │   │   ├── cinematic_intro_page.dart → Màn intro điện ảnh lúc mở app
    │   │   ├── admin_dashboard_page.dart → Dashboard quản trị
    │   │   └── admin_movie_edit_page.dart → Thêm/sửa phim (Admin)
    │   └── widgets/                    → 30 widget dùng chung
    │       ├── navigation_shell.dart    → Bottom Nav 5 tab chính
    │       ├── app_top_navbar.dart      → Thanh topbar user
    │       ├── app_bottom_bar.dart      → Thanh bottom user
    │       ├── admin_top_navbar.dart    → Topbar khu vực admin
    │       ├── admin_bottom_bar.dart    → Bottom khu vực admin
    │       ├── admin_movies_tab.dart    → Tab quản lý phim
    │       ├── admin_users_tab.dart     → Tab quản lý user / khóa acc
    │       ├── admin_comments_tab.dart  → Tab duyệt bình luận
    │       ├── admin_genres_tab.dart    → Tab quản lý thể loại/quốc gia
    │       ├── admin_notifications_tab.dart → Tab gửi thông báo
    │       ├── movie_card.dart          → Thẻ phim nhỏ
    │       ├── movie_grid.dart          → Lưới phim
    │       ├── movie_row_section.dart   → Hàng phim ngang theo thể loại
    │       ├── hero_banner_carousel.dart → Banner xoay phim hot
    │       ├── trending_carousel.dart   → Carousel trending
    │       ├── episode_grid.dart        → Lưới chọn tập
    │       ├── comment_section.dart     → Khung bình luận + reply
    │       ├── rating_stars.dart        → Sao hiển thị 1–10
    │       ├── rating_modal.dart        → Popup chấm sao
    │       ├── embed_video_player.dart  → Router chọn player theo platform
    │       ├── embed_player_mobile.dart → Player cho Android/iOS
    │       ├── embed_player_web.dart    → Player cho Web PWA
    │       ├── embed_player_stub.dart   → Player giả khi test
    │       ├── search_input.dart        → Ô tìm kiếm + debounce
    │       ├── custom_button.dart       → Nút bấm style neon
    │       ├── confirm_dialog.dart      → Hộp xác nhận xóa/khóa
    │       ├── loading_spinner.dart     → Vòng xoay tải
    │       ├── pagination.dart          → Phân trang list
    │       ├── error_report_modal.dart  → Popup báo lỗi video
    │       └── movie_share_helper.dart  → Chia sẻ phim + tạo deep link
    │
    ├── test/                           → 🧪 13 file, 157 ca — xem mục Kiểm thử 8a–8e
    │   ├── validators_test.dart         → Test validate form, email, rating
    │   ├── input_sanitizer_test.dart    → Test cắt HTML, chặn XSS
    │   ├── video_source_test.dart       → Test parse YouTube, lọc URL độc
    │   ├── generic_utils_test.dart      → Test search/filter/sort/chunk
    │   ├── rate_limiter_test.dart       → Test chặn spam + debounce
    │   ├── movie_model_test.dart        → Test parse mềm movie JSON
    │   ├── models_extra_test.dart       → Test comment/episode/rating/watchlist
    │   ├── page_result_api_response_test.dart → Test bọc response + phân trang
    │   ├── repositories_test.dart       → Test bắt lỗi biên repository
    │   ├── common_widgets_test.dart     → Test SearchInput/Button/Spinner/Dialog/...
    │   ├── app_flow_test.dart           → Test flow Home→Search→Chi tiết→Player
    │   ├── movie_interactions_test.dart → Test yêu thích/đánh giá/lịch sử
    │   └── widget_test.dart             → Test smoke mặc định
    ├── android/ ios/ web/ windows/ linux/ macos/  → Platform folders (web/ đã build PWA)
    └── tool/                           → Tool build nội bộ
```

</details>

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:2b1400,100:f26522&height=3&width=1000)

</div>

## 🗄️ Mô hình dữ liệu (Firestore)

Không còn 14 bảng MySQL như bản web — bản mobile dùng **collections Firestore** (NoSQL), quan hệ thể hiện bằng **subcollection + field tham chiếu**:

```
users/{profileId}                        → Hồ sơ (docId là chuỗi số, VD "12")
  ├── favorites/{movieSlug}              → Phim yêu thích (riêng từng user)
  ├── watchlist/{movieSlug}              → Xem sau
  └── notifications/{notifId}            → Thông báo cá nhân

user_auth_map/{profileId}                → Nối Firebase UID ↔ profileId { uid, email, role }
admins/{uid}                             → Danh sách UID admin (ghi: không cho phép từ client)

movies/{slug}                            → Phim (đọc: public)
  ├── episodes/{episodeId}               → Tập phim (ghi: chỉ admin)
  ├── ratings/{uidAuth}                 → Điểm 1–10 (mỗi UID một điểm/phim)
  └── comments/{commentId}              → Bình luận phim

comments/{commentId}                     → Bình luận top-level (userId INT + ownsProfile)
ratings/{ratingId}                       → Đánh giá dự phòng
genres/{id} · countries/{id}             → Danh mục (ghi: chỉ admin)
movie_genres/{id} · movie_countries/{id} → Bảng nối n–n
watch_history/{docId}                    → { userId INT, movieSlug, episodeId, position }
error_reports/{docId}                    → Báo lỗi video (tạo: signed-in; xử lý: admin)
notifications/{notifId}                  → Thông báo chung (ghi: chỉ admin)
favorites/{id} · watchlist/{id}          → Dự phòng top-level
```

- **Khóa logic:** cặp `(uidAuth, movieSlug)` cho ratings; `user_auth_map` khóa `role` (client không tự nâng admin).
- **Kiểu mềm:** `userId` là INT (id hồ sơ), `profileId` trên path là STRING — rules dùng `ownsProfile(string(...))` để nối.
- **Mặc định khóa hết:** `match /{document=**} { allow read, write: if false; }`.

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:f26522,100:2b1400&height=3&width=1000)

</div>

## 🛡️ Kiến trúc bảo mật (do nhóm tự vẽ)

> 🛡️ Sơ đồ dưới do nhóm **tự vẽ bằng Mermaid** vì 15 ảnh gốc chưa có sơ đồ bảo mật — tổng hợp từ `secure_token_storage.dart`, `input_sanitizer.dart`, `rate_limiter.dart`, `video_source.dart`, `validators.dart` và `firestore.rules`.

| Lớp | Cơ chế (file thật) | Chống gì |
|-----|-------------------|----------|
| **L1. Validate đầu vào** | `validators.dart` (required, email, password, rating 1–10) + `validateComment()` | Form sai, điểm lậu, comment rỗng |
| **L2. Làm sạch XSS** | `input_sanitizer.dart` — strip `<tags>`, gọn khoảng trắng, cắt 2000 ký tự; UI chỉ dùng `Text` (không render HTML) | `<script>`, paste HTML từ web |
| **L3. Token an toàn** | `secure_token_storage.dart` — access/refresh token vào Keychain / EncryptedSharedPreferences; logout xóa sạch; theme mới nằm SharedPreferences | Máy root đọc XML, token cũ sót lại |
| **L4. Chống spam** | `rate_limiter.dart` (1200 ms) + `SearchDebouncer` (400 ms) | Bấm liên tục, search dồn request |
| **L5. Video an toàn** | `video_source.dart` — chỉ nhận `https`, chặn `javascript:`/`file:`/`data:`/`http`, phân loại HLS/Direct/Iframe | Embed độc, mixed-content |
| **L6. Auth** | Firebase Auth + `AuthProvider.checkAuthStatus()` + `DeepLinkService` | Giả phiên, link reset giả |
| **L7. Phân quyền server** | `firestore.rules`: `isSignedIn()` / `isAdmin()` (check `admins/{uid}`) / `ownsProfile()` (qua `user_auth_map`) / `hasNoPlaintextPassword()` | Đọc trộm, tự nâng admin, lưu plaintext password |
| **L8. Mặc định từ chối** | `match /{document=**} { allow read, write: if false }` | Collection lạ bị lộ |

```mermaid
flowchart TB
    subgraph Client["📱 Flutter App (cinema_app)"]
        UI["Pages + Widgets\n(Text-only render)"]
        L1["L1 Validators\nform + rating 1-10"]
        L2["L2 InputSanitizer\nstrip HTML, max 2000"]
        L4["L4 RateLimiter 1200ms\nSearchDebouncer 400ms"]
        L5["L5 VideoSource\nhttps only, HLS/Direct/Iframe"]
        L3["L3 SecureTokenStorage\nKeychain / EncryptedPrefs"]
        VA["🎙️ Lina/Seven\nSTT-TT-Gemini (cô lập)"]
        UI --> L1 --> L2 --> L4
        L2 --> L5
        UI <--> L3
        UI <--> VA
    end
    subgraph Firebase["🔥 Firebase (cinema-app-b760e)"]
        AUTH["Firebase Auth\nEmail/Password + DeepLink reset"]
        RULES["firestore.rules\nisSignedIn / isAdmin\nownsProfile / hasNoPlaintextPassword\ndefault DENY"]
        DATA[("Firestore Data\nmovies (public read)\nusers + subcollections (owner)\nadmins (no client write)")]
        AUTH --> RULES --> DATA
    end
    Client -- "ID token (không lưu plaintext)" --> AUTH
    L2 -- "comment sạch + userId INT" --> RULES
    L5 -- "URL đã lọc" --> UI
    L3 -- "logout → clearTokens()" --> Client
    style L3 fill:#2b1400,stroke:#f26522,color:#ffcf9e
    style RULES fill:#2b1400,stroke:#f26522,color:#ffcf9e
```

> 💡 **Đánh đổi đã phân tích:** mobile không có cookie HttpOnly nên token buộc nằm trên máy — nhóm tách hẳn 2 kho (bí mật → mã hóa, thường → SharedPreferences) và dồn mọi quyết định phân quyền về Rules phía server, client chỉ là lớp lọc sớm để tiết kiệm RAM/data.

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:2b1400,100:f26522&height=3&width=1000)

</div>

## 📊 Sơ đồ hệ thống (15 ảnh + 2 sơ đồ tự vẽ)

### 📐 Class Diagram — Model Mobile + Backend tham khảo

![Class Diagram](docs/images/ClassDiagrams.drawio.png)

---

### 🧩 Kiến trúc tổng thể — Flutter + Firebase + Gemini + Render/APK

![Kiến trúc tổng thể](docs/images/KTTongThe.drawio.png)

---

### 🔄 Activity Diagram — Luồng nghiệp vụ

#### 🔐 Đăng nhập (Login)

![Đăng nhập](docs/images/ACLogin.png)

#### 📝 Tìm kiếm & Lọc phim

![Tìm kiếm lọc phim](docs/images/AcTimKiemLocPhim.png)

#### 🚫 Khóa tài khoản (Ban Acc — Admin)

![Ban Acc](docs/images/AC_BandAcc.png)

#### 🎬 Chọn tập & Phát video

![Chọn tập phát video](docs/images/AC_ChonTapVaPhatVideo.png)

---

### 📡 Sequence Diagram — Mobile flows

#### 🔑 Login (Mobile)

![Mobile Login](docs/images/Movies_Mobile-Login.png)

#### 📝 Đăng ký (Mobile)

![Mobile Đăng ký](docs/images/Movies_Mobile-Dang%20ky.png)

#### 🔎 Tìm kiếm (Mobile)

![Mobile Search](docs/images/Movies_Mobile-search.png)

#### ▶️ Xem phim (Mobile)

![Mobile Watch](docs/images/Movies_Mobile-watch.png)

#### 💬 Bình luận (Mobile)

![Mobile Comment](docs/images/Movies_Mobile-comment.png)

#### 👍 Like / Dislike (Mobile)

![Mobile Like Dislike](docs/images/Movies_Mobile-like_dislike.png)

---

### 📡 Sequence Diagram — Nghiệp vụ chi tiết

#### 📖 Xem chi tiết phim

![Xem chi tiết phim](docs/images/Se_XemChiTietPhim.png)

#### ❤️ Quản lý phim yêu thích

![Quản lý yêu thích](docs/images/SE_QuanLyPhimYeuThich.png)

#### 🕘 Quản lý lịch sử xem

![Quản lý lịch sử xem](docs/images/SE_QLLSXEM.drawio.png)

---

### 📸 Demo video & App dùng thử

> 📱 **Bấm là xài — không cần cài máy ảo:** mở link VMOS dưới đây là điều khiển được app thật ngay trên trình duyệt.

| Kênh dùng thử | Link |
|---|---|
| 📱 **App Demo Cloud (VMOS)** — bấm vào xài trực tiếp | <a href="https://cloud.vmoscloud.com/screen/share/#token=164E-C79D-35E3-4E51-936E-3DEF-99E3-91B9">Mở App Demo Cloud</a> |
| 🌐 **Bản Web PWA Live** — deploy từ `cinema_app/Dockerfile` + `render.yaml` | <a href="https://phimhay24h.onrender.com">phimhay24h.onrender.com</a> (lần đầu mở chờ 5–20 s để Render "đánh thức" free tier) |
| 📦 **APK Android** — tab Actions → workflow `build-apk` → `app-release.apk` (~59 MB) | <a href="https://github.com/hung123-alt/mobile/actions">Tải trên GitHub Actions</a> rồi kéo vào Appetize.io (Pixel 8, Android 14) để test không cần máy thật |
| 🎬 **Video Demo YouTube** | *(Bạn dán link YouTube vào đây — khung giữ chỗ, ví dụ: `https://www.youtube.com/watch?v=...`)* |

```text
TODO (bạn cập nhật sau): thay dòng trên bằng link YouTube thật, ví dụ:
🎬 Video Demo: https://www.youtube.com/watch?v=YOUR_VIDEO_ID
```

#### 🌐 Trang chủ Web Phim — giao diện User

![Trang chủ Web](docs/images/web-home.png)

#### 🛠️ Trang Admin — giao diện yêu cầu (quản trị)

![Trang Admin](docs/images/web-admin.png)

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:f26522,100:2b1400&height=3&width=1000)

</div>

## 🧪 Kiểm thử & Kiểm định (8a – 8e)

> ✅ Đã chạy toàn bộ trên nhánh `main`: **13 file · 157 ca · All tests passed!** (`flutter test` trong `cinema_app/`).

| Yêu cầu | Nội dung | File kiểm thử |
|---------|----------|---------------|
| **8a. Xử lý lỗi** | Repository bắt `ApiException` ở biên I/O → trả default an toàn, không crash app | `repositories_test.dart` |
| **8b. Unit test Core** | Validators, sanitizer, video source, utils, rate limiter, models | `validators_test.dart`, `input_sanitizer_test.dart`, `video_source_test.dart`, `generic_utils_test.dart`, `rate_limiter_test.dart`, `movie_model_test.dart`, `models_extra_test.dart`, `page_result_api_response_test.dart` |
| **8c. Full app flow** | Mô phỏng Question 1: Home → Search → Category → Favorite/Profile → Player | `app_flow_test.dart` |
| **8d. Thành công / Thất bại** | Mỗi service có case thành công + thất bại (sai format, quá dài, URL độc, spam nhanh) | Rải khắp các file trên + `movie_interactions_test.dart` |
| **8e. Widget UI** | `SearchInput`, `CustomButton`, `LoadingSpinner`, `ConfirmDialog`, `Pagination`, `RatingStars` | `common_widgets_test.dart`, `widget_test.dart` |

```bash
cd cinema_app
flutter pub get
flutter test
# 00:xx +157: All tests passed!
```

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:2b1400,100:f26522&height=3&width=1000)

</div>

## ⚙️ Cài đặt & Chạy nhanh

### Yêu cầu

- **Flutter 3.x** + Dart `>=3.12.0`
- Tài khoản Firebase (project `cinema-app-b760e`) nếu muốn chạy Auth/Firestore thật
- Trình duyệt (cho PWA) hoặc máy ảo Android (cho APK)

### 1) Chạy mobile (debug)

```bash
cd cinema_app
flutter pub get
flutter run
```

### 2) Build APK bằng GitHub Actions

- Workflow: `.github/workflows/build-apk.yml` (`flutter channel stable`, không set `flutter-version`).
- Vào **Actions → build-apk → Run workflow** trên nhánh `main` → tải Artifact `app-release-apk`.
- Muốn test không cần máy thật: upload APK lên **Appetize.io** (Pixel 8 · Android 14).

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:2b1400,100:f26522&height=3&width=1000)

</div>

## 👥 Nhóm phát triển

<div align="center">

| Thành viên | MSSV | Tài khoản GitHub | Phụ trách (mobile) |
|-----------|------|------------------|-------------------|
| Trần Quốc Việt Hùng | 24100015 | [hung123-alt](https://github.com/hung123-alt) | Search + Category + Favorite + Profile, CI APK, deploy Render, README |
| Bùi Quang Hưng | 24100129 | [hungdzx1](https://github.com/hungdzx1) | Home + Setup, Firebase, theme |
| Doãn Bùi Đình Hiếu | 24100221 | — | Phụ trách (bạn bổ sung sau) |
| Nguyễn Văn Thành Hưng | 24100101 | — | Phụ trách (bạn bổ sung sau) |

</div>

<div align="center">

![divider](https://capsule-render.vercel.app/api?type=rect&color=0:2b1400,100:f26522&height=3&width=1000)

</div>

## 📚 Tài liệu tham khảo

- [Flutter Documentation](https://docs.flutter.dev)
- [Firebase Auth + Firestore](https://firebase.google.com/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- [speech_to_text](https://pub.dev/packages/speech_to_text) · [flutter_tts](https://pub.dev/packages/flutter_tts)
- [NestJS Documentation](https://docs.nestjs.com) (backend tham khảo trong `server/`)
- [Render Docker Deploy](https://render.com/docs/docker) · [GitHub Actions](https://docs.github.com/actions)

---

<div align="center">

![Footer](https://capsule-render.vercel.app/api?type=waving&color=0:2b1400,50:1a1005,100:0b0b0f&height=150&section=footer&text=PHIMHAY24H%20—%20Nhóm%204&fontSize=24&fontColor=f26522&animation=fadeIn&fontAlignY=65)

<p>
  <img src="https://img.shields.io/badge/Made%20with-❤️%20%26%20Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Made with Flutter"/>
  &nbsp;
  <img src="https://img.shields.io/badge/PhimHay24h-Nhóm%204-f26522?style=flat-square" alt="PhimHay24 Nhóm 4"/>
</p>

<sub>⬆️ <a href="#-mục-lục">Về đầu trang</a> · Repo: <a href="https://github.com/hung123-alt/mobile">hung123-alt/mobile</a> · Web live: <a href="https://phimhay24h.onrender.com">phimhay24h.onrender.com</a></sub>

</div>
