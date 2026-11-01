import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';

enum CommentSortOption {
  newest,
  popular,
  oldest,
}

/// Khu vực bình luận cho phim (hiển thị danh sách bình luận, ô viết bình luận,
/// trả lời, like/dislike, sắp xếp và xoá bình luận).
class CommentSection extends StatefulWidget {
  final int movieId;

  const CommentSection({
    super.key,
    required this.movieId,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  List<Comment> _comments = [];
  final Map<int, User> _userCache = {};
  bool _isLoading = true;
  bool _isSending = false;
  CommentSortOption _sortOption = CommentSortOption.newest;
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void didUpdateWidget(covariant CommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movieId != widget.movieId) {
      _replyingTo = null;
      _loadComments();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);

    try {
      // Lấy bình luận theo movieId hoặc movie_id (dữ liệu migrate từ MySQL)
      final snapCamel = await _firestore
          .collection(CollectionNames.comments)
          .where('movieId', isEqualTo: widget.movieId)
          .get();

      final snapSnake = await _firestore
          .collection(CollectionNames.comments)
          .where('movie_id', isEqualTo: widget.movieId)
          .get();

      final docMap = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final d in snapCamel.docs) {
        docMap[d.id] = d;
      }
      for (final d in snapSnake.docs) {
        docMap[d.id] = d;
      }

      final parsed = <Comment>[];
      final missingUserIds = <int>{};

      for (final entry in docMap.entries) {
        final c = Comment.fromJson(entry.value.data(), docId: entry.key);
        if (!c.isHidden && c.content.trim().isNotEmpty) {
          parsed.add(c);
          if ((c.authorName == null || c.authorName!.isEmpty) && c.userId > 0) {
            missingUserIds.add(c.userId);
          }
        }
      }

      // Tải thông tin user (tên & avatar) từ collection users cho các comment cũ
      for (final uid in missingUserIds) {
        if (!_userCache.containsKey(uid)) {
          try {
            final uDoc = await _firestore
                .collection(CollectionNames.users)
                .doc(uid.toString())
                .get();
            if (uDoc.exists && uDoc.data() != null) {
              _userCache[uid] = User.fromJson(uDoc.data()!);
            } else {
              final q = await _firestore
                  .collection(CollectionNames.users)
                  .where('id', isEqualTo: uid)
                  .limit(1)
                  .get();
              if (q.docs.isNotEmpty) {
                _userCache[uid] = User.fromJson(q.docs.first.data());
              }
            }
          } catch (_) {}
        }
      }

      final enriched = parsed.map((c) {
        final cachedUser = _userCache[c.userId];
        if (cachedUser != null) {
          return c.copyWith(
            authorName: (c.authorName != null && c.authorName!.isNotEmpty)
                ? c.authorName
                : cachedUser.getDisplayName(),
            authorAvatar: c.authorAvatar ?? cachedUser.avatarUrl,
          );
        }
        return c;
      }).toList();

      if (mounted) {
        setState(() {
          _comments = enriched;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải bình luận: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<int> _getNextCommentId() async {
    try {
      final snap = await _firestore
          .collection(CollectionNames.comments)
          .orderBy('id', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final rawId = snap.docs.first.data()['id'];
        if (rawId is int) return rawId + 1;
        if (rawId is num) return rawId.toInt() + 1;
      }
    } catch (_) {}
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  void _requireLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Vui lòng đăng nhập để bình luận và tương tác'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Đăng nhập',
          textColor: Colors.amber,
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.login);
          },
        ),
      ),
    );
  }

  Future<void> _handleSendComment() async {
    final user = AuthProvider.instance.currentUser;
    if (user == null) {
      _requireLoginPrompt();
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final nextId = await _getNextCommentId();
      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final parentId = _replyingTo?.id;

      final data = <String, dynamic>{
        'id': nextId,
        'userId': user.id,
        'user_id': user.id,
        'movieId': widget.movieId,
        'movie_id': widget.movieId,
        'parentId': parentId,
        'parent_id': parentId,
        'content': text,
        'isHidden': false,
        'is_hidden': 0,
        'authorName': user.getDisplayName(),
        'authorAvatar': user.avatarUrl,
        'likeCount': 0,
        'dislikeCount': 0,
        'likedUserIds': <int>[],
        'dislikedUserIds': <int>[],
        'createdAt': nowIso,
        'created_at': nowIso,
        'updatedAt': nowIso,
        'updated_at': nowIso,
      };

      final docId = nextId.toString();
      await _firestore
          .collection(CollectionNames.comments)
          .doc(docId)
          .set(data);

      final newComment = Comment.fromJson(data, docId: docId);

      if (!mounted) return;
      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
        _replyingTo = null;
        _isSending = false;
      });
      _inputFocusNode.unfocus();
    } catch (e) {
      debugPrint('Lỗi gửi bình luận: $e');
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi bình luận: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleReaction(Comment comment, {required bool isLike}) async {
    final user = AuthProvider.instance.currentUser;
    if (user == null) {
      _requireLoginPrompt();
      return;
    }

    final uid = user.id;
    final liked = List<int>.from(comment.likedUserIds);
    final disliked = List<int>.from(comment.dislikedUserIds);

    int newLikeCount = comment.likeCount;
    int newDislikeCount = comment.dislikeCount;

    if (isLike) {
      if (liked.contains(uid)) {
        liked.remove(uid);
        newLikeCount = (newLikeCount - 1).clamp(0, 999999);
      } else {
        liked.add(uid);
        newLikeCount += 1;
        if (disliked.contains(uid)) {
          disliked.remove(uid);
          newDislikeCount = (newDislikeCount - 1).clamp(0, 999999);
        }
      }
    } else {
      if (disliked.contains(uid)) {
        disliked.remove(uid);
        newDislikeCount = (newDislikeCount - 1).clamp(0, 999999);
      } else {
        disliked.add(uid);
        newDislikeCount += 1;
        if (liked.contains(uid)) {
          liked.remove(uid);
          newLikeCount = (newLikeCount - 1).clamp(0, 999999);
        }
      }
    }

    final updated = comment.copyWith(
      likeCount: newLikeCount,
      dislikeCount: newDislikeCount,
      likedUserIds: liked,
      dislikedUserIds: disliked,
    );

    setState(() {
      final idx = _comments.indexWhere(
        (c) => (c.docId != null && c.docId == comment.docId) || c.id == comment.id,
      );
      if (idx != -1) {
        _comments[idx] = updated;
      }
    });

    final docId = comment.docId ?? comment.id.toString();
    try {
      await _firestore.collection(CollectionNames.comments).doc(docId).set({
        'likeCount': newLikeCount,
        'dislikeCount': newDislikeCount,
        'likedUserIds': liked,
        'dislikedUserIds': disliked,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Lỗi cập nhật reaction: $e');
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final docId = comment.docId ?? comment.id.toString();
    setState(() {
      _comments.removeWhere(
        (c) =>
            (c.docId != null && c.docId == comment.docId) ||
            c.id == comment.id ||
            c.parentId == comment.id,
      );
    });

    try {
      await _firestore.collection(CollectionNames.comments).doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa bình luận'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi xoá bình luận: $e');
    }
  }

  List<Comment> _getSortedTopLevelComments() {
    final topIds = _comments.map((c) => c.id).toSet();
    final roots = _comments
        .where((c) => !c.getIsReply() || !topIds.contains(c.parentId))
        .toList();

    roots.sort((a, b) {
      switch (_sortOption) {
        case CommentSortOption.newest:
          final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final cmp = db.compareTo(da);
          return cmp != 0 ? cmp : b.id.compareTo(a.id);
        case CommentSortOption.popular:
          final cmp = b.likeCount.compareTo(a.likeCount);
          return cmp != 0 ? cmp : b.id.compareTo(a.id);
        case CommentSortOption.oldest:
          final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final cmp = da.compareTo(db);
          return cmp != 0 ? cmp : a.id.compareTo(b.id);
      }
    });

    return roots;
  }

  List<Comment> _getRepliesFor(int parentId) {
    final replies = _comments
        .where((c) => c.getIsReply() && c.parentId == parentId)
        .toList();
    replies.sort((a, b) {
      final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
    return replies;
  }

  String get _sortLabel {
    switch (_sortOption) {
      case CommentSortOption.newest:
        return 'Mới nhất';
      case CommentSortOption.popular:
        return 'Nổi bật';
      case CommentSortOption.oldest:
        return 'Cũ nhất';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = AuthProvider.instance.currentUser;
    final topComments = _getSortedTopLevelComments();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== 1. TIÊU ĐỀ BÌNH LUẬN + BỘ SẮP XẾP =====
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bình luận (${_comments.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0B1021),
              ),
            ),
            PopupMenuButton<CommentSortOption>(
              onSelected: (opt) {
                setState(() => _sortOption = opt);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: CommentSortOption.newest,
                  child: Text('Mới nhất'),
                ),
                PopupMenuItem(
                  value: CommentSortOption.popular,
                  child: Text('Nổi bật'),
                ),
                PopupMenuItem(
                  value: CommentSortOption.oldest,
                  child: Text('Cũ nhất'),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sắp xếp: $_sortLabel',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : const Color(0xFF1F2937),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Nếu đang trả lời 1 bình luận thì hiển thị thanh báo trả lời
        if (_replyingTo != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4B5C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.reply_rounded,
                  size: 16,
                  color: Color(0xFFFF4B5C),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Đang trả lời ${_replyingTo!.authorName ?? "Người dùng #${_replyingTo!.userId}"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF4B5C),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _replyingTo = null),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFFFF4B5C),
                  ),
                ),
              ],
            ),
          ),

        // ===== 2. Ô NHẬP BÌNH LUẬN =====
        Row(
          children: [
            _buildAvatar(
              avatarUrl: currentUser?.avatarUrl,
              name: currentUser?.getDisplayName(),
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF242424)
                      : const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _inputFocusNode,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSendComment(),
                        style: TextStyle(
                          fontSize: 13.5,
                          color:
                              isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                        decoration: InputDecoration(
                          hintText: _replyingTo != null
                              ? 'Viết câu trả lời...'
                              : 'Viết bình luận...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF4B5C),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                      onPressed: _isSending ? null : _handleSendComment,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ===== 3. DANH SÁCH BÌNH LUẬN =====
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4B5C)),
            ),
          )
        else if (_comments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 38,
                  color: isDark ? Colors.white24 : Colors.grey[350],
                ),
                const SizedBox(height: 8),
                Text(
                  'Chưa có bình luận nào',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: topComments.length,
            separatorBuilder: (context, index) => Divider(
              height: 24,
              color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
            ),
            itemBuilder: (context, index) {
              final comment = topComments[index];
              final replies = _getRepliesFor(comment.id);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCommentItem(comment, isDark, currentUser),
                  if (replies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 44, top: 12),
                      child: Column(
                        children: replies
                            .map(
                              (rep) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildCommentItem(
                                  rep,
                                  isDark,
                                  currentUser,
                                  isReply: true,
                                  rootComment: comment,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildCommentItem(
    Comment comment,
    bool isDark,
    User? currentUser, {
    bool isReply = false,
    Comment? rootComment,
  }) {
    final author = comment.authorName?.trim().isNotEmpty == true
        ? comment.authorName!
        : 'Người dùng #${comment.userId}';
    final isLiked =
        currentUser != null && comment.likedUserIds.contains(currentUser.id);
    final isDisliked =
        currentUser != null && comment.dislikedUserIds.contains(currentUser.id);
    final canDelete = currentUser != null &&
        (currentUser.id == comment.userId || currentUser.getIsAdmin());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(
          avatarUrl: comment.authorAvatar,
          name: author,
          radius: isReply ? 15 : 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dòng 1: Tên người bình luận + Ngày giờ + Nút (...)
              Row(
                children: [
                  Flexible(
                    child: Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0B1021),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comment.getTimeAgoLabel(),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  if (canDelete)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                      onSelected: (val) {
                        if (val == 'delete') {
                          _deleteComment(comment);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Xoá bình luận',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    const Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                ],
              ),
              const SizedBox(height: 3),

              // Dòng 2: Nội dung bình luận
              Text(
                comment.content,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),

              // Dòng 3: Like / Dislike / Trả lời
              Row(
                children: [
                  // Nút Like
                  GestureDetector(
                    onTap: () => _toggleReaction(comment, isLike: true),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Icon(
                          isLiked
                              ? Icons.thumb_up_alt_rounded
                              : Icons.thumb_up_alt_outlined,
                          size: 16,
                          color: isLiked
                              ? const Color(0xFFFF4B5C)
                              : const Color(0xFF6B7280),
                        ),
                        if (comment.likeCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likeCount}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isLiked ? FontWeight.bold : FontWeight.w500,
                              color: isLiked
                                  ? const Color(0xFFFF4B5C)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Nút Dislike
                  GestureDetector(
                    onTap: () => _toggleReaction(comment, isLike: false),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Icon(
                          isDisliked
                              ? Icons.thumb_down_alt_rounded
                              : Icons.thumb_down_alt_outlined,
                          size: 16,
                          color: isDisliked
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF6B7280),
                        ),
                        if (comment.dislikeCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${comment.dislikeCount}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isDisliked
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isDisliked
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),

                  // Nút Trả lời
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyingTo = rootComment ?? comment;
                      });
                      _inputFocusNode.requestFocus();
                    },
                    child: const Text(
                      'Trả lời',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar({
    required String? avatarUrl,
    required String? name,
    double radius = 18,
  }) {
    final hasAvatar =
        avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl != 'null';
    final initial = (name != null && name.trim().isNotEmpty)
        ? name.trim().substring(0, 1).toUpperCase()
        : null;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: Color(0xFFD1D5DB),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackAvatarIcon(initial, radius),
              )
            : _buildFallbackAvatarIcon(initial, radius),
      ),
    );
  }

  Widget _buildFallbackAvatarIcon(String? initial, double radius) {
    if (initial != null) {
      return Container(
        color: const Color(0xFFFF4B5C).withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF4B5C),
          ),
        ),
      );
    }
    return Icon(
      Icons.person_rounded,
      size: radius * 1.3,
      color: Colors.white,
    );
  }
}
