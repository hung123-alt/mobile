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
2. Thiết kế Mô hình Dữ liệu (Data Model)

Dựa trên lược đồ thực thể (Class Diagram), đối tượng Category đã được mô hình hóa thành Dart class trong ứng dụng Flutter:

Vị trí file: lib/models/category.dart
Các trường dữ liệu chính:
id (int): Mã định danh duy nhất của danh mục.
name (String): Tên danh mục/thể loại phim.
description (String): Mô tả chi tiết về danh mục.
isActive (bool): Trạng thái hoạt động của danh mục, xác định danh mục có đang được sử dụng/hiển thị trong hệ thống hay không.
createdAt (DateTime): Thời gian danh mục được tạo trong hệ thống.
updatedAt (DateTime): Thời gian danh mục được cập nhật gần nhất.
Quan hệ dữ liệu:
Một Category có thể liên kết với nhiều Movie.
Quan hệ giữa Category và Movie là 1 - N (One-to-Many), trong đó một danh mục có thể chứa nhiều bộ phim, còn mỗi bộ phim thuộc về một danh mục.