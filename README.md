### 🎬 Quản lý Dữ liệu Phim (Movie Module)

#### 1. Thiết kế Mô hình Dữ liệu (Data Model)
Dựa trên lược đồ thực thể (Class Diagram), đối tượng `Movie` đã được mô hình hóa thành Dart class trong ứng dụng Flutter:
* **Vị trí file:** `lib/models/movie.dart`
* **Các trường dữ liệu chính:**
  * `id` (`int`): Mã định danh duy nhất của phim.
  * `title` (`String`): Tiêu đề/tên bộ phim.
  * `description` (`String`): Mô tả nội dung phim.
  * `thumbnail` (`String`): URL ảnh đại diện poster.
  * `categoryId` (`int`), `countryId` (`int`): Khóa ngoại liên kết danh mục và quốc gia.
  * `releaseYear` (`int`): Năm phát hành.
  * `movieType` (`String`), `status` (`String`): Phân loại (phim lẻ/bộ) và trạng thái hiển thị.
  * `createdAt`, `updatedAt` (`DateTime`): Dấu vết thời gian tạo và cập nhật.
* 