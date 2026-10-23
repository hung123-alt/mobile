import 'package:flutter/foundation.dart';

import '../models/watchlist_item_model.dart';
import '../services/api_service.dart';
import '../services/watchlist_service.dart';


class WatchlistRepository {
  WatchlistRepository(this._watchlistService);

  final WatchlistService _watchlistService;

  /// Thêm phim vào xem sau. Trả `true` nếu thành công.
  Future<bool> add(int movieId) async {
    try {
      await _watchlistService.add(movieId);
      return true;
    } on ApiException catch (e) {
      debugPrint('WatchlistRepository.add($movieId) lỗi: $e');
      return false;
    }
  }

  /// Danh sách xem sau của người dùng hiện tại.
  Future<List<WatchlistItem>> getMine() async {
    try {
      return await _watchlistService.getMine();
    } on ApiException catch (e) {
      debugPrint('WatchlistRepository.getMine lỗi: $e');
      return <WatchlistItem>[];
    }
  }

  /// Kiểm tra phim đã có trong danh sách xem sau chưa.
  ///
  /// Trả `false` khi lỗi mạng — coi như "chưa lưu" để nút bấm không bị
  /// kẹt ở trạng thái sai.
  Future<bool> isInWatchlist(int movieId) async {
    try {
      return await _watchlistService.checkInWatchlist(movieId);
    } on ApiException catch (e) {
      debugPrint('WatchlistRepository.isInWatchlist($movieId) lỗi: $e');
      return false;
    }
  }

  /// Bỏ phim khỏi danh sách xem sau. Trả `true` nếu thành công.
  Future<bool> remove(int movieId) async {
    try {
      await _watchlistService.remove(movieId);
      return true;
    } on ApiException catch (e) {
      debugPrint('WatchlistRepository.remove($movieId) lỗi: $e');
      return false;
    }
  }
}
