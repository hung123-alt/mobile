
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';
import '../services/movie_service.dart';
import 'movie_detail_page.dart';

class RandomPage extends StatefulWidget {
  const RandomPage({super.key});

  @override
  State<RandomPage> createState() => _RandomPageState();
}

class _RandomPageState extends State<RandomPage> {
  static const Color primaryColor = Color(0xFFFF4B5C);

  final ApiService _apiService = ApiService();
  final Random _random = Random();

  late final MovieService _movieService =
      MovieService(_apiService);

  late final Future<void> _loadMoviesFuture;

  final List<Movie> _cachedMovies = [];
  final Map<int, String> _genres = {};
  final Map<int, String> _countries = {};

  Movie? _selectedMovie;

  String _selectedType = 'all';
  String _selectedStatus = 'all';

  int _selectedGenreId = -1;
  int _selectedCountryId = -1;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Tải sẵn dữ liệu để dự phòng khi NestJS chưa chạy.
    _loadMoviesFuture = _loadFirebaseMovies();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  // ===== TẢI DANH SÁCH PHIM FIREBASE =====
  Future<void> _loadFirebaseMovies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(CollectionNames.movies)
          .get();

      final movies = <Movie>[];
      final genres = <int, String>{};
      final countries = <int, String>{};

      for (final document in snapshot.docs) {
        try {
          final movie = Movie.fromJson(document.data());

          if (!movie.isVisible) continue;

          movies.add(movie);

          for (final genre in movie.genres) {
            genres[genre.id] = genre.name;
          }

          for (final country in movie.countries) {
            countries[country.id] = country.name;
          }
        } catch (error) {
          debugPrint(
            'Không đọc được phim ${document.id}: $error',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _cachedMovies
          ..clear()
          ..addAll(movies);

        _genres
          ..clear()
          ..addAll(genres);

        _countries
          ..clear()
          ..addAll(countries);
      });
    } catch (error) {
      debugPrint(
        'Không tải được danh sách phim Firebase: $error',
      );
    }
  }

  // ===== KIỂM TRA BỘ LỌC =====
  bool _matchesFilters(Movie movie) {
    if (!movie.isVisible) return false;

    if (_selectedType != 'all' &&
        movie.type != _selectedType) {
      return false;
    }

    if (_selectedStatus != 'all' &&
        movie.status != _selectedStatus) {
      return false;
    }

    if (_selectedGenreId != -1) {
      final hasGenre = movie.genres.any(
        (genre) => genre.id == _selectedGenreId,
      );

      if (!hasGenre) return false;
    }

    if (_selectedCountryId != -1) {
      final hasCountry = movie.countries.any(
        (country) => country.id == _selectedCountryId,
      );

      if (!hasCountry) return false;
    }

    return true;
  }

  // ===== CHỌN NGẪU NHIÊN TRONG DANH SÁCH =====
  Movie _pickFromList(List<Movie> movies) {
    // Hạn chế chọn trùng phim vừa hiển thị.
    final otherMovies = movies.where((movie) {
      return movie.id != _selectedMovie?.id;
    }).toList();

    final candidates = otherMovies.isNotEmpty
        ? otherMovies
        : movies;

    final randomIndex = _random.nextInt(
      candidates.length,
    );

    return candidates[randomIndex];
  }

  // ===== CHỨC NĂNG RANDOM CHÍNH =====
  Future<void> _randomMovie() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Movie? result;

    try {
      final noTypeFilter = _selectedType == 'all';
      final noStatusFilter = _selectedStatus == 'all';
      final noGenreFilter = _selectedGenreId == -1;
      final noCountryFilter = _selectedCountryId == -1;

      final noFilters = noTypeFilter &&
          noStatusFilter &&
          noGenreFilter &&
          noCountryFilter;

      // ===== ƯU TIÊN API NESTJS =====
      // NestJS hỗ trợ loại, trạng thái và thể loại.
      // Quốc gia sẽ được lọc bằng Firebase bên dưới.
      if (noCountryFilter) {
        try {
          if (noFilters) {
            // GET /movies/random
            final movie = await _movieService
                .getRandomOne()
                .timeout(const Duration(seconds: 3));

            if (_matchesFilters(movie)) {
              result = movie;
            }
          } else {
            // GET /movies/random/advanced
            final movies = await _movieService
                .getRandomAdvanced(
                  type: noTypeFilter
                      ? null
                      : _selectedType,
                  status: noStatusFilter
                      ? null
                      : _selectedStatus,
                  genreIds: noGenreFilter
                      ? null
                      : [_selectedGenreId],
                  limit: 10,
                  sortBy: 'view',
                )
                .timeout(const Duration(seconds: 3));

            final validMovies = movies
                .where(_matchesFilters)
                .toList();

            if (validMovies.isNotEmpty) {
              result = _pickFromList(validMovies);
            }
          }
        } catch (error) {
          debugPrint(
            'NestJS Random không khả dụng: $error',
          );
        }
      }

      // ===== DỰ PHÒNG FIREBASE =====
      if (result == null) {
        await _loadMoviesFuture;

        final candidates = _cachedMovies
            .where(_matchesFilters)
            .toList();

        if (candidates.isNotEmpty) {
          result = _pickFromList(candidates);
        }
      }

      if (!mounted) return;

      setState(() {
        if (result != null) {
          _selectedMovie = result;
        } else {
          _selectedMovie = null;
          _errorMessage =
              'Không tìm thấy phim phù hợp với bộ lọc '
              'hoặc không thể kết nối nguồn dữ liệu.';
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Không thể chọn phim ngẫu nhiên: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ===== MỞ CHI TIẾT PHIM =====
  void _openMovieDetail() {
    final movie = _selectedMovie;

    if (movie == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailPage(
          movie: movie,
        ),
      ),
    );
  }

  // ===== GIAO DIỆN THẺ PHIM =====
  Widget _buildMovieCard(Movie movie) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final imageUrl = movie.displayImageUrl;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF242424)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF383838)
              : const Color(0xFFE5E7EB),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            _buildImageFallback(),
                  )
                : _buildImageFallback(),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  movie.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _movieInfo(
                      Icons.movie_outlined,
                      movie.getTypeLabel(),
                    ),
                    _movieInfo(
                      Icons.calendar_today_outlined,
                      movie.releaseYear?.toString() ??
                          'Chưa rõ',
                    ),
                    _movieInfo(
                      Icons.visibility_outlined,
                      movie.getViewCountLabel(),
                    ),
                    if (movie.ratingCount > 0)
                      _movieInfo(
                        Icons.star_rounded,
                        '${movie.avgRating.toStringAsFixed(1)}/10',
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  movie.description.isNotEmpty
                      ? movie.description
                      : 'Chưa có mô tả phim.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _openMovieDetail,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Xem chi tiết phim',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _movieInfo(
    IconData icon,
    String label,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: primaryColor,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFF1F2937),
      child: const Center(
        child: Icon(
          Icons.movie_filter_rounded,
          color: Colors.white54,
          size: 60,
        ),
      ),
    );
  }

  // ===== GIAO DIỆN BỘ LỌC =====
  Widget _buildFilters() {
    final sortedGenres = _genres.entries.toList()
      ..sort(
        (a, b) => a.value.compareTo(b.value),
      );

    final sortedCountries = _countries.entries.toList()
      ..sort(
        (a, b) => a.value.compareTo(b.value),
      );

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 440;

        final fieldWidth = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Loại phim',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Tất cả'),
                  ),
                  DropdownMenuItem(
                    value: 'phim_le',
                    child: Text('Phim lẻ'),
                  ),
                  DropdownMenuItem(
                    value: 'phim_bo',
                    child: Text('Phim bộ'),
                  ),
                  DropdownMenuItem(
                    value: 'hoat_hinh',
                    child: Text('Hoạt hình'),
                  ),
                  DropdownMenuItem(
                    value: 'anime',
                    child: Text('Anime'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ?? 'all';
                  });
                },
              ),
            ),

            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Tất cả'),
                  ),
                  DropdownMenuItem(
                    value: 'ongoing',
                    child: Text('Đang phát'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Hoàn thành'),
                  ),
                  DropdownMenuItem(
                    value: 'upcoming',
                    child: Text('Sắp chiếu'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value ?? 'all';
                  });
                },
              ),
            ),

            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<int>(
                initialValue: _selectedGenreId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Thể loại',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Text('Tất cả thể loại'),
                  ),
                  ...sortedGenres.map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGenreId = value ?? -1;
                  });
                },
              ),
            ),

            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<int>(
                initialValue: _selectedCountryId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Quốc gia',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Text('Tất cả quốc gia'),
                  ),
                  ...sortedCountries.map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCountryId = value ?? -1;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFFAFAFA),

      appBar: AppBar(
        title: const Text(
          'Phim ngẫu nhiên',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            }
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hôm nay xem phim gì?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Chọn bộ lọc yêu thích rồi để '
                  'PhimHay24h gợi ý một bộ phim cho bạn.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),

                // Bộ lọc
                _buildFilters(),

                const SizedBox(height: 20),

                // Nút Random
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : _randomMovie,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.shuffle_rounded,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isLoading
                          ? 'Đang tìm phim...'
                          : 'Chọn phim ngẫu nhiên',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),

                // Kết quả
                if (_selectedMovie != null) ...[
                  const Text(
                    'Phim dành cho bạn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildMovieCard(_selectedMovie!),
                ] else if (!_isLoading &&
                    _errorMessage == null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 42,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF242424)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.casino_outlined,
                          size: 56,
                          color: primaryColor,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Phim bất ngờ đang chờ bạn!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Nhấn nút phía trên để khám phá.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
