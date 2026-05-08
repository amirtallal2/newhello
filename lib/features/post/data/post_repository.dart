import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

const Object _postUnset = Object();

class PostFeedData {
  const PostFeedData({required this.notificationCount, required this.posts});

  final int notificationCount;
  final List<PostItemData> posts;
}

class PostItemData {
  const PostItemData({
    required this.id,
    this.authorUserId,
    required this.authorKey,
    required this.authorName,
    required this.authorAvatarAsset,
    required this.bodyText,
    required this.dateLabel,
    required this.relativeTime,
    required this.isFollowed,
    required this.canFollow,
    required this.isLiked,
    required this.canEdit,
    required this.canDelete,
    required this.commentCount,
    required this.likeCount,
    required this.shareCount,
    this.isShared = false,
    this.sharedPostId,
    this.sharedAuthorName,
    this.sharedAuthorAvatarAsset,
    this.sharedBodyText,
    this.sharedImagePath,
    this.imagePath,
  });

  final int id;
  final int? authorUserId;
  final String authorKey;
  final String authorName;
  final String authorAvatarAsset;
  final String bodyText;
  final String dateLabel;
  final String relativeTime;
  final bool isFollowed;
  final bool canFollow;
  final bool isLiked;
  final bool canEdit;
  final bool canDelete;
  final int commentCount;
  final int likeCount;
  final int shareCount;
  final bool isShared;
  final int? sharedPostId;
  final String? sharedAuthorName;
  final String? sharedAuthorAvatarAsset;
  final String? sharedBodyText;
  final String? sharedImagePath;
  final String? imagePath;

  factory PostItemData.fromJson(Map<String, dynamic> json) {
    return PostItemData(
      id: _postAsInt(json['id']),
      authorUserId: json['author_user_id'] == null
          ? null
          : _postAsInt(json['author_user_id']),
      authorKey: json['author_key']?.toString() ?? 'seed:unknown',
      authorName: json['author_name']?.toString() ?? 'اسماء فتحي',
      authorAvatarAsset:
          json['author_avatar_asset']?.toString() ??
          'assets/images/post_author_avatar.png',
      bodyText: json['body_text']?.toString() ?? '',
      dateLabel: json['date_label']?.toString() ?? '10/25/2024',
      relativeTime: json['relative_time']?.toString() ?? '12 hours ago',
      isFollowed: json['is_followed'] == true,
      canFollow: json['can_follow'] != false,
      isLiked: json['is_liked'] == true,
      canEdit: json['can_edit'] == true,
      canDelete: json['can_delete'] == true,
      commentCount: _postAsInt(json['comment_count'], fallback: 0),
      likeCount: _postAsInt(json['like_count'], fallback: 0),
      shareCount: _postAsInt(json['share_count'], fallback: 0),
      isShared: json['is_shared'] == true,
      sharedPostId: json['shared_post_id'] == null
          ? null
          : _postAsInt(json['shared_post_id']),
      sharedAuthorName: json['shared_author_name']?.toString(),
      sharedAuthorAvatarAsset: json['shared_author_avatar_asset']?.toString(),
      sharedBodyText: json['shared_body_text']?.toString(),
      sharedImagePath: json['shared_image_path']?.toString(),
      imagePath: json['image_path']?.toString(),
    );
  }

  PostItemData copyWith({
    int? id,
    Object? authorUserId = _postUnset,
    String? authorKey,
    String? authorName,
    String? authorAvatarAsset,
    String? bodyText,
    String? dateLabel,
    String? relativeTime,
    bool? isFollowed,
    bool? canFollow,
    bool? isLiked,
    bool? canEdit,
    bool? canDelete,
    int? commentCount,
    int? likeCount,
    int? shareCount,
    bool? isShared,
    int? sharedPostId,
    String? sharedAuthorName,
    String? sharedAuthorAvatarAsset,
    String? sharedBodyText,
    String? sharedImagePath,
    Object? imagePath = _postUnset,
  }) {
    return PostItemData(
      id: id ?? this.id,
      authorUserId: identical(authorUserId, _postUnset)
          ? this.authorUserId
          : authorUserId as int?,
      authorKey: authorKey ?? this.authorKey,
      authorName: authorName ?? this.authorName,
      authorAvatarAsset: authorAvatarAsset ?? this.authorAvatarAsset,
      bodyText: bodyText ?? this.bodyText,
      dateLabel: dateLabel ?? this.dateLabel,
      relativeTime: relativeTime ?? this.relativeTime,
      isFollowed: isFollowed ?? this.isFollowed,
      canFollow: canFollow ?? this.canFollow,
      isLiked: isLiked ?? this.isLiked,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      commentCount: commentCount ?? this.commentCount,
      likeCount: likeCount ?? this.likeCount,
      shareCount: shareCount ?? this.shareCount,
      isShared: isShared ?? this.isShared,
      sharedPostId: sharedPostId ?? this.sharedPostId,
      sharedAuthorName: sharedAuthorName ?? this.sharedAuthorName,
      sharedAuthorAvatarAsset:
          sharedAuthorAvatarAsset ?? this.sharedAuthorAvatarAsset,
      sharedBodyText: sharedBodyText ?? this.sharedBodyText,
      sharedImagePath: sharedImagePath ?? this.sharedImagePath,
      imagePath: identical(imagePath, _postUnset)
          ? this.imagePath
          : imagePath as String?,
    );
  }
}

class PostReportReasonData {
  const PostReportReasonData({
    required this.id,
    required this.reasonKey,
    required this.label,
    required this.description,
  });

  final int id;
  final String reasonKey;
  final String label;
  final String description;

  factory PostReportReasonData.fromJson(Map<String, dynamic> json) {
    return PostReportReasonData(
      id: _postAsInt(json['id']),
      reasonKey: json['reason_key']?.toString() ?? '',
      label: json['label']?.toString() ?? 'بلاغ عام',
      description: json['description']?.toString() ?? '',
    );
  }
}

class PostImageDraft {
  const PostImageDraft({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  Map<String, dynamic> toJson() {
    return {
      'filename': fileName,
      'mime_type': mimeType,
      'content_base64': base64Encode(bytes),
    };
  }
}

class PostCommentData {
  const PostCommentData({
    required this.id,
    required this.authorName,
    required this.authorAvatarAsset,
    required this.bodyText,
    required this.createdAtLabel,
    required this.canEdit,
    required this.canDelete,
    required this.canReport,
  });

  final int id;
  final String authorName;
  final String authorAvatarAsset;
  final String bodyText;
  final String createdAtLabel;
  final bool canEdit;
  final bool canDelete;
  final bool canReport;

  factory PostCommentData.fromJson(Map<String, dynamic> json) {
    return PostCommentData(
      id: _postAsInt(json['id']),
      authorName: json['author_name']?.toString() ?? 'محمد احمد',
      authorAvatarAsset:
          json['author_avatar_asset']?.toString() ??
          'assets/images/post_author_avatar.png',
      bodyText: json['body_text']?.toString() ?? '',
      createdAtLabel: json['created_at_label']?.toString() ?? 'just now',
      canEdit: json['can_edit'] == true,
      canDelete: json['can_delete'] == true,
      canReport: json['can_report'] != false,
    );
  }

  PostCommentData copyWith({
    String? bodyText,
    String? createdAtLabel,
    bool? canEdit,
    bool? canDelete,
    bool? canReport,
  }) {
    return PostCommentData(
      id: id,
      authorName: authorName,
      authorAvatarAsset: authorAvatarAsset,
      bodyText: bodyText ?? this.bodyText,
      createdAtLabel: createdAtLabel ?? this.createdAtLabel,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      canReport: canReport ?? this.canReport,
    );
  }
}

class PostCommentsPayload {
  const PostCommentsPayload({
    required this.composerName,
    required this.comments,
  });

  final String composerName;
  final List<PostCommentData> comments;
}

class PostNotificationData {
  const PostNotificationData({
    required this.id,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.createdAtLabel,
  });

  final int id;
  final String message;
  final String notificationType;
  final bool isRead;
  final String createdAtLabel;

  factory PostNotificationData.fromJson(Map<String, dynamic> json) {
    return PostNotificationData(
      id: _postAsInt(json['id']),
      message: json['message']?.toString() ?? '',
      notificationType: json['notification_type']?.toString() ?? 'like',
      isRead: json['is_read'] == true,
      createdAtLabel: json['created_at_label']?.toString() ?? 'just now',
    );
  }
}

class PostNotificationsPayload {
  const PostNotificationsPayload({
    required this.unreadCount,
    required this.notifications,
  });

  final int unreadCount;
  final List<PostNotificationData> notifications;
}

class PostFollowToggleResult {
  const PostFollowToggleResult({
    required this.authorKey,
    required this.isFollowed,
    required this.canFollow,
  });

  final String authorKey;
  final bool isFollowed;
  final bool canFollow;
}

abstract class PostRepository {
  static PostRepository instance = LivePostRepository();

  Future<PostFeedData> loadFeed({required bool friendsOnly});

  Future<PostItemData> createPost({
    required String bodyText,
    PostImageDraft? image,
  });

  Future<PostItemData> updatePost({
    required int postId,
    required String bodyText,
    PostImageDraft? image,
    bool removeImage = false,
  });

  Future<void> deletePost({required int postId});

  Future<PostFollowToggleResult> toggleFollow({required int postId});

  Future<PostItemData> toggleLike({required int postId});

  Future<PostCommentsPayload> loadComments({required int postId});

  Future<PostCommentsPayload> addComment({
    required int postId,
    required String bodyText,
  });

  Future<PostCommentsPayload> updateComment({
    required int postId,
    required int commentId,
    required String bodyText,
  });

  Future<PostCommentsPayload> deleteComment({
    required int postId,
    required int commentId,
  });

  Future<void> reportComment({
    required int postId,
    required int commentId,
    required String reasonKey,
  });

  Future<PostItemData> sharePost({required int postId});

  Future<List<PostReportReasonData>> loadReportReasons();

  Future<void> reportPost({required int postId, required String reasonKey});

  Future<PostNotificationsPayload> loadNotifications();

  Future<int> markNotificationsRead();
}

final class LivePostRepository implements PostRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<PostFeedData> loadFeed({required bool friendsOnly}) async {
    final response = await _client.get(
      '/posts?friends_only=${friendsOnly ? 1 : 0}',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PostFeedData(
      notificationCount: _postAsInt(data['notification_count']),
      posts: (data['posts'] as List? ?? const <dynamic>[])
          .map(
            (item) =>
                PostItemData.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  @override
  Future<PostItemData> createPost({
    required String bodyText,
    PostImageDraft? image,
  }) async {
    final response = await _client.post(
      '/posts',
      body: {'body_text': bodyText, 'image': image?.toJson()},
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PostItemData.fromJson(
      Map<String, dynamic>.from(data['post'] as Map),
    );
  }

  @override
  Future<PostItemData> updatePost({
    required int postId,
    required String bodyText,
    PostImageDraft? image,
    bool removeImage = false,
  }) async {
    final response = await _client.post(
      '/posts/$postId',
      body: {
        'body_text': bodyText,
        'image': image?.toJson(),
        'remove_image': removeImage,
      },
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PostItemData.fromJson(
      Map<String, dynamic>.from(data['post'] as Map),
    );
  }

  @override
  Future<void> deletePost({required int postId}) async {
    await _client.post(
      '/posts/$postId/delete',
      bearerToken: _authStore.authToken,
    );
  }

  @override
  Future<PostFollowToggleResult> toggleFollow({required int postId}) async {
    final response = await _client.post(
      '/posts/$postId/follow-toggle',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PostFollowToggleResult(
      authorKey: data['author_key']?.toString() ?? '',
      isFollowed: data['is_followed'] == true,
      canFollow: data['can_follow'] != false,
    );
  }

  @override
  Future<PostItemData> toggleLike({required int postId}) async {
    final response = await _client.post(
      '/posts/$postId/like-toggle',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PostItemData.fromJson(
      Map<String, dynamic>.from(data['post'] as Map),
    );
  }

  @override
  Future<PostCommentsPayload> loadComments({required int postId}) async {
    final response = await _client.get(
      '/posts/$postId/comments',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PostCommentsPayload(
      composerName: data['composer_name']?.toString() ?? 'المستخدم الحالي',
      comments: (data['comments'] as List? ?? const <dynamic>[])
          .map(
            (item) => PostCommentData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<PostCommentsPayload> addComment({
    required int postId,
    required String bodyText,
  }) async {
    final response = await _client.post(
      '/posts/$postId/comments',
      body: {'body_text': bodyText},
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PostCommentsPayload(
      composerName: data['composer_name']?.toString() ?? 'المستخدم الحالي',
      comments: (data['comments'] as List? ?? const <dynamic>[])
          .map(
            (item) => PostCommentData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<PostCommentsPayload> updateComment({
    required int postId,
    required int commentId,
    required String bodyText,
  }) async {
    final response = await _client.post(
      '/posts/$postId/comments/$commentId',
      body: {'body_text': bodyText},
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PostCommentsPayload(
      composerName: data['composer_name']?.toString() ?? 'المستخدم الحالي',
      comments: (data['comments'] as List? ?? const <dynamic>[])
          .map(
            (item) => PostCommentData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<PostCommentsPayload> deleteComment({
    required int postId,
    required int commentId,
  }) async {
    final response = await _client.post(
      '/posts/$postId/comments/$commentId/delete',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PostCommentsPayload(
      composerName: data['composer_name']?.toString() ?? 'المستخدم الحالي',
      comments: (data['comments'] as List? ?? const <dynamic>[])
          .map(
            (item) => PostCommentData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> reportComment({
    required int postId,
    required int commentId,
    required String reasonKey,
  }) async {
    await _client.post(
      '/posts/$postId/comments/$commentId/report',
      body: {'reason_key': reasonKey},
      bearerToken: _authStore.authToken,
    );
  }

  @override
  Future<PostItemData> sharePost({required int postId}) async {
    final response = await _client.post(
      '/posts/$postId/share',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PostItemData.fromJson(
      Map<String, dynamic>.from(data['post'] as Map),
    );
  }

  @override
  Future<List<PostReportReasonData>> loadReportReasons() async {
    final response = await _client.get(
      '/posts/report-reasons',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['reasons'] as List? ?? const <dynamic>[])
        .map(
          (item) => PostReportReasonData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> reportPost({
    required int postId,
    required String reasonKey,
  }) async {
    await _client.post(
      '/posts/$postId/report',
      body: {'reason_key': reasonKey},
      bearerToken: _authStore.authToken,
    );
  }

  @override
  Future<PostNotificationsPayload> loadNotifications() async {
    final response = await _client.get(
      '/posts/notifications',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PostNotificationsPayload(
      unreadCount: _postAsInt(data['unread_count']),
      notifications: (data['notifications'] as List? ?? const <dynamic>[])
          .map(
            (item) => PostNotificationData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<int> markNotificationsRead() async {
    final response = await _client.post(
      '/posts/notifications/read-all',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return _postAsInt(data['unread_count']);
  }
}

final class FakePostRepository implements PostRepository {
  final List<PostItemData> _posts = <PostItemData>[
    const PostItemData(
      id: 1,
      authorUserId: 2,
      authorKey: 'seed:asmaa',
      authorName: 'اسماء فتحي',
      authorAvatarAsset: 'assets/images/post_author_avatar.png',
      bodyText:
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔\n'
          'لا تعود الايام الي فاتت ولا تنتظر احد 💔',
      dateLabel: '10/25/2024',
      relativeTime: '12 hours ago',
      isFollowed: true,
      canFollow: true,
      isLiked: false,
      canEdit: false,
      canDelete: false,
      commentCount: 1,
      likeCount: 0,
      shareCount: 0,
    ),
    const PostItemData(
      id: 2,
      authorUserId: 3,
      authorKey: 'seed:nour',
      authorName: 'نور سالم',
      authorAvatarAsset: 'assets/images/post_author_avatar.png',
      bodyText:
          'من اجمل اللحظات ان تجد من يفهمك بدون شرح.\n'
          'من اجمل اللحظات ان تجد من يفهمك بدون شرح.',
      dateLabel: '10/24/2024',
      relativeTime: '18 hours ago',
      isFollowed: false,
      canFollow: true,
      isLiked: false,
      canEdit: false,
      canDelete: false,
      commentCount: 0,
      likeCount: 0,
      shareCount: 0,
    ),
    const PostItemData(
      id: 3,
      authorUserId: 4,
      authorKey: 'seed:mohamed',
      authorName: 'محمد احمد',
      authorAvatarAsset: 'assets/images/post_author_avatar.png',
      bodyText:
          'لا تزال البداية ممكنة مهما تأخر الوقت.\n'
          'لا تزال البداية ممكنة مهما تأخر الوقت.',
      dateLabel: '10/23/2024',
      relativeTime: '2 days ago',
      isFollowed: false,
      canFollow: true,
      isLiked: false,
      canEdit: false,
      canDelete: false,
      commentCount: 2,
      likeCount: 0,
      shareCount: 0,
    ),
  ];

  final Map<int, List<PostCommentData>> _commentsByPost =
      <int, List<PostCommentData>>{
        1: const <PostCommentData>[
          PostCommentData(
            id: 1,
            authorName: 'محمد احمد',
            authorAvatarAsset: 'assets/images/post_author_avatar.png',
            bodyText: 'منشور جميل جدا.',
            createdAtLabel: '1 min ago',
            canEdit: false,
            canDelete: false,
            canReport: true,
          ),
        ],
        3: const <PostCommentData>[
          PostCommentData(
            id: 2,
            authorName: 'سارة محمد',
            authorAvatarAsset: 'assets/images/post_author_avatar.png',
            bodyText: 'كلام حقيقي.',
            createdAtLabel: '5 min ago',
            canEdit: false,
            canDelete: false,
            canReport: true,
          ),
          PostCommentData(
            id: 3,
            authorName: 'نور سالم',
            authorAvatarAsset: 'assets/images/post_author_avatar.png',
            bodyText: 'اتفق جدًا.',
            createdAtLabel: '8 min ago',
            canEdit: false,
            canDelete: false,
            canReport: true,
          ),
        ],
      };

  List<PostNotificationData> _notifications = const <PostNotificationData>[
    PostNotificationData(
      id: 1,
      message: 'محمد احمد علّق على منشورك',
      notificationType: 'comment',
      isRead: false,
      createdAtLabel: '3 min ago',
    ),
    PostNotificationData(
      id: 2,
      message: 'نور سالم أعجب بمنشورك',
      notificationType: 'like',
      isRead: false,
      createdAtLabel: '10 min ago',
    ),
  ];

  int _nextPostId = 10;
  int _nextCommentId = 20;

  @override
  Future<PostFeedData> loadFeed({required bool friendsOnly}) async {
    final posts = friendsOnly
        ? _posts.where((post) => post.isFollowed || !post.canFollow).toList()
        : List<PostItemData>.from(_posts);

    return PostFeedData(
      notificationCount: _notifications.where((item) => !item.isRead).length,
      posts: posts,
    );
  }

  @override
  Future<PostItemData> createPost({
    required String bodyText,
    PostImageDraft? image,
  }) async {
    final post = PostItemData(
      id: _nextPostId++,
      authorUserId: 1512345412,
      authorKey: 'user:current',
      authorName: 'المستخدم الحالي',
      authorAvatarAsset: 'assets/images/post_author_avatar.png',
      bodyText: bodyText,
      dateLabel: '10/25/2024',
      relativeTime: 'just now',
      isFollowed: false,
      canFollow: false,
      isLiked: false,
      canEdit: true,
      canDelete: true,
      commentCount: 0,
      likeCount: 0,
      shareCount: 0,
      imagePath: image?.fileName,
    );
    _posts.insert(0, post);
    _commentsByPost[post.id] = <PostCommentData>[];
    return post;
  }

  @override
  Future<PostItemData> updatePost({
    required int postId,
    required String bodyText,
    PostImageDraft? image,
    bool removeImage = false,
  }) async {
    final post = _posts.firstWhere((item) => item.id == postId);
    if (!post.canEdit) {
      throw StateError('لا يمكنك تعديل هذا المنشور.');
    }

    final nextImagePath = image != null
        ? image.fileName
        : removeImage
        ? null
        : post.imagePath;
    if (bodyText.trim().isEmpty &&
        (nextImagePath == null || nextImagePath.isEmpty)) {
      throw StateError('اكتب نصًا أو اختر صورة للمنشور.');
    }

    final updated = post.copyWith(
      bodyText: bodyText.trim(),
      imagePath: nextImagePath,
    );
    _replacePost(updated);
    return updated;
  }

  @override
  Future<void> deletePost({required int postId}) async {
    final post = _posts.firstWhere((item) => item.id == postId);
    if (!post.canDelete) {
      throw StateError('لا يمكنك حذف هذا المنشور.');
    }

    _posts.removeWhere((item) => item.id == postId);
    _commentsByPost.remove(postId);
  }

  @override
  Future<PostFollowToggleResult> toggleFollow({required int postId}) async {
    final post = _posts.firstWhere((item) => item.id == postId);
    final updated = post.copyWith(isFollowed: !post.isFollowed);
    _replacePost(updated);
    return PostFollowToggleResult(
      authorKey: updated.authorKey,
      isFollowed: updated.isFollowed,
      canFollow: updated.canFollow,
    );
  }

  @override
  Future<PostItemData> toggleLike({required int postId}) async {
    final post = _posts.firstWhere((item) => item.id == postId);
    final isLiked = !post.isLiked;
    final updated = post.copyWith(
      isLiked: isLiked,
      likeCount: isLiked
          ? post.likeCount + 1
          : (post.likeCount - 1).clamp(0, 999),
    );
    _replacePost(updated);
    return updated;
  }

  @override
  Future<PostCommentsPayload> loadComments({required int postId}) async {
    return PostCommentsPayload(
      composerName: 'المستخدم الحالي',
      comments: List<PostCommentData>.from(_commentsByPost[postId] ?? const []),
    );
  }

  @override
  Future<PostCommentsPayload> addComment({
    required int postId,
    required String bodyText,
  }) async {
    final comments = List<PostCommentData>.from(
      _commentsByPost[postId] ?? const [],
    );
    comments.add(
      PostCommentData(
        id: _nextCommentId++,
        authorName: 'المستخدم الحالي',
        authorAvatarAsset: 'assets/images/post_author_avatar.png',
        bodyText: bodyText,
        createdAtLabel: 'just now',
        canEdit: true,
        canDelete: true,
        canReport: false,
      ),
    );
    _commentsByPost[postId] = comments;

    final post = _posts.firstWhere((item) => item.id == postId);
    _replacePost(post.copyWith(commentCount: comments.length));

    return PostCommentsPayload(
      composerName: 'المستخدم الحالي',
      comments: comments,
    );
  }

  @override
  Future<PostCommentsPayload> updateComment({
    required int postId,
    required int commentId,
    required String bodyText,
  }) async {
    final comments = List<PostCommentData>.from(
      _commentsByPost[postId] ?? const [],
    );
    final index = comments.indexWhere((item) => item.id == commentId);
    if (index == -1 || !comments[index].canEdit) {
      throw StateError('لا يمكنك تعديل هذا التعليق.');
    }

    comments[index] = comments[index].copyWith(
      bodyText: bodyText.trim(),
      createdAtLabel: 'edited now',
    );
    _commentsByPost[postId] = comments;

    return PostCommentsPayload(
      composerName: 'المستخدم الحالي',
      comments: comments,
    );
  }

  @override
  Future<PostCommentsPayload> deleteComment({
    required int postId,
    required int commentId,
  }) async {
    final comments = List<PostCommentData>.from(
      _commentsByPost[postId] ?? const [],
    );
    final comment = comments.firstWhere((item) => item.id == commentId);
    if (!comment.canDelete) {
      throw StateError('لا يمكنك حذف هذا التعليق.');
    }

    comments.removeWhere((item) => item.id == commentId);
    _commentsByPost[postId] = comments;

    final post = _posts.firstWhere((item) => item.id == postId);
    _replacePost(post.copyWith(commentCount: comments.length));

    return PostCommentsPayload(
      composerName: 'المستخدم الحالي',
      comments: comments,
    );
  }

  @override
  Future<void> reportComment({
    required int postId,
    required int commentId,
    required String reasonKey,
  }) async {
    _commentsByPost[postId]?.firstWhere((item) => item.id == commentId);
  }

  @override
  Future<PostItemData> sharePost({required int postId}) async {
    final post = _posts.firstWhere((item) => item.id == postId);
    final updated = post.copyWith(shareCount: post.shareCount + 1);
    _replacePost(updated);
    final sharedPost = PostItemData(
      id: _nextPostId++,
      authorUserId: 1512345412,
      authorKey: 'user:current',
      authorName: 'المستخدم الحالي',
      authorAvatarAsset: 'assets/images/post_author_avatar.png',
      bodyText: post.bodyText,
      dateLabel: '10/25/2024',
      relativeTime: 'just now',
      isFollowed: false,
      canFollow: false,
      isLiked: false,
      canEdit: true,
      canDelete: true,
      commentCount: 0,
      likeCount: 0,
      shareCount: 0,
      isShared: true,
      sharedPostId: post.id,
      sharedAuthorName: post.authorName,
      sharedAuthorAvatarAsset: post.authorAvatarAsset,
      sharedBodyText: post.sharedBodyText ?? post.bodyText,
      sharedImagePath: post.sharedImagePath ?? post.imagePath,
      imagePath: post.imagePath,
    );
    _posts.insert(0, sharedPost);
    _commentsByPost[sharedPost.id] = <PostCommentData>[];
    return sharedPost;
  }

  @override
  Future<List<PostReportReasonData>> loadReportReasons() async {
    return const <PostReportReasonData>[
      PostReportReasonData(
        id: 1,
        reasonKey: 'spam',
        label: 'محتوى مزعج أو سبام',
        description: 'منشورات متكررة أو روابط مزعجة.',
      ),
      PostReportReasonData(
        id: 2,
        reasonKey: 'abuse',
        label: 'إساءة أو تنمر',
        description: 'إهانة أو تهديد أو مضايقة مباشرة.',
      ),
      PostReportReasonData(
        id: 3,
        reasonKey: 'adult',
        label: 'محتوى غير لائق',
        description: 'صور أو كلمات غير مناسبة داخل المنشور.',
      ),
      PostReportReasonData(
        id: 4,
        reasonKey: 'fraud',
        label: 'احتيال أو نصب',
        description: 'محاولة خداع أو طلب بيانات أو أموال.',
      ),
      PostReportReasonData(
        id: 5,
        reasonKey: 'other',
        label: 'سبب آخر',
        description: 'استخدم هذا الخيار عند عدم وجود سبب مناسب.',
      ),
    ];
  }

  @override
  Future<void> reportPost({
    required int postId,
    required String reasonKey,
  }) async {
    final post = _posts.firstWhere((item) => item.id == postId);
    _replacePost(post.copyWith());
  }

  @override
  Future<PostNotificationsPayload> loadNotifications() async {
    return PostNotificationsPayload(
      unreadCount: _notifications.where((item) => !item.isRead).length,
      notifications: List<PostNotificationData>.from(_notifications),
    );
  }

  @override
  Future<int> markNotificationsRead() async {
    _notifications = _notifications
        .map(
          (item) => PostNotificationData(
            id: item.id,
            message: item.message,
            notificationType: item.notificationType,
            isRead: true,
            createdAtLabel: item.createdAtLabel,
          ),
        )
        .toList();
    return 0;
  }

  void _replacePost(PostItemData updated) {
    final index = _posts.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      return;
    }

    _posts[index] = updated;
  }
}

int _postAsInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
