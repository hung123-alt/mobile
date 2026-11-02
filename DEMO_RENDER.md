# Hướng dẫn Demo PhimHay24h trên Render

App Flutter (PWA) + APK Android. Dữ liệu lấy từ **Firebase Firestore + Firebase Auth** nên
chạy được ngay, **không cần backend NestJS**.

---

## 1. Deploy lên Render (link web cho điện thoại)

### 1.1. Thêm domain Render vào Firebase Auth (BẮT BUỘC)

Bỏ qua bước này thì khi bấm "Đăng nhập" sẽ báo lỗi *Domain not whitelisted by project*.

1. Vào <https://console.firebase.google.com> → chọn project **cinema-app-b760e**
2. **Authentication** → tab **Settings** → **Authorized domains**
3. **Add domain** → gõ `phimhay24h.onrender.com` → **Add**
4. Thêm luôn `*.onrender.com` để không sợ đổi tên service sau này

### 1.2. Tạo Web Service trên Render

1. Vào <https://dashboard.render.com> → **New** → **Web Service**
2. **Connect repository** → chọn `hung123-alt/mobile`
3. Cấu hình:

| Ô | Điền |
|---|---|
| Name | `phimhay24h` |
| Branch | `feature/demo-render` |
| Runtime | **Docker** |
| Dockerfile Path | `./cinema_app/Dockerfile` |
| Docker Context Path | `./cinema_app` |
| Instance Type | Free |

4. **Create Web Service**

> Render sẽ build Docker image (Flutter SDK → nginx). Lần đầu mất **5-10 phút**.
> Render tự động đọc file `render.yaml` (Blueprint) ở gốc repo nên cũng có thể tạo
> qua **New → Blueprint** — khi đó chỉ cần chọn repo là xong.

### 1.3. Lấy link

Sau khi deploy xong, Render hiện URL dạng:

```
https://phimhay24h.onrender.com
```

### 1.4. Dùng trên điện thoại

1. Mở link bằng Chrome (Android) hoặc Safari (iPhone)
2. **Thêm vào màn hình chính** → app biến thành icon, mở ra fullscreen không có thanh địa chỉ
3. Đăng nhập / xem phim / xem tập phim — tất cả đọc từ Firestore nên hoạt động bình thường

> **Lưu ý Free tier**: Render ngủ (sleep) sau khi không có người dùng ~15 phút.
> Lần mở đầu tiên sau khi ngủ sẽ chờ khoảng 30-60 giây. Trước buổi demo nên mở app
> "khởi động trước" vài phút.

---

## 2. Build APK Android (demo trên trình duyệt qua Appetize.io)

### 2.1. Chạy workflow build APK

1. Vào repo <https://github.com/hung123-alt/mobile> → tab **Actions**
2. Chọn workflow **Build APK** → **Run workflow**
3. Đợi ~5-10 phút (server GitHub build, không cần máy bạn)

### 2.2. Tải file APK

Cuối trang workflow đó → mục **Artifacts** → tải `phimhay24h-apk` → giải nén →
có file `app-release.apk`.

### 2.3. Upload lên Appetize.io

1. Vào <https://appetize.io> → đăng nhập (miễn phí)
2. **Upload app** → chọn file `app-release.apk`
3. Chọn Device: **Google Pixel 7** hoặc tương tự
4. Bấm **Add** → app được cài vào máy ảo
5. Bấm **Share** → copy link → gửi cho giáo viên

> Giáo viên mở link → thấy **máy ảo Android** đang chạy app thật của bạn, không cần
> cài gì.

### 2.4. Lưu ý về quota Appetize

Free tier giới hạn số phút chạy máy ảo mỗi tháng (reset ngày 1/12).
**Đừng mở treo tab máy ảo** khi không dùng — nên đóng tab sau khi demo xong.

---

## 3. Nội dung bạn cần nói khi demo

- App chạy trên **Flutter** (một codebase, build ra cả Android, iOS, Web)
- Dữ liệu lưu ở **Firebase** (Firestore + Authentication) → mọi máy đều thấy cùng dữ liệu
- Có trợ lý giọng nói **Lina / Seven** tích hợp Gemini (STT + TTS)
- Màn hình **Bảng điều khiển Admin** được dựng theo layout mẫu của giáo viên:
  breadcrumb, bộ lọc thời gian, 8 thẻ chỉ số, 3 biểu đồ (vẽ tay bằng `CustomPainter`,
  không dùng thư viện chart), bảng có cột STT — số liệu 100% lấy từ Firestore

---

## 4. Cấu trúc file phục vụ deploy

```
render.yaml                  ← Render Blueprint (đọc ở gốc repo)
cinema_app/Dockerfile        ← Stage 1: build Flutter Web · Stage 2: nginx serve
cinema_app/nginx.conf        ← SPA fallback + gzip + cache policy
cinema_app/.dockerignore     ← giảm build context
.github/workflows/build-apk.yml  ← build APK universal + upload Artifact
```
