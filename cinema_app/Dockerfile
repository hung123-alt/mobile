# ============================================================
#  Dockerfile — Build Flutter Web rồi serve bằng nginx
#  Dùng cho Render (runtime: docker) để deploy app PhimHay24h
#  thành PWA — mở bằng link trên điện thoại, thêm vào MH chính.
#
#  Stage 1: build bằng image Flutter stable (cùng image devcontainer dùng)
#  Stage 2: serve file tĩnh bằng nginx alpine (nhẹ, nhanh)
#
#  ------------------------------------------------------------
#  QUAN TRỌNG — Dockerfile này KHÔNG phụ thuộc Docker Context:
#  - Context = gốc repo   (chứa thư mục cinema_app/)
#  - Context = cinema_app/ (chứa thẳng pubspec.yaml)
#  Cả hai trường hợp đều chạy được nhờ bước "dò layout" ở stage 1.
#  Trên Render: Dockerfile Path = ./cinema_app/Dockerfile
#               Docker Context = .   (gốc repo)
# ============================================================

# ---------- STAGE 1: BUILD ----------
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Dùng thư mục không khoảng trắng để tránh lỗi native assets hook
WORKDIR /workspace

# Copy TOÀN BỘ context vào /workspace (chỉ 1 lần, không cần biết layout)
COPY . /workspace

# --- DÒ LAYOUT: app Flutter nằm ở đâu trong context? ---
# Nếu context gốc repo -> /workspace/cinema_app có pubspec.yaml
# Nếu context cinema_app -> /workspace có pubspec.yaml
# Gom về một chỗ /app cho các bước sau.
RUN set -eux; \
    if [ -f "/workspace/cinema_app/pubspec.yaml" ]; then \
        echo ">> Phat hien: context = goc repo (co thu muc cinema_app/)"; \
        mkdir -p /app && cp -a /workspace/cinema_app/. /app/; \
    elif [ -f "/workspace/pubspec.yaml" ]; then \
        echo ">> Phat hien: context = cinema_app/"; \
        mkdir -p /app && cp -a /workspace/. /app/; \
    else \
        echo ">> LOI: khong tim thay pubspec.yaml trong context" >&2; \
        ls -la /workspace >&2; exit 1; \
    fi; \
    ls -la /app | head -n 30

# --- Bắt đầu build trong /app ---
WORKDIR /app

# flutter_secure_storage cần dart:js / web — bảo đảm web đã bật
RUN flutter config --enable-web \
    && flutter --version \
    && dart --version

# Dùng pubspec.lock có sẵn để build lặp lại cho ra kết quả giống nhau
RUN flutter pub get

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
# (copy từ stage builder để không phụ thuộc vị trí nginx.conf trong context)
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
