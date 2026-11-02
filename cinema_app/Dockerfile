# ============================================================
# Dockerfile — Build Flutter Web rồi serve bằng nginx
# Dùng cho Render (runtime: docker) để deploy app PhimHay24h
# thành PWA — mở bằng link trên điện thoại, thêm vào MH chính.
#
# Stage 1: build bằng image Flutter stable (cùng image devcontainer dùng)
# Stage 2: serve file tĩnh bằng nginx alpine (nhẹ, nhanh)
# ============================================================

# ---------- STAGE 1: BUILD ----------
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Dùng thư mục không khoảng trắng để tránh lỗi native assets hook
WORKDIR /app

# Copy pubspec trước để tận dụng Docker cache (đổi lockfile mới rebuild)
COPY pubspec.yaml pubspec.lock ./

# flutter_secure_storage cần dart:js / web — bảo đảm web đã bật
RUN flutter config --enable-web \
    && flutter --version \
    && dart --version

RUN flutter pub get

# Copy toàn bộ source app
COPY . .

# Build web bản release.
# --no-wasm-dry-run: bỏ qua bước kiểm tra wasm (một số plugin chưa hỗ trợ wasm,
#                     nhưng build JS thường vẫn OK — đây chỉ là cảnh báo).
# --base-href /: deploy ở root domain.
RUN flutter build web \
    --release \
    --no-wasm-dry-run \
    --base-href /

# ---------- STAGE 2: SERVE ----------
FROM nginx:alpine

# Xoá trang mặc định của nginx
RUN rm -f /usr/share/nginx/html/*

# Copy kết quả build
COPY --from=builder /app/build/web /usr/share/nginx/html

# Cấu hình nginx: fallback về index.html cho SPA routing + nén gzip + cache
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
