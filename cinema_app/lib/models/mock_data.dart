import 'User.dart';
import 'movie_model.dart';

// Tạo sẵn một User mẫu
final User testUser = User()..setUser(1, 'nguyenlethu', 'lethu@gmail.com', '123456');

// Tạo sẵn một Phim mẫu
final Movies testMovie = Movies(
  id: 1,
  title: 'Lật Mặt 7',
  description: 'Một bộ phim gia đình cảm động.',
  thumbnail: 'lat_mat_7.jpg',
  categoryId: 1,
  countryId: 1,
  releaseYear: 2024,
  movieType: 'Tâm lý',
  status: 'Đang chiếu',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);