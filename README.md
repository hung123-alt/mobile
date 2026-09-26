# 🎬 PhimHay24h - Ứng dụng xem phim Flutter

## 👥 Thông tin nhóm

| MSSV | Họ tên | Công việc |
|------|--------|-----------|
| 24100129 | Bùi Quang Hưng | HomePage + Setup |
| 24100015 | Trần Quốc Việt Hùng | SearchPage + CategoryPage + FavoritePage + ProfilePage |

---

## 📱 Yêu cầu 1: Demo các trang (Bottom Navigation Bar)

### 1. Trang chủ (Home)


### 2. Tìm kiếm (Search)


### 3. Thể loại (Category)


### 4. Yêu thích (Favorite)


### 5. Tài khoản (Profile)


## 🛠 Yêu cầu 2: Công nghệ sử dụng

- **Ngôn ngữ**: Dart
- **Framework**: Flutter 3.x
- **State Management**: StatefulWidget / StatelessWidget
- **Cấu trúc**: Repository Pattern
- **Hình ảnh**: Unsplash API

---

## 📐 Yêu cầu 3: Kiến trúc & Design Pattern

### Cấu trúc thư mục
lib/ ├── main.dart # Entry point ├── widgets/ │ └── navigation_shell.dart # Bottom Navigation Bar ├── pages/ │ ├── home_page.dart # Trang chủ │ ├── search_page.dart # Tìm kiếm │ ├── category_page.dart # Thể loại │ ├── favorite_page.dart # Yêu thích │ └── profile_page.dart # Tài khoản ├── models/ │ └── movie_model.dart # Model phim └── repositories/ └── movie_repository.dart # Repository pattern

